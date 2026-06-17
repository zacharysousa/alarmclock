import SwiftUI
import SwiftData
import UserNotifications

@main
struct alarmclockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Alarm.self, MissionConfig.self, SleepSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = NotificationManager.shared
        Task {
            await NotificationManager.shared.requestAuthorization()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if AppState.shared.isAlarmFiring {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.isIdleTimerDisabled = AppState.shared.isAlarmFiring
    }
}
