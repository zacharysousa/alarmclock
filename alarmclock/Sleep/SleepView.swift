import SwiftUI
import SwiftData

struct SleepView: View {
    @Query(sort: \SleepSession.startTime, order: .reverse) private var sessions: [SleepSession]
    @Environment(\.modelContext) private var context
    @State private var isTracking = false
    @State private var activeSession: SleepSession?
    @State private var showBedtimeReminder = false
    @State private var reminder = BedtimeReminderService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    if isTracking {
                        activeTrackingView
                    } else {
                        idleView
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .sheet(isPresented: $showBedtimeReminder) {
                BedtimeReminderSheet(reminder: reminder)
            }
        }
    }

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 80))
                .foregroundStyle(.purple)

            Text("Sleep Tracker")
                .font(.title.bold())
                .foregroundStyle(.white)

            if let last = sessions.first {
                lastSessionCard(last)
            }

            bedtimeReminderCard

            Button {
                startTracking()
            } label: {
                Text("START SLEEP TRACKING")
                    .font(.headline.bold())
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Text("Microphone will monitor snoring overnight")
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    private var bedtimeReminderCard: some View {
        Button {
            showBedtimeReminder = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.purple)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bedtime Reminder")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(reminder.isEnabled ? "Every day at \(reminder.timeString)" : "Off")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding()
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var activeTrackingView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.purple.opacity(0.15 - Double(i) * 0.04))
                        .frame(width: CGFloat(120 + i * 40))
                }
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.purple)
            }

            Text("Listening...")
                .font(.title2.bold())
                .foregroundStyle(.white)

            if let session = activeSession {
                Text("Started \(session.startTime, style: .time)")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            Text("Sleep well. The alarm will stop tracking automatically.")
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                stopTracking()
            } label: {
                Text("Stop Tracking")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
        }
    }

    private func lastSessionCard(_ session: SleepSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LAST NIGHT")
                .font(.caption.bold())
                .foregroundStyle(.gray)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.durationString)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Sleep duration")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.snoreScore)")
                        .font(.title2.bold())
                        .foregroundStyle(.purple)
                    Text(session.snoreLabel)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func startTracking() {
        let session = SleepSession()
        context.insert(session)
        activeSession = session
        isTracking = true
    }

    private func stopTracking() {
        activeSession?.endTime = Date()
        try? context.save()
        activeSession = nil
        isTracking = false
    }
}

struct BedtimeReminderSheet: View {
    var reminder: BedtimeReminderService
    @Environment(\.dismiss) private var dismiss
    @State private var isEnabled: Bool
    @State private var time: Date

    init(reminder: BedtimeReminderService) {
        self.reminder = reminder
        _isEnabled = State(initialValue: reminder.isEnabled)
        _time = State(initialValue: Calendar.current.date(
            bySettingHour: reminder.hour, minute: reminder.minute, second: 0, of: Date()
        ) ?? Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Toggle(isOn: $isEnabled) {
                        Text("Remind me to go to bed")
                            .foregroundStyle(.white)
                    }
                    .tint(.purple)

                    if isEnabled {
                        DatePicker("Reminder time", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }

                    Text("Get a nightly nudge to start winding down, so your alarm doesn't have to fight a short night.")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Bedtime Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
                        reminder.hour = components.hour ?? 22
                        reminder.minute = components.minute ?? 30
                        reminder.isEnabled = isEnabled
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
    }
}
