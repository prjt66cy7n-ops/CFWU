import SpriteKit

final class TaskScene: SKScene {
    var onChange: ((ChoreGame, Bool) -> Void)?
    private var entry: ChoreEntry
    private(set) var game: ChoreGame {
        get { entry.current }
        set { entry.current = newValue }
    }
    private var player: Player
    private var horse: HorseNode
    private let world = SKNode()
    private var dragging: String?
    private var dragPosition: CGPoint?
    private var lastDrag: CGPoint?
    private var reportedCompletion = false
    private var previousTime: TimeInterval?
    private var targets: [String: CGRect] = [:]
    private let entryBrokenFence: Bool
    private var animalElapsed = 0.0
    private var nextAnimal = Double.random(in: 10...22)
    private let source = CGPoint(x: 150, y: 95)
    private let bodyPoint = CGPoint(x: 575, y: 325)
    private var tapPoint: CGPoint { CGPoint(x: 180, y: game.activity == .paddockWater ? 355 : 430) }
    private var bucketFillPoint: CGPoint { CGPoint(x: 180, y: tapPoint.y - 95) }
    var foodVariant = 0 { didSet { render() } }
    var guide: String {
        if game.completed { return "✨ ✓ · Tap the activity to play again" }
        switch game.activity {
        case .manure: return "Tap a pile · Drag it to the wheelbarrow"
        case .trough: return game.stage == 0 ? "Brush back and forth over the green water" : "Drag the hose to the clean trough to refill"
        case .stableWater, .paddockWater:
            return game.bucketFull ? "Drag the full bucket to your horse" : (game.bucketAtTap ? "Tap the tap to fill your bucket" : "Drag the bucket under the tap")
        case .brush: return "Brush back and forth over your horse"
        case .wash: return ["Drag the hose to wet the coat", "Scrub with the sponge", "Drag the hose to rinse"][min(2, game.stage)]
        case .hooves: return "Tap a hoof to lift · Tap the pick three times · Do all four"
        case .tack: return "Drag pad, saddle and bridle onto the horse · Tap equipped tack to remove"
        case .eggs: return "Tap a nest · Drag each egg to the basket"
        case .straw: return "Tap each nest to clear straw · Drag fresh straw into it"
        case .fence: return game.brokenFence ? (game.hammerAtFence ? "Tap the hammer at the fence to fix the rail" : "Drag the hammer to the damaged fence rail") : "✓ The fence is sound · Try another activity"
        case .coopWater: return "Drag the hose to the water container · Hold it there"
        case .sweepStable, .sweepCoop: return "Sweep back and forth across the dirty patches"
        case .grain: return "Drag the scoop across the ground"
        case .hay: return "Drag the hay into the feeding spot"
        case .treats: return "Drag a treat onto the ground for the chickens"
        case .feed: return "Drag a treat to your horse's mouth"
        }
    }
    init(player: Player, activity: FarmActivity) {
        self.player = player; horse = HorseNode(player: player, mounted: false)
        let brokenFence = Bool.random(); entryBrokenFence = brokenFence
        entry = ChoreEntry(activity: activity, tack: player.tack, brokenFence: brokenFence)
        super.init(size: CGSize(width: 1000, height: 580))
        scaleMode = .aspectFit
        backgroundColor = UIColor(red: 0.93, green: 0.85, blue: 0.64, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func didMove(to view: SKView) { addChild(world); render(); demonstrate() }
    func choose(_ activity: FarmActivity) {
        entry.select(activity, tack: player.tack)
        reportedCompletion = false; dragging = nil; dragPosition = nil; lastDrag = nil
        render(); demonstrate(); notify()
    }
    func updatePlayer(_ player: Player) {
        let changedAppearance = self.player.selectedHorseID != player.selectedHorseID || self.player.palette != player.palette || self.player.rider != player.rider || self.player.tack != player.tack
        self.player = player
        if changedAppearance { horse = HorseNode(player: player, mounted: false) }
        game.tack = player.tack; render()
    }
    func pause() { dragging = nil; dragPosition = nil; lastDrag = nil; previousTime = nil; isPaused = true; render() }
    func resume() { previousTime = nil; isPaused = false }
    private func sprite(_ name: String, sheet: String, column: Int, row: Int, columns: Int = 4, rows: Int = 4, at point: CGPoint, width: CGFloat) {
        guard let image = GameArt.region(sheet: sheet, column: column, row: row, columns: columns, rows: rows) else { return }
        let node = SKSpriteNode(texture: SKTexture(image: image))
        node.name = name; node.size = CGSize(width: width, height: width * image.size.height / image.size.width)
        node.position = point; world.addChild(node)
    }
    private func symbol(_ text: String, name: String, at point: CGPoint, size: CGFloat = 58) {
        let node = SKLabelNode(text: text); node.fontSize = size
        node.verticalAlignmentMode = .center; node.horizontalAlignmentMode = .center
        node.name = name; node.position = point; world.addChild(node)
    }
    private func zone(_ name: String, at point: CGPoint, width: CGFloat, height: CGFloat, glow: Bool = true) {
        let rect = CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height)
        targets[name] = rect
        let shape = SKShapeNode(rect: rect, cornerRadius: 16); shape.name = name
        shape.fillColor = .clear; shape.strokeColor = glow ? .systemYellow : .clear
        shape.lineWidth = 4; shape.zPosition = -1; world.addChild(shape)
    }
    private func render() {
        world.removeAllChildren(); targets = [:]
        let floor = SKShapeNode(rectOf: CGSize(width: 960, height: 480), cornerRadius: 32)
        floor.position = CGPoint(x: 500, y: 310); floor.fillColor = UIColor(red: 0.96, green: 0.89, blue: 0.72, alpha: 1)
        floor.strokeColor = .brown; floor.lineWidth = 4; floor.zPosition = -3; world.addChild(floor)
        let activity = game.activity
        let coop = [.eggs, .grain, .coopWater, .sweepCoop, .straw, .treats].contains(activity)
        let paddock = [.manure, .trough, .paddockWater, .hay, .fence].contains(activity)
        let washBay = [.brush, .hooves, .wash, .tack].contains(activity)
        if let background = GameArt.background(sheet: "ChoreEnvironmentSheet", column: coop || washBay ? 1 : 0,
                                               row: coop || paddock ? 1 : 0, size: size) {
            world.addChild(background); floor.isHidden = true
        }
        if coop {
            for index in 0..<3 {
                sprite("chicken-\(index)", sheet: "ChickenPoseSheet", column: index == 0 ? 0 : index - 1,
                       row: index == 0 ? 0 : 1, columns: 4, rows: 2,
                       at: CGPoint(x: 550 + index * 130, y: 285), width: 110)
            }
        } else if ![.manure, .trough, .fence].contains(activity) {
            horse.render(point: .zero, facing: .west, gait: .walk, moving: false, time: 0, jumpHeight: 0)
            horse.position = bodyPoint; horse.setScale(CGFloat(2.6 * player.horse.size.scale)); world.addChild(horse)
            let sign = SKLabelNode(text: player.horse.name); sign.fontColor = .brown; sign.fontName = "AvenirNext-DemiBold"
            sign.fontSize = 25; sign.position = CGPoint(x: 580, y: 490); world.addChild(sign)
        }
        switch activity {
        case .feed:
            zone("destination", at: CGPoint(x: 470, y: 325), width: 140, height: 130)
            food(at: source)
        case .stableWater, .paddockWater:
            if activity == .paddockWater {
                let mount = SKShapeNode(rectOf: CGSize(width: 20, height: 44), cornerRadius: 3)
                mount.position = tapPoint; mount.fillColor = UIColor(red: 0.57, green: 0.35, blue: 0.15, alpha: 1)
                mount.strokeColor = .brown; world.addChild(mount)
            }
            symbol("🚰", name: "tap", at: tapPoint)
            zone("tap", at: CGPoint(x: 180, y: tapPoint.y - 65), width: 160, height: 170, glow: !game.bucketFull)
            zone("destination", at: CGPoint(x: 505, y: 260), width: 180, height: 140, glow: game.bucketFull)
            sprite("tool", sheet: "CareTackSheet", column: game.bucketFull ? 1 : 0, row: 1,
                   at: game.completed ? CGPoint(x: 505, y: 260) : (game.bucketAtTap && dragPosition == nil ? bucketFillPoint : source), width: 120)
        case .brush, .wash:
            zone("destination", at: bodyPoint, width: 245, height: 180)
            for index in 0..<6 {
                let dirt = SKShapeNode(ellipseOf: CGSize(width: 23, height: 15))
                dirt.fillColor = activity == .wash && game.stage == 1 ? .white : .brown
                dirt.strokeColor = .clear; dirt.position = CGPoint(x: 540 + (index % 3) * 25, y: 300 + (index / 3) * 45)
                dirt.alpha = CGFloat(1 - game.progress); world.addChild(dirt)
            }
            sprite("tool", sheet: "CareTackSheet", column: activity == .brush ? 0 : (game.stage == 1 ? 2 : 3), row: 0, at: source, width: 120)
        case .hooves:
            for index in 0..<4 {
                let point = hoofPoint(index)
                symbol(game.collection.contains(index) ? "✓" : (game.liftedHoof == index ? "⬆️" : "🧲"), name: "hoof-\(index)", at: point, size: 36)
                zone("hoof-\(index)", at: point, width: 70, height: 70, glow: !game.collection.contains(index))
            }
            sprite("tool", sheet: "CareTackSheet", column: 1, row: 0, at: source, width: 115)
        case .tack:
            zone("destination", at: bodyPoint, width: 265, height: 190)
            for index in 0..<3 {
                let equipped = [game.tack.saddlePad, game.tack.saddle, game.tack.bridle][index]
                let position = equipped ? CGPoint(x: 510 + index * 70, y: 440) : CGPoint(x: 130 + index * 150, y: 115)
                if index == 0 {
                    sprite(equipped ? "equipped-0" : "tack-0", sheet: "TackPaletteSheet", column: player.palette.artColumn, row: 0, columns: 6, rows: 2, at: position, width: 115)
                } else {
                    sprite(equipped ? "equipped-\(index)" : "tack-\(index)", sheet: "CareTackSheet", column: index == 1 ? 0 : 2, row: 3, at: position, width: 115)
                }
            }
        case .manure:
            zone("destination", at: CGPoint(x: 175, y: 320), width: 230, height: 170)
            sprite("destination", sheet: "CareTackSheet", column: 3, row: 1, at: CGPoint(x: 175, y: 320), width: 200)
            // Deposited piles stay in the bowl, above the wheelbarrow artwork.
            for (slot, _) in game.collection.sorted().enumerated() {
                sprite("load-\(slot)", sheet: "CoopPaddockSheet", column: 1, row: 2,
                       at: CGPoint(x: 151 + (slot % 3) * 22, y: 346 + (slot / 3) * 13), width: 48)
                world.childNode(withName: "load-\(slot)")?.zPosition = 1
            }
            for index in 0..<5 where !game.collection.contains(index) {
                let point = pilePoint(index)
                sprite("pile-\(index)", sheet: "CoopPaddockSheet", column: 1, row: 2, at: point, width: 85)
                if game.revealed.contains(index) { zone("pile-\(index)", at: point, width: 90, height: 90) }
            }
        case .trough:
            let point = CGPoint(x: 245, y: 290)
            sprite("destination", sheet: "CoopPaddockSheet", column: 1, row: 3, at: point, width: 220)
            zone("destination", at: point, width: 225, height: 140, glow: !game.completed)
            if !game.completed {
                let water = SKShapeNode(ellipseOf: CGSize(width: 150, height: 48))
                water.position = CGPoint(x: point.x, y: point.y + 24)
                water.strokeColor = .clear
                water.fillColor = game.stage == 0 ? UIColor(red: 0.34, green: 0.48, blue: 0.12, alpha: 1) : .gray
                water.alpha = game.stage == 0 ? CGFloat(1 - game.progress) : 1
                world.addChild(water)
            }
            sprite("tool", sheet: "CareTackSheet", column: game.stage == 0 ? 0 : 3, row: 0, at: source, width: 130)
        case .hay:
            zone("destination", at: CGPoint(x: 455, y: 310), width: 190, height: 170)
            sprite("tool", sheet: "CareTackSheet", column: 2, row: 2, at: source, width: 125)
        case .fence:
            let point = CGPoint(x: 600, y: 351)
            if game.brokenFence {
                // Attach the loose rail to the background's back fence line.
                // It straightens progressively instead of moving fence furniture
                // into the middle of the paddock.
                let rail = SKShapeNode(rectOf: CGSize(width: 76, height: 12), cornerRadius: 2)
                rail.position = point; rail.fillColor = UIColor(red: 0.66, green: 0.4, blue: 0.16, alpha: 1)
                rail.strokeColor = UIColor(red: 0.4, green: 0.24, blue: 0.1, alpha: 1)
                rail.lineWidth = 2; rail.zRotation = game.completed ? 0 : -0.32 * CGFloat(1 - game.progress)
                world.addChild(rail)
                if !game.completed { zone("destination", at: point, width: 110, height: 90) }
                sprite("tool", sheet: "CoopPaddockSheet", column: 3, row: 2,
                       at: game.hammerAtFence ? CGPoint(x: 610, y: 400) : source, width: 110)
            }
        case .eggs, .straw:
            for index in 0..<4 {
                let point = nestPoint(index)
                let nest = SKShapeNode(rectOf: CGSize(width: 100, height: 95), cornerRadius: 12)
                nest.fillColor = .brown.withAlphaComponent(0.55); nest.strokeColor = .brown
                nest.position = point; nest.name = "nest-\(index)"; world.addChild(nest)
                if activity == .eggs, game.revealed.contains(index), !game.collection.contains(index) {
                    sprite("egg-\(index)", sheet: "CoopPaddockSheet", column: 0, row: 0, at: point, width: 50)
                } else {
                    symbol(game.collection.contains(index) ? "✓" : (game.revealed.contains(index) ? "✨" : "🌾"), name: "nest-\(index)", at: point, size: 38)
                }
                zone("nest-\(index)", at: point, width: 110, height: 100)
            }
            if activity == .eggs {
                zone("destination", at: CGPoint(x: 165, y: 270), width: 180, height: 150)
                sprite("destination", sheet: "CoopPaddockSheet", column: 1, row: 0, at: CGPoint(x: 165, y: 270), width: 160)
            } else { sprite("tool", sheet: "CoopPaddockSheet", column: 2, row: 1, at: source, width: 130) }
        case .grain:
            zone("destination", at: CGPoint(x: 605, y: 235), width: 500, height: 220)
            sprite("tool", sheet: "CoopPaddockSheet", column: 2, row: 0, at: source, width: 130)
        case .coopWater:
            zone("destination", at: CGPoint(x: 780, y: 365), width: 150, height: 190)
            sprite("destination", sheet: "CoopPaddockSheet", column: game.completed ? 1 : 0, row: 1, at: CGPoint(x: 780, y: 365), width: 150)
            sprite("tool", sheet: "CareTackSheet", column: 3, row: 0, at: source, width: 135)
        case .sweepStable, .sweepCoop:
            zone("destination", at: CGPoint(x: 555, y: 205), width: 500, height: 150)
            for index in 0..<4 {
                sprite("dirt-\(index)", sheet: "CoopPaddockSheet", column: 2, row: 3, at: CGPoint(x: 390 + index * 115, y: 205), width: 95)
                world.childNode(withName: "dirt-\(index)")?.alpha = CGFloat(1 - game.progress)
            }
            sprite("tool", sheet: "CareTackSheet", column: 2, row: 1, at: source, width: 120)
        case .treats:
            zone("destination", at: CGPoint(x: 605, y: 240), width: 490, height: 220)
            sprite("tool", sheet: "CoopPaddockSheet", column: foodVariant % 2 == 0 ? 0 : 3, row: foodVariant % 2 == 0 ? 2 : 1, at: source, width: 130)
        }
        if let dragging, let position = dragPosition { world.childNode(withName: dragging)?.position = position }
        if !game.completed {
            let arrow = SKLabelNode(text: game.isScrubbing ? "↔" : "→")
            arrow.fontSize = 44; arrow.fontColor = .brown; arrow.position = CGPoint(x: 265, y: 100); world.addChild(arrow)
            arrow.run(.repeatForever(.sequence([.moveBy(x: 15, y: 0, duration: 0.5), .moveBy(x: -15, y: 0, duration: 0.5)])))
        } else {
            symbol("✨ ✓ ✨", name: "done", at: CGPoint(x: 500, y: 520), size: 42)
        }
    }
    private func food(at point: CGPoint) {
        switch foodVariant % 4 {
        case 0: sprite("tool", sheet: "CareTackSheet", column: 0, row: 2, at: point, width: 120)
        case 1: sprite("tool", sheet: "CareTackSheet", column: 1, row: 2, at: point, width: 100)
        case 2: symbol("🍬", name: "tool", at: point)
        default: sprite("tool", sheet: "CareTackSheet", column: 2, row: 2, at: point, width: 120)
        }
    }
    private func hoofPoint(_ index: Int) -> CGPoint {
        let width = CGFloat(96 * 2.6 * player.horse.size.scale)
        let image = GameArt.silhouette(sheet: "HorseBodySheet", index: player.horse.portraitIndex)
        let ratio = image.map { $0.size.height / $0.size.width } ?? 0.9
        // Care artwork is side-on: all four hoof handles follow its ground line,
        // rather than the former overhead figure's four corners.
        let offsets: [CGFloat] = [-0.30, -0.10, 0.17, 0.34]
        return CGPoint(x: bodyPoint.x + offsets[index] * width, y: bodyPoint.y - width * ratio / 2 + 10)
    }
    private func pilePoint(_ index: Int) -> CGPoint {
        let points = [CGPoint(x: 380, y: 430), CGPoint(x: 570, y: 445), CGPoint(x: 760, y: 430), CGPoint(x: 465, y: 260), CGPoint(x: 685, y: 255)]
        return points[index]
    }
    private func nestPoint(_ index: Int) -> CGPoint { CGPoint(x: 365 + index * 150, y: 425) }
    private func notify() {
        let justCompleted = game.completed && !reportedCompletion
        if justCompleted {
            reportedCompletion = true
            GameAudio.effect("task", enabled: player.sfxEnabled)
            if [.feed, .stableWater, .paddockWater, .hay].contains(game.activity) {
                if game.activity == .hay { horse.run(.move(to: CGPoint(x: 495, y: 325), duration: 0.7)) }
                horse.eat()
                horse.run(.sequence([.rotate(byAngle: 0.06, duration: 0.25), .rotate(byAngle: -0.06, duration: 0.25)]))
                symbol("😋", name: "eating", at: CGPoint(x: 460, y: 380), size: 34)
            }
            if [.grain, .treats].contains(game.activity) {
                for index in 0..<3 {
                    world.childNode(withName: "chicken-\(index)")?.run(.sequence([.move(to: CGPoint(x: 480 + index * 70, y: 235), duration: 0.6), .repeat(.sequence([.rotate(byAngle: 0.12, duration: 0.15), .rotate(byAngle: -0.12, duration: 0.15)]), count: 3)]))
                }
            }
        }
        onChange?(game, justCompleted)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if game.activity == .hooves && !game.completed,
           let closest = (0..<4).min(by: {
               hypot(point.x - hoofPoint($0).x, point.y - hoofPoint($0).y) < hypot(point.x - hoofPoint($1).x, point.y - hoofPoint($1).y)
           }), hypot(point.x - hoofPoint(closest).x, point.y - hoofPoint(closest).y) < 43 {
            game.liftHoof(closest); render(); notify(); return
        }
        let hit = world.nodes(at: point).first { $0.name != nil }
        guard let name = hit?.name else { return }
        if name.hasPrefix("chicken-") {
            hit?.run(.sequence([.moveBy(x: 0, y: 18, duration: 0.12), .moveBy(x: 0, y: -18, duration: 0.15)]))
            GameAudio.effect("chicken", enabled: player.sfxEnabled); return
        }
        if name.hasPrefix("equipped-"), let index = Int(name.dropFirst(9)) {
            game.removeTack(index); reportedCompletion = false; render(); notify(); return
        }
        if game.completed && name == "tool" && [.feed, .hay, .treats].contains(game.activity) {
            game = ChoreGame(activity: game.activity, tack: player.tack, brokenFence: entryBrokenFence)
            reportedCompletion = false; render()
        }
        guard !game.completed else { return }
        if name.hasPrefix("hoof-"), let index = Int(name.dropFirst(5)) {
            game.liftHoof(index); render(); notify(); return
        }
        if name.hasPrefix("nest-"), let index = Int(name.dropFirst(5)) {
            game.tapTarget(index); render(); notify(); return
        }
        if name == "tool" && game.activity == .hooves {
            game.pickLiftedHoof(); game.progress = Double(game.hoofPicks.reduce(0, +)) / 12
            GameAudio.effect("pick", enabled: player.sfxEnabled); render(); notify(); return
        }
        if name == "tap" { game.tapTarget(); GameAudio.effect("water", enabled: player.sfxEnabled); render(); notify(); return }
        if name == "tool" && game.activity == .fence && game.hammerAtFence {
            game.tapTarget(); GameAudio.effect(game.activity == .fence ? "pick" : "water", enabled: player.sfxEnabled)
            render(); notify()
            if game.activity == .fence {
                world.childNode(withName: "tool")?.run(.sequence([
                    .rotate(byAngle: -0.5, duration: 0.1), .rotate(byAngle: 0.5, duration: 0.15)
                ]))
            }
            return
        }
        if name.hasPrefix("pile-"), let index = Int(name.dropFirst(5)) { game.tapTarget(index); render() }
        if name == "tool" || name.hasPrefix("pile-") || name.hasPrefix("egg-") || name.hasPrefix("tack-") {
            dragging = name; dragPosition = point; lastDrag = point
            world.childNode(withName: name)?.zPosition = 2000
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self), let dragging else { return }
        dragPosition = point
        world.childNode(withName: dragging)?.position = point
        if dragging == "tool", game.isScrubbing, let previous = lastDrag,
           targets["destination"]?.contains(point) == true, targets["destination"]?.contains(previous) == true {
            let oldStage = game.stage
            game.scrub(distance: Double(hypot(point.x - previous.x, point.y - previous.y)))
            if oldStage != game.stage { self.dragging = nil; dragPosition = nil; lastDrag = nil }
            render()
            if oldStage != game.stage { demonstrate() }
            notify()
        }
        lastDrag = self.dragging == nil ? nil : point
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self), let name = dragging else { return }
        if targets["tap"]?.contains(point) == true && name == "tool" { game.dropAtTap() }
        if name.hasPrefix("tack-"), let index = Int(name.dropFirst(5)), targets["destination"]?.contains(point) == true { game.equip(index) }
        if game.activity == .straw && name == "tool" {
            for index in 0..<4 where targets["nest-\(index)"]?.contains(point) == true { game.dropAtDestination(item: index) }
        } else if targets["destination"]?.contains(point) == true {
            if name.hasPrefix("pile-"), let index = Int(name.dropFirst(5)) { game.dropAtDestination(item: index) }
            else if name.hasPrefix("egg-"), let index = Int(name.dropFirst(4)) { game.dropAtDestination(item: index) }
            else if name == "tool" { game.dropAtDestination() }
        }
        dragging = nil; dragPosition = nil; lastDrag = nil
        render(); notify()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragging = nil; dragPosition = nil; lastDrag = nil; render()
    }
    private func demonstrate() {
        let hand = SKLabelNode(text: "👆"); hand.fontSize = 40; hand.zPosition = 3000; hand.position = source
        let destination: CGPoint
        if game.activity == .manure { hand.position = pilePoint(0); destination = CGPoint(x: 175, y: 320) }
        else if [.eggs, .straw].contains(game.activity) { hand.position = nestPoint(0); destination = game.activity == .eggs ? CGPoint(x: 165, y: 270) : source }
        else if game.activity == .hooves { destination = hoofPoint(0) }
        else if [.stableWater, .paddockWater].contains(game.activity) { destination = bucketFillPoint }
        else { destination = targets["destination"].map { CGPoint(x: $0.midX, y: $0.midY) } ?? bodyPoint }
        world.addChild(hand)
        var actions: [SKAction] = [.move(to: destination, duration: 0.8)]
        if game.isScrubbing { actions += [.moveBy(x: 60, y: 0, duration: 0.3), .moveBy(x: -120, y: 0, duration: 0.5), .moveBy(x: 60, y: 0, duration: 0.3)] }
        actions += [.wait(forDuration: 0.3), .fadeOut(withDuration: 0.25), .removeFromParent()]
        hand.run(.sequence(actions))
    }
    override func update(_ currentTime: TimeInterval) {
        defer { previousTime = currentTime }
        guard let previous = previousTime else { return }
        let dt = min(0.1, max(0, currentTime - previous))
        animalElapsed += dt
        if animalElapsed >= nextAnimal {
            animalElapsed = 0; nextAnimal = Double.random(in: 12...26)
            if [.eggs, .grain, .coopWater, .sweepCoop, .straw, .treats].contains(game.activity) {
                GameAudio.effect("chicken", enabled: player.sfxEnabled)
            } else if ![.manure, .trough, .fence].contains(game.activity) {
                let sound = Int.random(in: 0..<12) == 0 ? "horse-fart" : "horse-\(Int.random(in: 1...3))"
                GameAudio.effect(sound, enabled: player.sfxEnabled); horse.flickTail()
            }
        }
        guard game.activity == .coopWater, dragging == "tool", !game.completed,
              let point = dragPosition, targets["destination"]?.contains(point) == true else { return }
        game.holdWater(seconds: dt); render(); notify()
    }
}
