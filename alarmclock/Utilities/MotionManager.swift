import Foundation
import CoreMotion
import Combine

final class MotionManager: ObservableObject {
    static let shared = MotionManager()

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    @Published var shakeCount: Int = 0
    @Published var squatCount: Int = 0

    private var lastAcceleration: CMAcceleration?
    private var shakeThreshold: Double = 2.5
    private var isMonitoringShakes = false

    private var lastVerticalPosition: Double = 0
    private var squatPhase: SquatPhase = .standing
    private var isMonitoringSquats = false

    private enum SquatPhase {
        case standing, descending, ascending
    }

    private init() {
        queue.maxConcurrentOperationCount = 1
    }

    func startShakeMonitoring(threshold: Double = 2.5) {
        guard motionManager.isAccelerometerAvailable else { return }
        shakeCount = 0
        shakeThreshold = threshold
        isMonitoringShakes = true
        motionManager.accelerometerUpdateInterval = 0.05
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let self, let data else { return }
            self.processShake(acceleration: data.acceleration)
        }
    }

    func stopShakeMonitoring() {
        isMonitoringShakes = false
        motionManager.stopAccelerometerUpdates()
    }

    func startSquatMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        squatCount = 0
        squatPhase = .standing
        isMonitoringSquats = true
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.processSquat(motion: motion)
        }
    }

    func stopSquatMonitoring() {
        isMonitoringSquats = false
        motionManager.stopDeviceMotionUpdates()
    }

    func resetShakeCount() {
        DispatchQueue.main.async { self.shakeCount = 0 }
    }

    func resetSquatCount() {
        DispatchQueue.main.async { self.squatCount = 0 }
    }

    private func processShake(acceleration: CMAcceleration) {
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        if magnitude > shakeThreshold {
            if let last = lastAcceleration {
                let delta = abs(magnitude - sqrt(
                    last.x * last.x + last.y * last.y + last.z * last.z
                ))
                if delta > 1.0 {
                    DispatchQueue.main.async { self.shakeCount += 1 }
                }
            }
        }
        lastAcceleration = acceleration
    }

    private func processSquat(motion: CMDeviceMotion) {
        let verticalAccel = motion.gravity.y
        let threshold = 0.3

        switch squatPhase {
        case .standing:
            if verticalAccel < -threshold {
                squatPhase = .descending
            }
        case .descending:
            if verticalAccel > threshold {
                squatPhase = .ascending
            }
        case .ascending:
            if abs(verticalAccel) < threshold {
                squatPhase = .standing
                DispatchQueue.main.async { self.squatCount += 1 }
            }
        }
    }
}
