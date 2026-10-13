import SpriteKit
import Combine

final class RidingScene: SKScene {
    enum Mode { case arena, roundYard }
    let mode: Mode
    var arena = ArenaRide()
    var yard = RoundYardRide()
    var joystick = RidePoint.zero
    var soundEnabled: Bool
    private var animalElapsed = 0.0
    private var nextAnimal = Double.random(in: 12...24)
    var onProgress: ((Int, String?, [String]) -> Void)?
    private let horse: HorseNode
    private let horseSize: Double
    private let obstacles = SKNode()
    private var lastTime: TimeInterval?
    private var animationTime = 0.0
    init(player: Player, mode: Mode) {
        self.mode = mode; horseSize = player.horse.size.scale; horse = HorseNode(player: player); soundEnabled = player.sfxEnabled
        super.init(size: CGSize(width: ArenaRide.width, height: ArenaRide.height))
        horse.enableAngledRiding(player: player)
        scaleMode = .aspectFit
        backgroundColor = UIColor(red: 0.71, green: 0.84, blue: 0.57, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func didMove(to view: SKView) {
        removeAllChildren()
        if let background = GameArt.background(sheet: "FarmEnvironmentSheet", column: mode == .arena ? 0 : 1, row: 0, size: size) {
            addChild(background)
        }
        obstacles.zPosition = 1; addChild(obstacles); addChild(horse)
        rebuildEquipment()
        renderHorse()
    }
    func resume() { lastTime = nil; isPaused = false }
    func pause() { joystick = .zero; isPaused = true; lastTime = nil }
    func chooseCourse(_ index: Int) {
        arena.chooseCourse(index); rebuildEquipment(); renderHorse()
        onProgress?(0, nil, [])
    }
    func setGait(_ gait: RideGait) { arena.gait = gait; yard.setGait(gait) }
    func togglePoles() { yard.togglePoles(); rebuildEquipment() }
    func changeDirection() { yard.changeDirection() }
    override func update(_ currentTime: TimeInterval) {
        guard let previous = lastTime else { lastTime = currentTime; return }
        lastTime = currentTime
        let dt = min(0.1, max(0, currentTime - previous)); animationTime += dt
        animalElapsed += dt
        if animalElapsed > nextAnimal {
            animalElapsed = 0; nextAnimal = Double.random(in: 14...28)
            GameAudio.effect("horse-\(Int.random(in: 1...3))", enabled: soundEnabled); horse.flickTail()
        }
        if mode == .arena {
            let previousFallen = arena.fallenPoles
            let previousCompleted = arena.completedJumps
            arena.step(seconds: dt, input: joystick)
            if previousFallen != arena.fallenPoles || previousCompleted != arena.completedJumps { rebuildEquipment() }
            var events: [String] = []
            if arena.justCompletedCourse { events = [arena.course.id]; celebrate() }
            onProgress?(arena.completedJumps.count, arena.feedback, events)
        } else {
            yard.step(seconds: dt)
            if !yard.completedActivities.isEmpty { celebrate() }
            onProgress?(0, yard.completedActivities.isEmpty ? nil : "Wonderful circuit!", yard.completedActivities)
        }
        renderHorse()
    }
    private func renderHorse() {
        if mode == .arena {
            horse.setScale(CGFloat(horseSize * (0.9 + 0.25 * (1 - arena.position.y / 620))))
            horse.render(point: projected(arena.position), facing: arena.facing, gait: arena.gait,
                         moving: joystick.length > 0.04 || arena.isJumping, time: animationTime, jumpHeight: arena.jumpHeight)
        } else {
            let polePhase = abs(sin(yard.angle * 2))
            horse.setScale(CGFloat(horseSize * (0.9 + 0.25 * (1 - yard.position.y / 620))))
            horse.render(point: projected(yard.position), facing: yard.facing, gait: yard.gait,
                         moving: yard.speedMultiplier > 0.05, time: animationTime,
                         jumpHeight: yard.polesEnabled && polePhase < 0.18 ? 4 : 0)
        }
    }
    private func projected(_ point: RidePoint) -> RidePoint {
        let depth = min(1, max(0, point.y / 620))
        let width = 1 - depth * 0.22
        return RidePoint(x: 500 + (point.x - 500) * width + (point.y - 310) * 0.12, y: 100 + point.y * 0.5)
    }
    private func rebuildEquipment() {
        obstacles.removeAllChildren()
        if mode == .arena {
            let colors: [UIColor] = [.systemPink, .systemPurple, .systemBlue]
            let next = arena.course.jumps.first { !arena.completedJumps.contains($0.id) }
            for jump in arena.course.jumps {
                let item = SKNode(); item.name = "pole-\(jump.id)"
                let center = projected(jump.center)
                item.position = CGPoint(x: center.x, y: center.y)
                item.zPosition = CGFloat(700 - center.y)
                let tangent = RidePoint(x: -jump.normal.y * jump.halfWidth, y: jump.normal.x * jump.halfWidth)
                let start = projected(jump.center + tangent), end = projected(jump.center - tangent)
                let a = CGPoint(x: start.x - center.x, y: start.y - center.y)
                let b = CGPoint(x: end.x - center.x, y: end.y - center.y)
                let color = arena.courseIndex == 2 ? UIColor.systemGreen : colors[jump.id % colors.count]
                let fallen = arena.fallenPoles.contains(jump.id)
                for point in [a, b] {
                    let upright = SKShapeNode(rectOf: CGSize(width: 10, height: 44), cornerRadius: 2)
                    upright.position = CGPoint(x: point.x, y: point.y + 22)
                    upright.fillColor = .white; upright.strokeColor = color; upright.lineWidth = 3; item.addChild(upright)
                    let flowers = SKShapeNode(ellipseOf: CGSize(width: 18, height: 9))
                    flowers.position = point; flowers.fillColor = .systemPink; flowers.strokeColor = .systemGreen; item.addChild(flowers)
                }
                for height: CGFloat in [14, 34] {
                    let path = CGMutablePath(); path.move(to: CGPoint(x: a.x, y: a.y + (fallen ? 2 : height)))
                    path.addLine(to: CGPoint(x: b.x, y: b.y + (fallen ? 2 : height)))
                    let rail = SKShapeNode(path: path); rail.lineWidth = 7; rail.strokeColor = color; item.addChild(rail)
                    for index in 0..<5 {
                        let t = CGFloat(index) / 5
                        let stripe = CGMutablePath()
                        stripe.move(to: CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t + (fallen ? 2 : height)))
                        stripe.addLine(to: CGPoint(x: a.x + (b.x - a.x) * (t + 0.09), y: a.y + (b.y - a.y) * (t + 0.09) + (fallen ? 2 : height)))
                        let white = SKShapeNode(path: stripe); white.strokeColor = .white; white.lineWidth = 7; item.addChild(white)
                    }
                }
                if next?.id == jump.id {
                    let glow = SKShapeNode(ellipseOf: CGSize(width: 160, height: 65))
                    glow.fillColor = .clear; glow.strokeColor = .systemYellow; glow.lineWidth = 3; item.addChild(glow)
                }
                if arena.completedJumps.contains(jump.id) {
                    let tick = SKLabelNode(text: "✓"); tick.fontColor = .systemGreen; tick.fontSize = 22
                    tick.position = CGPoint(x: b.x + 15, y: b.y + 45); item.addChild(tick)
                }
                obstacles.addChild(item)
            }
        } else if yard.polesEnabled {
            for index in 0..<4 {
                let angle = Double(index) * .pi / 2
                let point = projected(RidePoint(x: 500 + cos(angle) * 280, y: 310 + sin(angle) * 215))
                let pole = SKShapeNode(rectOf: CGSize(width: 65, height: 7), cornerRadius: 3)
                pole.position = CGPoint(x: point.x, y: point.y); pole.zRotation = CGFloat(angle * 0.4)
                pole.fillColor = .systemBlue; pole.strokeColor = .white; pole.lineWidth = 2; obstacles.addChild(pole)
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard mode == .arena, let touch = touches.first else { return }
        for hit in nodes(at: touch.location(in: self)) {
            var current: SKNode? = hit
            while let node = current {
                if let name = node.name, name.hasPrefix("pole-"), let id = Int(name.dropFirst(5)), arena.fallenPoles.contains(id) {
                    arena.resetPole(id); rebuildEquipment(); return
                }
                current = node.parent
            }
        }
    }
    private func celebrate() {
        let label = SKLabelNode(text: "✨ ✓ ✨")
        label.fontSize = 48; label.position = CGPoint(x: 500, y: 470); label.zPosition = 2000
        addChild(label); label.run(.sequence([.moveBy(x: 0, y: 25, duration: 0.3), .wait(forDuration: 0.8), .fadeOut(withDuration: 0.4), .removeFromParent()]))
    }
}

final class RidingSession: ObservableObject {
    let scene: RidingScene
    @Published var gait: RideGait = .walk
    @Published var courseIndex = 0
    @Published var progress = 0
    @Published var polesEnabled = false
    @Published var notice = ""
    private var noticeExpiry = Date.distantPast
    init(player: Player, mode: RidingScene.Mode, onActivity: @escaping (String) -> Void) {
        scene = RidingScene(player: player, mode: mode)
        scene.onProgress = { [weak self] progress, message, activities in
            guard let self else { return }
            if self.progress != progress { self.progress = progress }
            if let message { self.notice = message; self.noticeExpiry = Date().addingTimeInterval(3) }
            else if !self.notice.isEmpty && Date() > self.noticeExpiry { self.notice = "" }
            for activity in activities { onActivity(activity) }
            if mode == .arena && !activities.isEmpty {
                self.notice = "Wonderful course! Keep riding or pick another."; self.noticeExpiry = Date().addingTimeInterval(4)
            }
        }
    }
    func setGait(_ gait: RideGait) { self.gait = gait; scene.setGait(gait) }
    func chooseCourse(_ index: Int) {
        courseIndex = index; gait = .walk; progress = 0; notice = ""; scene.chooseCourse(index)
    }
    func togglePoles() { polesEnabled.toggle(); scene.togglePoles() }
}
