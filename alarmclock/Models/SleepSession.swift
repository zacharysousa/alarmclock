import Foundation
import SwiftData

enum SnoreSeverity: String, Codable {
    case light, moderate, heavy

    var displayName: String { rawValue.capitalized }
    var color: String {
        switch self {
        case .light: return "green"
        case .moderate: return "yellow"
        case .heavy: return "red"
        }
    }
}

struct SnoreEvent: Codable {
    var timestamp: Date
    var duration: TimeInterval
    var severity: SnoreSeverity
}

struct SleepDepthSample: Codable {
    var timestamp: Date
    var depth: Double  // 0.0 (light) to 1.0 (deep)
}

@Model
final class SleepSession {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var snoreEventsData: Data
    var snoreScore: Int
    var sleepDepthSamplesData: Data

    init(id: UUID = UUID(), startTime: Date = Date()) {
        self.id = id
        self.startTime = startTime
        self.snoreEventsData = Data()
        self.snoreScore = 0
        self.sleepDepthSamplesData = Data()
    }

    var snoreEvents: [SnoreEvent] {
        get { (try? JSONDecoder().decode([SnoreEvent].self, from: snoreEventsData)) ?? [] }
        set { snoreEventsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var sleepDepthSamples: [SleepDepthSample] {
        get { (try? JSONDecoder().decode([SleepDepthSample].self, from: sleepDepthSamplesData)) ?? [] }
        set { sleepDepthSamplesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var durationString: String {
        guard let d = duration else { return "In progress" }
        let hours = Int(d) / 3600
        let minutes = (Int(d) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    var snoreLabel: String {
        switch snoreScore {
        case 0..<20: return "No snoring"
        case 20..<40: return "Light snorer"
        case 40..<60: return "Moderate snorer"
        case 60..<80: return "Heavy snorer"
        default: return "Very heavy snorer"
        }
    }
}
