import Foundation
import SwiftData
import Observation

@Observable
final class AlarmViewModel {
    var editingAlarm: Alarm?
    var isShowingEditor = false

    func addAlarm(context: ModelContext) {
        let alarm = Alarm()
        let defaultMission = MissionConfig(type: .math, difficulty: 1, requiredCount: 3)
        alarm.missions = [defaultMission]
        context.insert(alarm)
        context.insert(defaultMission)
        AlarmService.shared.schedule(alarm)
        editingAlarm = alarm
        isShowingEditor = true
    }

    func edit(_ alarm: Alarm) {
        editingAlarm = alarm
        isShowingEditor = true
    }

    func save(_ alarm: Alarm, context: ModelContext) {
        try? context.save()
        AlarmService.shared.schedule(alarm)
        isShowingEditor = false
        editingAlarm = nil
    }

    func delete(_ alarm: Alarm, context: ModelContext) {
        AlarmService.shared.cancelAll(for: alarm.id)
        context.delete(alarm)
        try? context.save()
    }

    func toggle(_ alarm: Alarm, context: ModelContext) {
        alarm.isEnabled.toggle()
        AlarmService.shared.schedule(alarm)
        try? context.save()
    }

    func cancelEdit(alarm: Alarm, context: ModelContext) {
        if context.hasChanges {
            context.rollback()
        }
        isShowingEditor = false
        editingAlarm = nil
    }
}
