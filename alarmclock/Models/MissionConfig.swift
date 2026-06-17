import Foundation
import SwiftData

enum MissionType: String, Codable, CaseIterable, Identifiable {
    case math, memory, shake, typing, squat, barcode, photo, step

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .math: return "Math"
        case .memory: return "Memory"
        case .shake: return "Shake"
        case .typing: return "Typing"
        case .squat: return "Squat"
        case .barcode: return "Barcode"
        case .photo: return "Photo"
        case .step: return "Step"
        }
    }

    var systemIcon: String {
        switch self {
        case .math: return "plus.forwardslash.minus"
        case .memory: return "square.grid.2x2"
        case .shake: return "iphone.radiowaves.left.and.right"
        case .typing: return "keyboard"
        case .squat: return "figure.strengthtraining.traditional"
        case .barcode: return "barcode.viewfinder"
        case .photo: return "camera"
        case .step: return "figure.walk"
        }
    }

    var defaultRequiredCount: Int {
        switch self {
        case .math: return 3
        case .memory: return 1
        case .shake: return 30
        case .typing: return 1
        case .squat: return 10
        case .barcode: return 1
        case .photo: return 1
        case .step: return 100
        }
    }
}

@Model
final class MissionConfig {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var difficulty: Int
    var requiredCount: Int
    var registeredBarcodeData: String?
    var referencePhotoData: Data?
    var customPhrase: String?
    var alarm: Alarm?

    init(
        id: UUID = UUID(),
        type: MissionType = .math,
        difficulty: Int = 1,
        requiredCount: Int? = nil,
        registeredBarcodeData: String? = nil,
        referencePhotoData: Data? = nil,
        customPhrase: String? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.difficulty = difficulty
        self.requiredCount = requiredCount ?? type.defaultRequiredCount
        self.registeredBarcodeData = registeredBarcodeData
        self.referencePhotoData = referencePhotoData
        self.customPhrase = customPhrase
    }

    var type: MissionType {
        get { MissionType(rawValue: typeRaw) ?? .math }
        set { typeRaw = newValue.rawValue }
    }
}
