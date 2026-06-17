import SwiftUI

struct ShakeMissionView: View {
    let mission: MissionConfig
    let onComplete: () -> Void

    @StateObject private var motion = MotionManager.shared
    @State private var bounceAnimation = false
    @State private var inactivityTimer: Timer?

    private var progress: Double {
        Double(min(motion.shakeCount, mission.requiredCount)) / Double(mission.requiredCount)
    }

    var body: some View {
        VStack(spacing: 40) {
            Text("Shake Mission")
                .font(.headline)
                .foregroundStyle(.gray)

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)

                VStack(spacing: 4) {
                    Text("\(min(motion.shakeCount, mission.requiredCount))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("of \(mission.requiredCount) shakes")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
                .offset(y: bounceAnimation ? -12 : 0)
                .animation(
                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                    value: bounceAnimation
                )

            Text("Shake your phone!")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()
        }
        .padding()
        .onAppear {
            bounceAnimation = true
            motion.startShakeMonitoring(threshold: 2.5)
            startInactivityTimer()
        }
        .onDisappear {
            motion.stopShakeMonitoring()
            inactivityTimer?.invalidate()
        }
        .onChange(of: motion.shakeCount) { _, newCount in
            resetInactivityTimer()
            if newCount >= mission.requiredCount {
                motion.stopShakeMonitoring()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }

    private func startInactivityTimer() {
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
            motion.resetShakeCount()
        }
    }

    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        startInactivityTimer()
    }
}
