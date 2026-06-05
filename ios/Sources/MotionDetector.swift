import Foundation
import CoreMotion
import Combine

/// Emits a "pickup" event when the phone is lifted off a resting position
/// during a focus block.
///
/// Apple gives us no "the user picked up the phone" API, so this is a
/// deliberate *heuristic*, modelled as the rest→motion transition: detection
/// **arms only after the phone has been at rest** (low user-acceleration and
/// stable gravity for `stillDuration`), then an acceleration spike or sharp
/// orientation change fires a pickup and disarms until the phone rests again.
/// Arming on rest is what keeps the noisy moments honest — tapping Start with
/// the phone still in your hand, setting it down, fidgeting after a counted
/// pickup, returning from a lock — none of those can fire, because the phone
/// wasn't resting when they happened. The thresholds below are starting
/// points — expect to tune them on a real device. Motion is unavailable on
/// the Simulator, so `isAvailable` is false there.
final class MotionDetector {
    /// Fires once per detected pickup (already debounced). Delivered on the
    /// CoreMotion queue — subscribers should hop to the main queue.
    let pickupDetected = PassthroughSubject<Void, Never>()

    private let manager = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.ajschleg.FocusSlice.motion"
        q.maxConcurrentOperationCount = 1   // serialize access to mutable state
        return q
    }()

    // --- Tunables ---------------------------------------------------------
    private let accelerationThreshold = 0.22   // g, user-acceleration magnitude
    private let gravityDeltaThreshold = 0.25   // change in gravity unit vector
    private let cooldown: TimeInterval = 2.0   // min seconds between pickups
    private let maxSampleGap: TimeInterval = 0.5 // a longer gap means we were suspended (backgrounded/locked)
    // How still the phone must be, and for how long, before pickup detection
    // arms. An order of magnitude tighter than the pickup thresholds so
    // hand-held wobble never reads as "resting".
    private let stillAccelMax = 0.07
    private let stillGravityDeltaMax = 0.02
    private let stillDuration: TimeInterval = 1.0
    // ----------------------------------------------------------------------

    private var lastGravity: CMAcceleration?
    private var lastPickup: Date = .distantPast
    private var lastSampleAt: Date = .distantPast
    private var stillSince: Date?   // start of the current stillness run, nil while moving
    private var armed = false       // true once the phone has rested ≥ stillDuration

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        lastGravity = nil
        lastPickup = .distantPast
        lastSampleAt = .distantPast
        stillSince = nil
        armed = false
        manager.deviceMotionUpdateInterval = 1.0 / 20.0   // 20 Hz is plenty
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.process(motion)
        }
    }

    func stop() {
        if manager.isDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
        }
    }

    private func process(_ motion: CMDeviceMotion) {
        let now = Date()

        // A gap longer than the sampling interval means updates stopped — the app
        // was suspended because it was backgrounded or the phone was locked. Our
        // gravity baseline is stale and the phone is probably in the user's hand
        // right now, so drop the baseline and disarm; detection re-arms once the
        // phone is resting again.
        if now.timeIntervalSince(lastSampleAt) > maxSampleGap {
            lastGravity = nil
            stillSince = nil
            armed = false
        }
        lastSampleAt = now

        let g = motion.gravity
        var gravityDelta = 0.0
        if let last = lastGravity {
            let dx = g.x - last.x, dy = g.y - last.y, dz = g.z - last.z
            gravityDelta = (dx * dx + dy * dy + dz * dz).squareRoot()
        }
        lastGravity = g

        let ua = motion.userAcceleration
        let accelMag = (ua.x * ua.x + ua.y * ua.y + ua.z * ua.z).squareRoot()

        guard armed else {
            // Waiting for the phone to rest. A quiet stretch arms detection; any
            // meaningful motion (still in hand, being set down) resets the run.
            if accelMag < stillAccelMax && gravityDelta < stillGravityDeltaMax {
                let since = stillSince ?? now
                stillSince = since
                if now.timeIntervalSince(since) >= stillDuration { armed = true }
            } else {
                stillSince = nil
            }
            return
        }

        let pickupLike = accelMag > accelerationThreshold || gravityDelta > gravityDeltaThreshold
        guard pickupLike else { return }
        guard now.timeIntervalSince(lastPickup) > cooldown else { return }
        lastPickup = now
        armed = false        // one event per lift; re-arms when the phone rests again
        stillSince = nil

        pickupDetected.send()
    }
}
