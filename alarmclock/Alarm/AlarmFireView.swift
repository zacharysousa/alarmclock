import SwiftUI
import SwiftData
import UserNotifications

struct AlarmFireView: View {
    let alarmID: UUID
    @Environment(\.modelContext) private var context

    @State private var currentTime = Date()
    @State private var missionIndex: Int = 0
    @State private var missionCompleted = false
    @State private var pulseAnimation = false
    @State private var showMission = false
    @State private var wakeUpCheckTimer: Timer?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var alarm: Alarm? {
        let descriptor = FetchDescriptor<Alarm>(
            predicate: #Predicate { $0.id == alarmID }
        )
        return try? context.fetch(descriptor).first
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showMission, let alarm, !alarm.missions.isEmpty {
                missionView(alarm: alarm)
            } else {
                alarmIdleView
            }
        }
        .onReceive(timer) { time in
            currentTime = time
        }
        .onAppear {
            startAlarmAudio()
            startWakeUpCheck()
        }
        .onDisappear {
            wakeUpCheckTimer?.invalidate()
        }
        .interactiveDismissDisabled(true)
        .statusBarHidden(true)
    }

    private var alarmIdleView: some View {
        VStack(spacing: 40) {
            Spacer()

            Text(currentTime, style: .time)
                .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            if let alarm, !alarm.label.isEmpty {
                Text(alarm.label)
                    .font(.title3)
                    .foregroundStyle(.gray)
            }

            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.orange.opacity(0.3 - Double(i) * 0.08), lineWidth: 2)
                        .frame(width: CGFloat(80 + i * 40), height: CGFloat(80 + i * 40))
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever()
                            .delay(Double(i) * 0.3),
                            value: pulseAnimation
                        )
                }
                Image(systemName: "alarm.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
            }
            .onAppear { pulseAnimation = true }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    withAnimation {
                        showMission = true
                    }
                } label: {
                    Text("START MISSION")
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)

                if let alarm, alarm.snoozeEnabled {
                    Button {
                        snoozeAlarm(alarm: alarm)
                    } label: {
                        Text("Snooze \(alarm.snoozeDuration) min")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding(.bottom, 48)
        }
    }

    @ViewBuilder
    private func missionView(alarm: Alarm) -> some View {
        if missionIndex < alarm.missions.count {
            VStack {
                missionProgressHeader(alarm: alarm)
                MissionRouter(
                    mission: alarm.missions[missionIndex],
                    onComplete: {
                        advanceMission(alarm: alarm)
                    }
                )
            }
        }
    }

    private func missionProgressHeader(alarm: Alarm) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<alarm.missions.count, id: \.self) { i in
                    Circle()
                        .fill(i <= missionIndex ? Color.orange : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            if alarm.missions.count > 1 {
                Text("Mission \(missionIndex + 1) of \(alarm.missions.count)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 8)
    }

    private func advanceMission(alarm: Alarm) {
        let next = missionIndex + 1
        if next >= alarm.missions.count {
            AppState.shared.dismissAlarm()
        } else {
            withAnimation {
                missionIndex = next
            }
        }
    }

    private func startAlarmAudio() {
        guard let alarm else { return }
        AppState.shared.startAlarmAudio(
            soundID: alarm.soundID,
            volume: alarm.volume,
            gradual: alarm.gradualVolume
        )
    }

    private func snoozeAlarm(alarm: Alarm) {
        AppState.shared.stopAlarmAudio()
        let snoozeSeconds = TimeInterval(alarm.snoozeDuration * 60)

        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "Alarm" : alarm.label
        content.body = "Snooze ended — complete your mission!"
        content.sound = nil
        content.userInfo = ["alarmID": alarm.id.uuidString]
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: snoozeSeconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)-snooze",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
        AppState.shared.dismissAlarm()
    }

    private func startWakeUpCheck() {
        guard let alarm, alarm.wakeUpCheckEnabled else { return }
        wakeUpCheckTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { _ in
            missionIndex = 0
            showMission = false
        }
    }
}
