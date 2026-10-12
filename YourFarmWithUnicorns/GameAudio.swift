import AVFoundation

enum GameAudio {
    private static var musicPlayer: AVAudioPlayer?
    private static var musicScene = ""
    private static var effectPlayers: [String: AVAudioPlayer] = [:]
    private static var lastEffect: [String: Date] = [:]
    static func stopEffects() { for player in effectPlayers.values { player.stop() } }
    static func chime(enabled: Bool) { effect("task", enabled: enabled) }
    static func music(scene: String, enabled: Bool) {
        guard enabled else { musicPlayer?.pause(); return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            if musicScene != scene || musicPlayer == nil {
                musicPlayer?.stop()
                let url = Bundle.main.url(forResource: "music-\(scene)", withExtension: "wav") ?? Bundle.main.url(forResource: "music-farm", withExtension: "wav")
                guard let url else { return }
                musicPlayer = try AVAudioPlayer(contentsOf: url); musicPlayer?.numberOfLoops = -1
                musicPlayer?.volume = scene == "flight" ? 0.22 : 0.16; musicScene = scene
            }
            if musicPlayer?.isPlaying != true { musicPlayer?.play() }
        } catch { /* Visual feedback remains available if the audio device fails. */ }
    }
    static func effect(_ name: String, enabled: Bool) {
        guard enabled else { return }
        if let previous = lastEffect[name], Date().timeIntervalSince(previous) < 0.18 { return }
        lastEffect[name] = Date()
        do {
            if effectPlayers[name] == nil {
                let resource = name == "task" ? "course-chime" : "sfx-\(name)"
                guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else { return }
                let player = try AVAudioPlayer(contentsOf: url); player.volume = 0.3; effectPlayers[name] = player
            }
            effectPlayers[name]?.currentTime = 0; effectPlayers[name]?.play()
        } catch { }
    }
}
