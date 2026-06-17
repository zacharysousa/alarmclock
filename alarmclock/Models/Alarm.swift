import Foundation
import SwiftData

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var calendarWeekday: Int { rawValue }
}

@Model
final class Alarm {
    @Attribute(.unique) var id: UUID
    var hour: Int
    var minute: Int
    var repeatDaysRaw: [Int]
    var label: String
    var soundID: String
    var volume: Float
    var gradualVolume: Bool
    @Relationship(deleteRule: .cascade, inverse: \MissionConfig.alarm)
    var missions: [MissionConfig]
    var snoozeEnabled: Bool
    var snoozeDuration: Int
    var wakeUpCheckEnabled: Bool
    var isEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        hour: Int = 7,
        minute: Int = 0,
        repeatDays: Set<Weekday> = [],
        label: String = "",
        soundID: String = "default",
        volume: Float = 0.8,
        gradualVolume: Bool = false,
        missions: [MissionConfig] = [],
        snoozeEnabled: Bool = true,
        snoozeDuration: Int = 5,
        wakeUpCheckEnabled: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.repeatDaysRaw = repeatDays.map(\.rawValue)
        self.label = label
        self.soundID = soundID
        self.volume = volume
        self.gradualVolume = gradualVolume
        self.missions = missions
        self.snoozeEnabled = snoozeEnabled
        self.snoozeDuration = snoozeDuration
        self.wakeUpCheckEnabled = wakeUpCheckEnabled
        self.isEnabled = isEnabled
        self.createdAt = Date()
    }

    var repeatDays: Set<Weekday> {
        get { Set(repeatDaysRaw.compactMap(Weekday.init(rawValue:))) }
        set { repeatDaysRaw = newValue.map(\.rawValue) }
    }

    var timeString: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let m = String(format: "%02d", minute)
        let period = hour < 12 ? "AM" : "PM"
        return "\(h):\(m) \(period)"
    }

    var repeatSummary: String {
        if repeatDays.isEmpty { return "Once" }
        if repeatDays.count == 7 { return "Every day" }
        let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday]
        let weekend: [Weekday] = [.saturday, .sunday]
        if Set(weekdays) == repeatDays { return "Weekdays" }
        if Set(weekend) == repeatDays { return "Weekends" }
        let sorted = repeatDays.sorted { $0.rawValue < $1.rawValue }
        return sorted.map(\.shortName).joined(separator: " ")
    }
}
