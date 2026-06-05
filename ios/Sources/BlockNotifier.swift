import Foundation
import UIKit
import UserNotifications

/// Local notifications for phase endings, so a locked phone still hears them.
///
/// A suspended app can't run code, but both phase end times are known the
/// moment the phase starts — so the notification is scheduled up front and
/// cancelled if the phase ends early in-app. As the center's delegate, this
/// also presents banners while the app is foreground — the end-of-phase chime
/// should be heard the same way whether the phone was locked or sitting on
/// the desk with the app open.
///
/// Permission is requested once at launch (not mid-flow, where the dialog
/// would race the first block's schedule), and `alertStatus` is published so
/// the plan screen can say *why* a locked phone would stay silent instead of
/// failing silently.
final class BlockNotifier: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    /// How visible our alerts actually are, beyond plain permission — iOS can
    /// leave an app authorized while hiding every surface (a long-press
    /// "Deliver Quietly", or Lock Screen/Banners unchecked in Settings), which
    /// would silently defeat the whole point of these notifications.
    enum AlertStatus {
        case ok
        case denied  // permission off entirely
        case muted   // authorized, but lock-screen or banner alerts are disabled
    }

    @Published private(set) var alertStatus: AlertStatus = .ok

    private static let focusEndID = "phase.focus-end"
    private static let breakEndID = "phase.break-end"
    private static let phaseIDs = [focusEndID, breakEndID]

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        // No session survives a relaunch, so anything still pending from a
        // force-quit or jetsammed block would fire later announcing a break
        // that no longer exists. Anything already delivered is old news too.
        center.removePendingNotificationRequests(withIdentifiers: Self.phaseIDs)
        center.removeDeliveredNotifications(withIdentifiers: Self.phaseIDs)
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] _, error in
            if let error { print("BlockNotifier: authorization request failed: \(error.localizedDescription)") }
            self?.refreshStatus()
        }
    }

    /// Re-read notification visibility — called after the launch request
    /// settles and whenever the app foregrounds (the user may have just
    /// flipped something in Settings).
    func refreshStatus() {
        center.getNotificationSettings { [weak self] settings in
            let status: AlertStatus
            switch settings.authorizationStatus {
            case .denied:
                status = .denied
            case .notDetermined:
                status = .ok   // the launch dialog is still up; don't nag yet
            default:
                status = (settings.lockScreenSetting == .disabled || settings.alertSetting == .disabled)
                    ? .muted : .ok
            }
            DispatchQueue.main.async { self?.alertStatus = status }
        }
    }

    /// Jump to the app's page in Settings, for the warning banner.
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// Fired when the focus countdown runs out. The break is opt-in, so the
    /// copy invites rather than announces a started timer.
    func scheduleFocusEnd(in seconds: TimeInterval) {
        schedule(id: Self.focusEndID,
                 title: "Focus block complete",
                 body: "Nice work — your break is ready when you are.",
                 after: seconds)
    }

    func scheduleBreakEnd(in seconds: TimeInterval) {
        schedule(id: Self.breakEndID,
                 title: "Break's over",
                 body: "Come back to see your score and plan the next block.",
                 after: seconds)
    }

    /// Drop anything not yet delivered. Only for phases that end *early* (and
    /// the launch sweep): on a natural finish the trigger has just matured,
    /// and yanking it races the delivery daemon — the cancel can win and
    /// silently swallow a legitimate notification.
    func cancelPending() {
        center.removePendingNotificationRequests(withIdentifiers: Self.phaseIDs)
    }

    private func schedule(id: String, title: String, body: String, after seconds: TimeInterval) {
        guard seconds >= 1 else { return }
        // Anchor the fire time now — the settings read below is async, and a
        // time-interval trigger would silently start counting from `add`.
        let fireDate = Date().addingTimeInterval(seconds)
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.add(id: id, title: title, body: body, at: fireDate)
            case .notDetermined:
                // A block started while the launch dialog was still up:
                // chain off the answer instead of silently scheduling nothing.
                // The fire date is already anchored, so nothing drifts.
                self.center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    self.refreshStatus()
                    if granted { self.add(id: id, title: title, body: body, at: fireDate) }
                }
            default:
                break   // denied — surfaced by the plan-screen warning instead
            }
        }
    }

    private func add(id: String, title: String, body: String, at fireDate: Date) {
        // A new phase is starting; delivered notifications from the previous
        // one have been acted on — don't let them pile up in the tray.
        center.removeDeliveredNotifications(withIdentifiers: Self.phaseIDs)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        // Break through Focus/DND modes (and the Scheduled Summary) — a timer
        // the user explicitly started is exactly what Time Sensitive is for.
        // Requires the time-sensitive entitlement; without it iOS quietly
        // treats this as the default level.
        content.interruptionLevel = .timeSensitive
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger)) { error in
            if let error { print("BlockNotifier: scheduling \(id) failed: \(error.localizedDescription)") }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Present even while the app is foreground. Without this, iOS drops the
    /// banner silently when the app is open — which reads as "notifications
    /// don't work" on a phone propped up showing the focus screen.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
