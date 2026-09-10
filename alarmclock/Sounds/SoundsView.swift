import SwiftUI
import AVFoundation

@Observable
final class AudioPlayerService {
    static let shared = AudioPlayerService()

    /// Track IDs currently mixed in, each with its own relative volume (0...1).
    var activeTrackVolumes: [String: Float] = [:]
    var masterVolume: Float = 0.8
    var sleepTimerMinutes: Int = 0
    var sleepTimerRemaining: TimeInterval = 0

    var isPlaying: Bool { !players.isEmpty }

    private var players: [String: AVAudioPlayer] = [:]
    private var sleepTimer: Timer?
    private var fadeTimer: Timer?

    private init() {}

    func isActive(_ trackID: String) -> Bool {
        players[trackID] != nil
    }

    func toggle(track: SoundTrack) {
        if isActive(track.id) {
            stop(trackID: track.id)
        } else {
            play(track: track)
        }
    }

    func play(track: SoundTrack) {
        guard players[track.id] == nil else { return }
        configureSession()
        guard let url = Bundle.main.url(forResource: track.filename.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") else { return }
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            let trackVolume: Float = activeTrackVolumes[track.id] ?? 1.0
            newPlayer.volume = trackVolume * masterVolume
            newPlayer.numberOfLoops = -1
            newPlayer.play()
            players[track.id] = newPlayer
            activeTrackVolumes[track.id] = trackVolume
        } catch {}
    }

    func stop(trackID: String) {
        players[trackID]?.stop()
        players[trackID] = nil
        activeTrackVolumes[trackID] = nil
        if players.isEmpty { cancelTimer() }
    }

    func stopAll() {
        for player in players.values { player.stop() }
        players.removeAll()
        activeTrackVolumes.removeAll()
        cancelTimer()
    }

    func setTrackVolume(_ trackID: String, volume: Float) {
        activeTrackVolumes[trackID] = volume
        players[trackID]?.volume = volume * masterVolume
    }

    func setMasterVolume(_ value: Float) {
        masterVolume = value
        for (id, player) in players {
            let trackVolume = activeTrackVolumes[id] ?? 1.0
            player.volume = trackVolume * value
        }
    }

    func setSleepTimer(minutes: Int) {
        cancelTimer()
        sleepTimerMinutes = minutes
        sleepTimerRemaining = TimeInterval(minutes * 60)
        guard minutes > 0 else { return }

        let fadeStartTime = max(0, sleepTimerRemaining - 300)
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeStartTime) { [weak self] in
            self?.startFadeOut()
        }
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            sleepTimerRemaining -= 1
            if sleepTimerRemaining <= 0 { stopAll() }
        }
    }

    private func startFadeOut() {
        let startVolumes = activeTrackVolumes
        var elapsed: TimeInterval = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            elapsed += 1
            let fraction = Float(max(0, 1.0 - (elapsed / 300.0)))
            for (id, base) in startVolumes {
                players[id]?.volume = fraction * base * masterVolume
            }
        }
    }

    private func cancelTimer() {
        sleepTimer?.invalidate(); sleepTimer = nil
        fadeTimer?.invalidate(); fadeTimer = nil
        sleepTimerRemaining = 0
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}

struct SoundsView: View {
    @State private var service = AudioPlayerService.shared
    @State private var selectedCategory: SoundCategory = .nature
    @State private var showTimerPicker = false

    private var filteredTracks: [SoundTrack] {
        SoundTrack.library.filter { $0.category == selectedCategory }
    }

    private var activeTracks: [SoundTrack] {
        SoundTrack.library.filter { service.isActive($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    categoryTabs
                    ScrollView {
                        VStack(spacing: 20) {
                            soundGrid
                            if !activeTracks.isEmpty {
                                mixerSection
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    Divider().background(Color.gray.opacity(0.2))
                    volumeBar
                }
            }
            .navigationTitle("Sounds")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showTimerPicker = true
                    } label: {
                        Image(systemName: "timer")
                            .foregroundStyle(service.sleepTimerRemaining > 0 ? .orange : .gray)
                    }
                }
            }
            .sheet(isPresented: $showTimerPicker) {
                TimerPickerView(service: service)
            }
        }
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SoundCategory.allCases) { cat in
                    Button {
                        selectedCategory = cat
                    } label: {
                        Text(cat.displayName)
                            .font(.subheadline.bold())
                            .foregroundStyle(selectedCategory == cat ? .black : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == cat ? Color.white : Color(white: 0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    private var soundGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(filteredTracks) { track in
                SoundCardView(track: track, service: service)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var mixerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MIXING \(activeTracks.count) SOUND\(activeTracks.count == 1 ? "" : "S")")
                .font(.caption.bold())
                .foregroundStyle(.gray)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(activeTracks) { track in
                    mixerRow(track)
                }
            }
            .padding(.horizontal)
        }
    }

    private func mixerRow(_ track: SoundTrack) -> some View {
        HStack(spacing: 12) {
            Text(track.name)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 90, alignment: .leading)

            Slider(value: Binding(
                get: { Double(service.activeTrackVolumes[track.id] ?? 1.0) },
                set: { service.setTrackVolume(track.id, volume: Float($0)) }
            ))
            .tint(.orange)

            Button {
                service.stop(trackID: track.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var volumeBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .foregroundStyle(.gray)
            Slider(value: Binding(
                get: { Double(service.masterVolume) },
                set: { service.setMasterVolume(Float($0)) }
            ))
            .tint(.white)
            Image(systemName: "speaker.wave.3.fill")
                .foregroundStyle(.gray)
        }
        .padding()
    }
}

struct SoundCardView: View {
    let track: SoundTrack
    let service: AudioPlayerService

    private var isActive: Bool { service.isActive(track.id) }

    private var icon: String {
        switch track.id {
        case "rain": return "cloud.rain.fill"
        case "ocean": return "water.waves"
        case "forest": return "tree.fill"
        case "thunder": return "cloud.bolt.fill"
        case "white_noise": return "waveform"
        case "brown_noise": return "waveform.path"
        case "pink_noise": return "waveform.badge.plus"
        case "fireplace": return "flame.fill"
        case "fan": return "wind"
        default: return "music.note"
        }
    }

    var body: some View {
        Button {
            service.toggle(track: track)
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    if isActive {
                        ForEach(0..<2) { i in
                            Circle()
                                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                                .scaleEffect(isActive ? 1.3 + Double(i) * 0.2 : 1.0)
                        }
                    }
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundStyle(isActive ? .orange : .gray)
                }
                .frame(width: 60, height: 60)

                Text(track.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(isActive ? .white : .gray)

                if track.isPremium {
                    Text("PRO")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isActive ? Color(white: 0.15) : Color(white: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? Color.orange : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

struct TimerPickerView: View {
    let service: AudioPlayerService
    @Environment(\.dismiss) private var dismiss
    @State private var selected = 0

    private let options = [0, 15, 30, 45, 60, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    ForEach(options, id: \.self) { min in
                        Button {
                            service.setSleepTimer(minutes: min)
                            dismiss()
                        } label: {
                            HStack {
                                Text(min == 0 ? "No timer" : "\(min) minutes")
                                    .foregroundStyle(.white)
                                Spacer()
                                if service.sleepTimerMinutes == min {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding()
                            .background(Color(white: 0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(.orange)
                }
            }
        }
    }
}
