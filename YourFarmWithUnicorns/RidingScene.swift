import SpriteKit
import Combine

final class RidingScene: SKScene {
    enum Mode { case arena, roundYard }
    let mode: Mode
    var arena = ArenaRide()
    var yard = RoundYardRide()
    var joystick = RidePoint.zero
    var onProgress: ((Int, String?, [String]) -> Void)?
    private let horse: HorseNode
    private let obstacles = SKNode()
    private var lastTime: TimeInterval?
    private var animationTime = 0.0
    init(player: Player, mode: Mode) {
        self.mode = mode; horse = HorseNode(player: player)
        super.init(size: CGSize(width: ArenaRide.width, height: ArenaRide.height))
        scaleMode = .aspectFit
        backgroundColor = UIColor(red: 0.71, green: 0.84, blue: 0.57, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func didMove(to view: SKView) {
        removeAllChildren()
        let footing = SKShapeNode(rectOf: CGSize(width: 910, height: 530), cornerRadius: mode == .arena ? 90 : 240)
        footing.position = CGPoint(x: 500, y: 310)
        footing.fillColor = UIColor(red: 0.95, green: 0.79, blue: 0.54, alpha: 1)
        footing.strokeColor = .brown; footing.lineWidth = 10; addChild(footing)
        for i in 0..<12 {
            let angle = Double(i) / 12 * .pi * 2
            let post = SKShapeNode(rectOf: CGSize(width: 9, height: 20), cornerRadius: 2)
            post.position = CGPoint(x: 500 + cos(angle) * 448, y: 310 + sin(angle) * 259)
            post.fillColor = .brown; post.strokeColor = .clear; addChild(post)
        }
        let artLabel = SKLabelNode(text: "DRAFT RIDING ART")
        artLabel.fontName = "AvenirNext-DemiBold"; artLabel.fontSize = 12
        artLabel.fontColor = .darkGray; artLabel.position = CGPoint(x: 500, y: 18); addChild(artLabel)
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
            horse.render(point: arena.position, facing: arena.facing, gait: arena.gait,
                         moving: joystick.length > 0.04 || arena.isJumping, time: animationTime, jumpHeight: arena.jumpHeight)
        } else {
            let polePhase = abs(sin(yard.angle * 2))
            horse.render(point: yard.position, facing: yard.facing, gait: yard.gait,
                         moving: yard.speedMultiplier > 0.05, time: animationTime,
                         jumpHeight: yard.polesEnabled && polePhase < 0.18 ? 4 : 0)
        }
    }
    private func rebuildEquipment() {
        obstacles.removeAllChildren()
        if mode == .arena {
            let colors: [UIColor] = [.systemPink, .systemPurple, .systemBlue]
            let next = arena.course.jumps.first { !arena.completedJumps.contains($0.id) }
            for jump in arena.course.jumps {
                let item = SKNode(); item.name = "pole-\(jump.id)"
                item.position = CGPoint(x: jump.center.x, y: jump.center.y)
                item.zRotation = CGFloat(atan2(jump.normal.y, jump.normal.x) - .pi / 2)
                let color = arena.courseIndex == 2 ? UIColor.systemGreen : colors[jump.id % colors.count]
                let fallen = arena.fallenPoles.contains(jump.id)
                if next?.id == jump.id {
                    let glow = SKShapeNode(ellipseOf: CGSize(width: 158, height: 96))
                    glow.fillColor = .clear; glow.strokeColor = .systemYellow; glow.lineWidth = 5
                    item.addChild(glow)
                    glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.3, duration: 0.6), .fadeAlpha(to: 1, duration: 0.6)])))
                    // Approach arrows point across the pole, rather than along it.
                    for y in [-64.0, 64.0] {
                        let arrow = SKLabelNode(text: y < 0 ? "↑" : "↓")
                        arrow.fontSize = 25; arrow.fontColor = .brown
                        arrow.position = CGPoint(x: 0, y: y - 8); item.addChild(arrow)
                    }
                }
                for side in [-1.0, 1.0] {
                    let upright = SKShapeNode(rectOf: CGSize(width: 12, height: 28), cornerRadius: 3)
                    upright.position.x = CGFloat(side * jump.halfWidth); upright.fillColor = .white
                    upright.strokeColor = color; upright.lineWidth = 3; item.addChild(upright)
                    let flowers = SKShapeNode(circleOfRadius: 9)
                    flowers.position = CGPoint(x: side * (jump.halfWidth + 4), y: -20)
                    flowers.fillColor = .systemPink; flowers.strokeColor = .systemGreen; item.addChild(flowers)
                }
                let rail = SKShapeNode(rectOf: CGSize(width: jump.halfWidth * 2, height: 10), cornerRadius: 3)
                rail.fillColor = color; rail.strokeColor = .white; rail.lineWidth = 2
                rail.name = item.name
                if fallen { rail.position.y = -24; rail.zRotation = 0.18 }
                item.addChild(rail)
                for i in 0..<5 {
                    let stripe = SKShapeNode(rectOf: CGSize(width: 10, height: 9))
                    stripe.position.x = CGFloat(Double(i) * 24 - 48); stripe.fillColor = .white
                    stripe.strokeColor = .clear; rail.addChild(stripe)
                }
                if arena.completedJumps.contains(jump.id) {
                    let tick = SKLabelNode(text: "✓"); tick.fontSize = 24; tick.fontColor = .systemGreen
                    tick.position = CGPoint(x: jump.halfWidth + 22, y: 0); item.addChild(tick)
                }
                obstacles.addChild(item)
            }
        } else if yard.polesEnabled {
            for index in 0..<4 {
                let angle = Double(index) * .pi / 2
                let pole = SKShapeNode(rectOf: CGSize(width: 70, height: 8), cornerRadius: 3)
                pole.position = CGPoint(x: 500 + cos(angle) * 280, y: 310 + sin(angle) * 215)
                pole.zRotation = CGFloat(angle); pole.fillColor = .systemBlue; pole.strokeColor = .white
                pole.lineWidth = 2; obstacles.addChild(pole)
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
