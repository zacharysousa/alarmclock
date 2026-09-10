import Foundation
import UserNotifications
import Observation

@Observable
final class BedtimeReminderService {
    static let shared = BedtimeReminderService()

    private static let requestID = "bedtime-reminder"
    private static let enabledKey = "bedtimeReminderEnabled"
    private static let hourKey = "bedtimeReminderHour"
    private static let minuteKey = "bedtimeReminderMinute"

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey); reschedule() }
    }
    var hour: Int {
        didSet { UserDefaults.standard.set(hour, forKey: Self.hourKey); reschedule() }
    }
    var minute: Int {
        didSet { UserDefaults.standard.set(minute, forKey: Self.minuteKey); reschedule() }
    }

    private init() {
        let defaults = UserDefaults.standard
        isEnabled = defaults.bool(forKey: Self.enabledKey)
        hour = defaults.object(forKey: Self.hourKey) as? Int ?? 22
        minute = defaults.object(forKey: Self.minuteKey) as? Int ?? 30
        if isEnabled { reschedule() }
    }

    var timeString: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let m = String(format: "%02d", minute)
        let period = hour < 12 ? "AM" : "PM"
        return "\(h):\(m) \(period)"
    }

    private func reschedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bedtime"
        content.body = "It's almost time to wind down for a consistent sleep schedule."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.requestID, content: content, trigger: trigger)
        center.add(request)
    }
}
