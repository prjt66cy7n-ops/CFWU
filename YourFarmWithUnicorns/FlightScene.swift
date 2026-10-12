import SpriteKit
import SwiftUI

final class FlightScene: SKScene {
    var onFinish: (() -> Void)?
    private var flight = FlightGame()
    private let normal: HorseNode
    private let unicorn: HorseNode
    private let landscape: SKNode
    private let particles = SKNode()
    private let banner = SKNode()
    private var previousTime: TimeInterval?
    private var finished = false
    private var finaleShown = false
    private var nextSparkle = 0.0
    private var player: Player
    init(player: Player) {
        self.player = player
        normal = HorseNode(player: player)
        unicorn = HorseNode(player: player, unicorn: true)
        landscape = FarmLandscape.make(playerName: player.name)
        super.init(size: CGSize(width: 1000, height: 620)); scaleMode = .aspectFit
        backgroundColor = UIColor(red: 0.61, green: 0.8, blue: 0.94, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func didMove(to view: SKView) {
        landscape.alpha = 0.8; addChild(landscape)
        addChild(particles); addChild(normal); addChild(unicorn); addChild(banner)
        normal.setScale(CGFloat(player.horse.size.scale * 2)); unicorn.setScale(CGFloat(player.horse.size.scale * 2))
        normal.zPosition = 1500; unicorn.zPosition = 1500; particles.zPosition = 1600; banner.zPosition = 3000
        unicorn.isHidden = true
        for index in 0..<12 {
            let kind = index % 4
            let col = kind == 3 ? 0 : kind + 1
            let row = kind == 3 ? 2 : 1
            let node: SKNode
            if let image = GameArt.region(sheet: "MagicEffectsSheet", column: col, row: row, columns: 4, rows: 3) {
                let sprite = SKSpriteNode(texture: SKTexture(image: image)); sprite.size = CGSize(width: 65, height: 65)
                node = sprite
            } else {
                let label = SKLabelNode(text: ["⭐️", "💗", "🦋", "🌈"][kind]); label.fontSize = 36; node = label
            }
            node.name = "collect-\(kind)"
            node.position = CGPoint(x: 130 + (index % 6) * 145, y: index < 6 ? 455 : 265)
            particles.addChild(node)
            node.run(.repeatForever(.sequence([.moveBy(x: 0, y: 12, duration: 1 + Double(index) * 0.07), .moveBy(x: 0, y: -12, duration: 1 + Double(index) * 0.07)])))
        }
        GameAudio.effect("wand", enabled: player.sfxEnabled)
    }
    func updatePlayer(_ player: Player) { self.player = player }
    func pause() { previousTime = nil; isPaused = true }
    func resume() { previousTime = nil; isPaused = false }
    override func update(_ currentTime: TimeInterval) {
        defer { previousTime = currentTime }
        guard let previous = previousTime, !finished else { return }
        flight.step(seconds: currentTime - previous)
        let t = flight.elapsed
        let point = RidePoint(x: 220 + flight.routeProgress * 570, y: 330 + sin(flight.routeProgress * .pi * 2) * 75)
        normal.render(point: point, facing: .east, gait: .walk, moving: false, time: t, jumpHeight: 0)
        let glide = Int(t) % 9 >= 6
        unicorn.render(point: point, facing: .east, gait: .canter, moving: true, time: glide ? t * 0.18 : t * 0.45, jumpHeight: 9 + sin(t * 1.4) * 4)
        normal.zPosition = 1500; unicorn.zPosition = 1500; unicorn.flightMotion(time: t)
        if flight.phase == .transformation {
            normal.isHidden = t > 1.25; unicorn.isHidden = t < 2
            if t >= nextSparkle { sparkle(at: CGPoint(x: point.x + cos(t * 12) * 85, y: point.y + sin(t * 12) * 65), rainbow: false); nextSparkle = t + 0.08 }
        } else {
            normal.isHidden = true; unicorn.isHidden = false
            landscape.setScale(CGFloat(0.95 + flight.routeProgress * 0.04))
            if flight.rainbowStars > 0 && t >= nextSparkle {
                sparkle(at: CGPoint(x: point.x - 70, y: point.y - 5), rainbow: true); nextSparkle = t + 0.12
            }
        }
        if flight.phase == .finale && !finaleShown {
            finaleShown = true
            let backing = SKShapeNode(rectOf: CGSize(width: 850, height: 135), cornerRadius: 32)
            backing.position = CGPoint(x: 500, y: 490); backing.fillColor = UIColor(red: 1, green: 0.95, blue: 0.78, alpha: 0.98)
            backing.strokeColor = .systemPink; backing.lineWidth = 8; banner.addChild(backing)
            let text = SKLabelNode(text: "What a wonderful day!"); text.fontName = "AvenirNext-Bold"; text.fontColor = .systemPurple
            text.fontSize = 40; text.position = CGPoint(x: 500, y: 490); banner.addChild(text)
            let rainbow = SKLabelNode(text: "🌈 ✨ 🌈"); rainbow.fontSize = 38; rainbow.position = CGPoint(x: 500, y: 435); banner.addChild(rainbow)
            GameAudio.effect("ribbon", enabled: player.sfxEnabled)
        }
        if flight.phase == .finished { finished = true; DispatchQueue.main.async { [weak self] in self?.onFinish?() } }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard flight.phase == .flying, let point = touches.first?.location(in: self) else { return }
        if let node = particles.nodes(at: point).first(where: { $0.name?.hasPrefix("collect-") == true }) {
            if node.name == "collect-0" { flight.tapStar() }
            sparkle(at: node.position, rainbow: true)
            node.run(.sequence([.scale(to: 1.5, duration: 0.12), .scale(to: 1, duration: 0.2)]))
            GameAudio.effect("magic", enabled: player.sfxEnabled)
        }
    }
    private func sparkle(at point: CGPoint, rainbow: Bool) {
        let sparkle = SKLabelNode(text: rainbow ? ["✨", "🌈", "💗"][Int.random(in: 0..<3)] : "✨")
        sparkle.fontSize = rainbow ? 23 : 32; sparkle.position = point; particles.addChild(sparkle)
        sparkle.run(.sequence([.group([.moveBy(x: -25, y: 15, duration: 0.8), .fadeOut(withDuration: 0.8)]), .removeFromParent()]))
    }
}
struct FlightScreen: View {
    @State private var scene: FlightScene
    @Environment(\.scenePhase) private var phase
    let player: Player
    let paused: Bool
    let finish: () -> Void
    init(player: Player, paused: Bool, finish: @escaping () -> Void) {
        self.player = player; self.paused = paused; self.finish = finish
        _scene = State(initialValue: FlightScene(player: player))
    }
    var body: some View {
        SpriteView(scene: scene).clipShape(RoundedRectangle(cornerRadius: 24))
            .accessibilityIdentifier("unicorn-flight")
            .onAppear { scene.onFinish = finish; updatePause() }
            .onDisappear { scene.pause() }
            .onChange(of: paused) { _ in updatePause() }
            .onChange(of: phase) { _ in updatePause() }
            .onChange(of: player) { scene.updatePlayer($0) }
            .accessibilityLabel("Unicorn flight above your farm. Tap stars, hearts, butterflies and rainbows.")
    }
    private func updatePause() { if paused || phase != .active { scene.pause() } else { scene.resume() } }
}
