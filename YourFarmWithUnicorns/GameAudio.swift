import AVFoundation

enum GameAudio {
    private static var player: AVAudioPlayer?
    static func stopEffects() { player?.stop() }
    static func chime(enabled: Bool) {
        guard enabled else { return }
        do {
            if player == nil, let url = Bundle.main.url(forResource: "course-chime", withExtension: "wav") {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                player = try AVAudioPlayer(contentsOf: url)
                player?.volume = 0.35
            }
            player?.currentTime = 0; player?.play()
        } catch { /* Visual feedback remains available when audio cannot play. */ }
    }
}
