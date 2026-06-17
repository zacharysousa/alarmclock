import Foundation
import UserNotifications

final class AlarmService {
    static let shared = AlarmService()
    private init() {}

    func schedule(_ alarm: Alarm) {
        cancelAll(for: alarm.id)
        guard alarm.isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "Alarm" : alarm.label
        content.body = "Time to wake up! Complete your mission to dismiss."
        content.sound = nil
        content.userInfo = ["alarmID": alarm.id.uuidString]
        content.interruptionLevel = .timeSensitive

        if alarm.repeatDays.isEmpty {
            scheduleOneTime(alarm: alarm, content: content)
        } else {
            for day in alarm.repeatDays {
                scheduleRepeating(alarm: alarm, weekday: day, content: content)
            }
        }
    }

    func cancelAll(for alarmID: UUID) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.content.userInfo["alarmID"] as? String == alarmID.uuidString }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private func scheduleOneTime(alarm: Alarm, content: UNMutableNotificationContent) {
        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)-onetime",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleRepeating(
        alarm: Alarm,
        weekday: Weekday,
        content: UNMutableNotificationContent
    ) {
        var components = DateComponents()
        components.weekday = weekday.calendarWeekday
        components.hour = alarm.hour
        components.minute = alarm.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)-\(weekday.rawValue)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
