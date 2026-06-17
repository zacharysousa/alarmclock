import Foundation

enum SoundCategory: String, Codable, CaseIterable, Identifiable {
    case nature, noise, asmr, binaural

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

struct SoundTrack: Identifiable, Codable {
    var id: String
    var name: String
    var category: SoundCategory
    var filename: String
    var isPremium: Bool

    static let library: [SoundTrack] = [
        SoundTrack(id: "rain", name: "Rain", category: .nature, filename: "rain.mp3", isPremium: false),
        SoundTrack(id: "ocean", name: "Ocean", category: .nature, filename: "ocean.mp3", isPremium: false),
        SoundTrack(id: "forest", name: "Forest", category: .nature, filename: "forest.mp3", isPremium: false),
        SoundTrack(id: "thunder", name: "Thunder", category: .nature, filename: "thunder.mp3", isPremium: true),
        SoundTrack(id: "white_noise", name: "White Noise", category: .noise, filename: "white_noise.mp3", isPremium: false),
        SoundTrack(id: "brown_noise", name: "Brown Noise", category: .noise, filename: "brown_noise.mp3", isPremium: false),
        SoundTrack(id: "pink_noise", name: "Pink Noise", category: .noise, filename: "pink_noise.mp3", isPremium: true),
        SoundTrack(id: "fireplace", name: "Fireplace", category: .asmr, filename: "fireplace.mp3", isPremium: false),
        SoundTrack(id: "fan", name: "Fan", category: .asmr, filename: "fan.mp3", isPremium: false),
        SoundTrack(id: "binaural_sleep", name: "Sleep Waves", category: .binaural, filename: "binaural_sleep.mp3", isPremium: true),
        SoundTrack(id: "binaural_focus", name: "Focus Waves", category: .binaural, filename: "binaural_focus.mp3", isPremium: true),
    ]

    static let alarmSounds: [SoundTrack] = [
        SoundTrack(id: "default", name: "Default", category: .noise, filename: "alarm_default.mp3", isPremium: false),
        SoundTrack(id: "gentle", name: "Gentle Rise", category: .nature, filename: "alarm_gentle.mp3", isPremium: false),
        SoundTrack(id: "radar", name: "Radar", category: .noise, filename: "alarm_radar.mp3", isPremium: false),
        SoundTrack(id: "bell", name: "Bell", category: .asmr, filename: "alarm_bell.mp3", isPremium: false),
        SoundTrack(id: "digital", name: "Digital", category: .noise, filename: "alarm_digital.mp3", isPremium: true),
    ]
}
