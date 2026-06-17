import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            return false
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if let alarmIDString = userInfo["alarmID"] as? String,
           let alarmID = UUID(uuidString: alarmIDString) {
            DispatchQueue.main.async {
                AppState.shared.triggerAlarm(id: alarmID)
            }
        }
        completionHandler([])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let alarmIDString = userInfo["alarmID"] as? String,
           let alarmID = UUID(uuidString: alarmIDString) {
            DispatchQueue.main.async {
                AppState.shared.triggerAlarm(id: alarmID)
            }
        }
        completionHandler()
    }
}
