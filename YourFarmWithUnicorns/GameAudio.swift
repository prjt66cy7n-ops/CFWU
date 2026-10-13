import AVFoundation

enum GameAudio {
    private static let queue = DispatchQueue(label: "farm.audio", qos: .userInitiated)
    private static var configured = false
    private static func configure() throws {
        guard !configured else { return }
        try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        configured = true
    }
    private static var musicPlayer: AVAudioPlayer?
    private static var waterPlayer: AVAudioPlayer?
    private static var musicScene = ""
    private static var effectPlayers: [String: AVAudioPlayer] = [:]
    private static var lastEffect: [String: Date] = [:]
    static func stopEffects() { queue.async { for player in effectPlayers.values { player.stop() }; waterPlayer?.stop() } }
    static func waterFlow(enabled: Bool) {
        queue.async {
            guard enabled else { waterPlayer?.stop(); return }
            do {
                try configure()
                if waterPlayer == nil, let url = Bundle.main.url(forResource: "sfx-water", withExtension: "wav") {
                    waterPlayer = try AVAudioPlayer(contentsOf: url)
                    waterPlayer?.numberOfLoops = -1; waterPlayer?.volume = 0.25
                }
                if waterPlayer?.isPlaying != true { waterPlayer?.play() }
            } catch { }
        }
    }
    static func chime(enabled: Bool) { effect("task", enabled: enabled) }
    static func music(scene: String, enabled: Bool) {
        queue.async { playMusic(scene: scene, enabled: enabled) }
    }
    private static func playMusic(scene: String, enabled: Bool) {
        guard enabled else { musicPlayer?.pause(); return }
        do {
            try configure()
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
        queue.async { playEffect(name, enabled: enabled) }
    }
    private static func playEffect(_ name: String, enabled: Bool) {
        guard enabled else { return }
        if let previous = lastEffect[name], Date().timeIntervalSince(previous) < 0.18 { return }
        lastEffect[name] = Date()
        do {
            try configure()
            if effectPlayers[name] == nil {
                let resource = name == "task" ? "course-chime" : "sfx-\(name)"
                guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else { return }
                let player = try AVAudioPlayer(contentsOf: url); player.volume = 0.3; effectPlayers[name] = player
            }
            if name == "water", effectPlayers[name]?.isPlaying == true { return }
            effectPlayers[name]?.currentTime = 0; effectPlayers[name]?.play()
        } catch { }
    }
}
