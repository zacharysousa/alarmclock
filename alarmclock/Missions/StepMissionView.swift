import SwiftUI
import CoreMotion

final class StepCounter: ObservableObject {
    @Published var steps: Int = 0
    private let pedometer = CMPedometer()
    private var startTime: Date?

    func start() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        startTime = Date()
        pedometer.startUpdates(from: startTime!) { [weak self] data, _ in
            DispatchQueue.main.async {
                self?.steps = Int(data?.numberOfSteps ?? 0)
            }
        }
    }

    func stop() {
        pedometer.stopUpdates()
    }
}

struct StepMissionView: View {
    let mission: MissionConfig
    let onComplete: () -> Void

    @StateObject private var counter = StepCounter()

    private var progress: Double {
        Double(min(counter.steps, mission.requiredCount)) / Double(mission.requiredCount)
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Step Mission")
                .font(.headline)
                .foregroundStyle(.gray)

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)

                VStack(spacing: 4) {
                    Text("\(min(counter.steps, mission.requiredCount))")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("of \(mission.requiredCount) steps")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Walk \(mission.requiredCount) steps\nto dismiss the alarm")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .onAppear { counter.start() }
        .onDisappear { counter.stop() }
        .onChange(of: counter.steps) { _, steps in
            if steps >= mission.requiredCount {
                counter.stop()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onComplete() }
            }
        }
    }
}
