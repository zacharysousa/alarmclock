import SwiftUI
import SwiftData

private let cycleMinutes = 90
private let defaultFallAsleepMinutes: Double = 14

struct SleepCycleResult: Identifiable {
    let id = UUID()
    let time: Date
    let cycles: Int
    var hours: Double { Double(cycles) * Double(cycleMinutes) / 60.0 }
    var isRecommended: Bool { cycles >= 5 }
}

struct SleepCycleCalculatorView: View {
    @Environment(\.modelContext) private var context

    enum Mode: String, CaseIterable, Identifiable {
        case wakeUp = "Wake Up At"
        case sleepNow = "Sleep Now"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .wakeUp
    @State private var wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var now = Date()
    @State private var fallAsleepMinutes: Double = defaultFallAsleepMinutes
    @State private var confirmationMessage: String?

    private let cycleOptions = [6, 5, 4, 3]
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var results: [SleepCycleResult] {
        let fallAsleepSeconds = TimeInterval(fallAsleepMinutes * 60)
        switch mode {
        case .wakeUp:
            return cycleOptions.map { cycles in
                let sleepDuration = TimeInterval(cycles * cycleMinutes * 60)
                let bedtime = wakeTime.addingTimeInterval(-sleepDuration - fallAsleepSeconds)
                return SleepCycleResult(time: bedtime, cycles: cycles)
            }
        case .sleepNow:
            let fallAsleepTime = now.addingTimeInterval(fallAsleepSeconds)
            return cycleOptions.reversed().map { cycles in
                let wake = fallAsleepTime.addingTimeInterval(TimeInterval(cycles * cycleMinutes * 60))
                return SleepCycleResult(time: wake, cycles: cycles)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        header
                        modePicker

                        if mode == .wakeUp {
                            wakeTimePicker
                        } else {
                            sleepNowCard
                        }

                        resultsList
                    }
                    .padding()
                }
            }
            .navigationTitle("Sleep Cycles")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .onReceive(timer) { time in now = time }
            .alert(
                "Alarm Set",
                isPresented: Binding(
                    get: { confirmationMessage != nil },
                    set: { if !$0 { confirmationMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { confirmationMessage = nil }
            } message: {
                Text(confirmationMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 44))
                .foregroundStyle(.purple)
            Text("Wake up feeling refreshed by timing your alarm to a full 90-minute sleep cycle.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            ForEach(Mode.allCases) { m in
                Text(m.rawValue).tag(m)
            }
        }
        .pickerStyle(.segmented)
    }

    private var wakeTimePicker: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("I WANT TO WAKE UP AT")
                    .font(.caption.bold())
                    .foregroundStyle(.gray)
                DatePicker("Wake time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
            }

            fallAsleepSlider
        }
        .padding()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var sleepNowCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("IT'S CURRENTLY")
                    .font(.caption.bold())
                    .foregroundStyle(.gray)
                Text(now, style: .time)
                    .font(.system(size: 42, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
            }

            fallAsleepSlider
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var fallAsleepSlider: some View {
        VStack(spacing: 10) {
            HStack {
                Text("TIME TO FALL ASLEEP")
                    .font(.caption.bold())
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(Int(fallAsleepMinutes)) min")
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
            }
            Slider(value: $fallAsleepMinutes, in: 0...45, step: 1)
                .tint(.purple)
        }
    }

    private var resultsList: some View {
        VStack(spacing: 12) {
            Text(mode == .wakeUp ? "RECOMMENDED BEDTIMES" : "RECOMMENDED WAKE TIMES")
                .font(.caption.bold())
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(results) { result in
                resultRow(result)
            }
        }
    }

    private func resultRow(_ result: SleepCycleResult) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(result.time, style: .time)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    if result.isRecommended {
                        Text("BEST")
                            .font(.caption2.bold())
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .clipShape(Capsule())
                    }
                }
                Text("\(result.cycles) cycles · \(formattedHours(result.hours)) of sleep")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Button {
                setAlarm(at: result.time)
            } label: {
                Text("Set Alarm")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formattedHours(_ hours: Double) -> String {
        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)
        return minutes == 0 ? "\(wholeHours)h" : "\(wholeHours)h \(minutes)m"
    }

    private func setAlarm(at time: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let alarm = Alarm(hour: components.hour ?? 7, minute: components.minute ?? 0)
        let defaultMission = MissionConfig(type: .math, difficulty: 1, requiredCount: 3)
        alarm.missions = [defaultMission]
        context.insert(alarm)
        context.insert(defaultMission)
        try? context.save()
        AlarmService.shared.schedule(alarm)
        confirmationMessage = "Alarm set for \(alarm.timeString)."
    }
}
