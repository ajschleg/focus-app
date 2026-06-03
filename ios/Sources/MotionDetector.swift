import Foundation
import CoreMotion
import Combine

/// Emits a "pickup" event when the phone is lifted or significantly moved while
/// it's supposed to be sitting still during a focus block.
///
/// Apple gives us no "the user picked up the phone" API, so this is a
/// deliberate *heuristic*: we watch device motion and fire when either the
/// user-acceleration magnitude spikes OR the gravity vector (orientation)
/// changes sharply, then debounce. The thresholds below are starting points —
/// expect to tune them on a real device. Motion is unavailable on the
/// Simulator, so `isAvailable` is false there.
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
    private let settleDelay: TimeInterval = 1.5 // ignore the act of setting it down
    // ----------------------------------------------------------------------

    private var lastGravity: CMAcceleration?
    private var lastPickup: Date = .distantPast
    private var settleUntil: Date = .distantPast

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        lastGravity = nil
        lastPickup = .distantPast
        settleUntil = Date().addingTimeInterval(settleDelay)
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

        // Track gravity delta every sample so the first post-settle reading is honest.
        let g = motion.gravity
        var gravityDelta = 0.0
        if let last = lastGravity {
            let dx = g.x - last.x, dy = g.y - last.y, dz = g.z - last.z
            gravityDelta = (dx * dx + dy * dy + dz * dz).squareRoot()
        }
        lastGravity = g

        guard now >= settleUntil else { return }

        let ua = motion.userAcceleration
        let accelMag = (ua.x * ua.x + ua.y * ua.y + ua.z * ua.z).squareRoot()

        let pickupLike = accelMag > accelerationThreshold || gravityDelta > gravityDeltaThreshold
        guard pickupLike else { return }
        guard now.timeIntervalSince(lastPickup) > cooldown else { return }
        lastPickup = now

        pickupDetected.send()
    }
}
