import SwiftUI

struct TouchMissionView: View {
    let mission: MissionConfig
    let onComplete: () -> Void

    @State private var tapCount = 0
    @State private var pulse = false

    private var progress: Double {
        Double(min(tapCount, mission.requiredCount)) / Double(mission.requiredCount)
    }

    var body: some View {
        VStack(spacing: 40) {
            Text("Touch Mission")
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
                    Text("\(min(tapCount, mission.requiredCount))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("of \(mission.requiredCount) taps")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Button {
                registerTap()
            } label: {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .frame(width: 140, height: 140)
                    .background(Color(white: 0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Text("Tap the button repeatedly!")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()
        }
        .padding()
    }

    private func registerTap() {
        guard tapCount < mission.requiredCount else { return }
        tapCount += 1
        withAnimation(.easeOut(duration: 0.1)) {
            pulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pulse = false
        }
        if tapCount >= mission.requiredCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete()
            }
        }
    }
}
