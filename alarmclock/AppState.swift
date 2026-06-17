import Foundation
import Observation
import AVFoundation

@Observable
final class AppState {
    static let shared = AppState()

    var activeAlarmID: UUID?
    var isAlarmFiring: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var volumeEscalationTimer: Timer?
    private var baseVolume: Float = 0.8

    private init() {}

    func triggerAlarm(id: UUID) {
        activeAlarmID = id
        isAlarmFiring = true
    }

    func dismissAlarm() {
        activeAlarmID = nil
        isAlarmFiring = false
        stopAlarmAudio()
    }

    func startAlarmAudio(soundID: String, volume: Float, gradual: Bool) {
        configureAudioSession()
        baseVolume = volume
        let startVolume = gradual ? volume * 0.3 : volume
        playAlarmSound(soundID: soundID, volume: startVolume)
        if gradual {
            startVolumeEscalation(targetVolume: volume)
        }
    }

    func stopAlarmAudio() {
        volumeEscalationTimer?.invalidate()
        volumeEscalationTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func playAlarmSound(soundID: String, volume: Float) {
        guard let url = Bundle.main.url(forResource: "alarm_\(soundID)", withExtension: "mp3")
                ?? Bundle.main.url(forResource: "alarm_default", withExtension: "mp3") else {
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            print("Audio player error: \(error)")
        }
    }

    private func startVolumeEscalation(targetVolume: Float) {
        var elapsed: TimeInterval = 0
        volumeEscalationTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            elapsed += 30
            let newVolume: Float
            switch elapsed {
            case 30:  newVolume = min(targetVolume * 1.25, 1.0)
            case 60:  newVolume = min(targetVolume * 1.50, 1.0)
            default:  newVolume = 1.0
            }
            self.audioPlayer?.volume = newVolume
        }
    }
}
