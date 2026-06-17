import SwiftUI

struct SquatMissionView: View {
    let mission: MissionConfig
    let onComplete: () -> Void

    @StateObject private var motion = MotionManager.shared

    private var progress: Double {
        Double(min(motion.squatCount, mission.requiredCount)) / Double(mission.requiredCount)
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Squat Mission")
                .font(.headline)
                .foregroundStyle(.gray)

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)

                VStack(spacing: 4) {
                    Text("\(min(motion.squatCount, mission.requiredCount))")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("of \(mission.requiredCount)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("Hold phone flat.\nSquat down and back up.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .onAppear { motion.startSquatMonitoring() }
        .onDisappear { motion.stopSquatMonitoring() }
        .onChange(of: motion.squatCount) { _, count in
            if count >= mission.requiredCount {
                motion.stopSquatMonitoring()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onComplete() }
            }
        }
    }
}
