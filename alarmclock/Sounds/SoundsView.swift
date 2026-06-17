import SwiftUI
import AVFoundation

@Observable
final class AudioPlayerService {
    static let shared = AudioPlayerService()

    var currentTrackID: String?
    var isPlaying = false
    var volume: Float = 0.8
    var sleepTimerMinutes: Int = 0
    var sleepTimerRemaining: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var sleepTimer: Timer?
    private var fadeTimer: Timer?

    private init() {}

    func play(track: SoundTrack) {
        stop()
        currentTrackID = track.id
        configureSession()
        guard let url = Bundle.main.url(forResource: track.filename.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.numberOfLoops = -1
            player?.play()
            isPlaying = true
        } catch {}
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTrackID = nil
        cancelTimer()
    }

    func setVolume(_ value: Float) {
        volume = value
        player?.volume = value
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
            if sleepTimerRemaining <= 0 { stop() }
        }
    }

    private func startFadeOut() {
        let startVolume = player?.volume ?? volume
        var elapsed: TimeInterval = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            elapsed += 1
            let fraction = 1.0 - (elapsed / 300.0)
            player?.volume = Float(max(0, fraction)) * startVolume
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
    private let service = AudioPlayerService.shared
    @State private var selectedCategory: SoundCategory = .nature
    @State private var showTimerPicker = false

    private var filteredTracks: [SoundTrack] {
        SoundTrack.library.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    categoryTabs
                    soundGrid
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
                        Image(systemName: service.sleepTimerRemaining > 0 ? "timer" : "timer")
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
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(filteredTracks) { track in
                    SoundCardView(track: track, service: service)
                }
            }
            .padding()
        }
    }

    private var volumeBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .foregroundStyle(.gray)
            Slider(value: Binding(
                get: { Double(service.volume) },
                set: { service.setVolume(Float($0)) }
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

    private var isActive: Bool { service.currentTrackID == track.id }

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
            if isActive {
                service.stop()
            } else {
                service.play(track: track)
            }
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
