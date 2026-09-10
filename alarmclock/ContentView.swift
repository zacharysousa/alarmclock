import SwiftUI

struct ContentView: View {
    @State private var appState = AppState.shared
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                AlarmListView()
                    .tabItem {
                        Label("Alarm", systemImage: "alarm.fill")
                    }
                    .tag(0)

                SleepCycleCalculatorView()
                    .tabItem {
                        Label("Cycles", systemImage: "bed.double.fill")
                    }
                    .tag(1)

                SleepView()
                    .tabItem {
                        Label("Sleep", systemImage: "moon.fill")
                    }
                    .tag(2)

                SoundsView()
                    .tabItem {
                        Label("Sounds", systemImage: "waveform")
                    }
                    .tag(3)
            }
            .tint(.orange)
            .preferredColorScheme(.dark)
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.black
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }

            if appState.isAlarmFiring, let alarmID = appState.activeAlarmID {
                AlarmFireView(alarmID: alarmID)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAlarmFiring)
    }
}
