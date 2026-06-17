import SwiftUI

struct MissionRouter: View {
    let mission: MissionConfig
    let onComplete: () -> Void

    var body: some View {
        switch mission.type {
        case .math:
            MathMissionView(mission: mission, onComplete: onComplete)
        case .shake:
            ShakeMissionView(mission: mission, onComplete: onComplete)
        case .memory:
            MemoryMissionView(mission: mission, onComplete: onComplete)
        case .typing:
            TypingMissionView(mission: mission, onComplete: onComplete)
        case .squat:
            SquatMissionView(mission: mission, onComplete: onComplete)
        case .barcode:
            BarcodeMissionView(mission: mission, onComplete: onComplete)
        case .photo:
            PhotoMissionView(mission: mission, onComplete: onComplete)
        case .step:
            StepMissionView(mission: mission, onComplete: onComplete)
        }
    }
}
