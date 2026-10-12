import SpriteKit
import UIKit

// Temporary procedural eight-facing animation. Inventory portraits are painted
// artwork; mounted gait/jump sprite exports are still needed for final fidelity.
final class HorseNode: SKNode {
    private let figure = SKNode()
    private let shadow = SKShapeNode(ellipseOf: CGSize(width: 48, height: 24))
    private var legs: [SKShapeNode] = []
    private let pad = SKShapeNode(ellipseOf: CGSize(width: 31, height: 24))
    private let saddle = SKShapeNode(rectOf: CGSize(width: 23, height: 15), cornerRadius: 4)
    private let bridle = SKShapeNode(rectOf: CGSize(width: 19, height: 4), cornerRadius: 2)
    private let riderBody = SKShapeNode(ellipseOf: CGSize(width: 17, height: 21))
    private let riderHead = SKShapeNode(circleOfRadius: 8)
    private let ponyScale: CGFloat
    private var lastDirection = 0.0
    private var firstDirection = true
    private var wings: [SKShapeNode] = []
    private var tailNode: SKShapeNode?
    private var headNode: SKShapeNode?
    init(player: Player, mounted: Bool = true, unicorn: Bool = false) {
        ponyScale = CGFloat(player.horse.size.scale)
        super.init()
        shadow.fillColor = .black.withAlphaComponent(0.13); shadow.strokeColor = .clear
        shadow.zPosition = -1; addChild(shadow); addChild(figure)
        let coat: UIColor
        switch player.horse.coat {
        case .bay, .paint: coat = UIColor(red: 0.58, green: 0.29, blue: 0.11, alpha: 1)
        case .palomino, .fawn: coat = UIColor(red: 0.86, green: 0.63, blue: 0.32, alpha: 1)
        case .dun: coat = UIColor(red: 0.68, green: 0.52, blue: 0.31, alpha: 1)
        case .dapple: coat = .lightGray
        case .chestnut: coat = UIColor(red: 0.72, green: 0.34, blue: 0.14, alpha: 1)
        case .black, .piebald: coat = UIColor(white: 0.18, alpha: 1)
        case .white, .appaloosa: coat = UIColor(white: 0.94, alpha: 1)
        }
        let legPositions = [CGPoint(x: -13, y: 15), CGPoint(x: 13, y: 15), CGPoint(x: -13, y: -19), CGPoint(x: 13, y: -19)]
        for (index, location) in legPositions.enumerated() {
            let leg = SKShapeNode(rectOf: CGSize(width: 8, height: 22), cornerRadius: 4)
            leg.position = location; leg.fillColor = .darkGray; leg.strokeColor = .clear
            if player.horse.id == "roo" && index == 2 { leg.fillColor = .white }
            if player.horse.size == .draft { leg.fillColor = .white }
            if unicorn { leg.fillColor = player.horse.id == "roo" && index == 2 ? UIColor.systemBrown.withAlphaComponent(0.45) : .white }
            legs.append(leg); figure.addChild(leg)
        }
        let tail = SKShapeNode(rectOf: CGSize(width: 10, height: 28), cornerRadius: 5)
        tail.position.y = -34; tail.fillColor = unicorn ? player.palette.uiColor : .darkGray; tail.strokeColor = .clear; figure.addChild(tail); tailNode = tail
        let body = SKShapeNode(ellipseOf: CGSize(width: 31, height: 54))
        body.fillColor = unicorn ? .white : coat; body.strokeColor = coat.withAlphaComponent(0.8); figure.addChild(body)
        if [.paint, .piebald].contains(player.horse.coat) {
            let patch = SKShapeNode(ellipseOf: CGSize(width: 17, height: 25)); patch.fillColor = unicorn ? .lightGray : .white
            patch.strokeColor = .clear; patch.position = CGPoint(x: 4, y: -8); figure.addChild(patch)
        }
        if [.dapple, .appaloosa].contains(player.horse.coat) {
            for i in 0..<6 {
                let spot = SKShapeNode(circleOfRadius: 3); spot.fillColor = player.horse.coat == .dapple ? .gray : .brown
                spot.strokeColor = .clear; spot.position = CGPoint(x: i % 2 == 0 ? -7 : 7, y: CGFloat(i * 6 - 16))
                figure.addChild(spot)
            }
        }
        let head = SKShapeNode(ellipseOf: CGSize(width: 21, height: 30))
        head.position.y = 34; head.fillColor = unicorn ? .white : coat; head.strokeColor = .brown; figure.addChild(head); headNode = head
        for x in [-8.0, 8.0] {
            let ear = SKShapeNode(ellipseOf: CGSize(width: 6, height: 12)); ear.position = CGPoint(x: x, y: 49)
            ear.fillColor = unicorn ? .white : coat; ear.strokeColor = .brown; figure.addChild(ear)
        }
        let mane = SKShapeNode(rectOf: CGSize(width: 7, height: 35), cornerRadius: 3)
        mane.position = CGPoint(x: -7, y: 23)
        mane.fillColor = unicorn ? player.palette.uiColor : ([.palomino, .white, .chestnut, .fawn].contains(player.horse.coat) ? .systemYellow : .darkGray)
        mane.strokeColor = .clear; figure.addChild(mane)
        if player.horse.id == "roo" {
            let path = CGMutablePath(); path.move(to: CGPoint(x: 0, y: 4)); path.addLine(to: CGPoint(x: 3, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -4)); path.addLine(to: CGPoint(x: -3, y: 0)); path.closeSubpath()
            let marking = SKShapeNode(path: path); marking.position.y = 39
            marking.fillColor = unicorn ? .brown : .white; marking.strokeColor = .clear; figure.addChild(marking)
        }
        pad.fillColor = player.palette.uiColor; pad.strokeColor = player.palette == .blackGold ? .systemYellow : .white
        pad.isHidden = unicorn || !player.tack.saddlePad; figure.addChild(pad)
        saddle.fillColor = .brown; saddle.strokeColor = .darkGray; saddle.isHidden = unicorn || !player.tack.saddle
        figure.addChild(saddle)
        bridle.position.y = 39; bridle.fillColor = player.palette.uiColor; bridle.strokeColor = .clear
        bridle.isHidden = unicorn || !player.tack.bridle; figure.addChild(bridle)
        riderBody.fillColor = player.palette.uiColor; riderBody.strokeColor = .white
        riderBody.position.y = 4; figure.addChild(riderBody)
        riderHead.position.y = 11; riderHead.fillColor = player.palette.uiColor; riderHead.strokeColor = .darkGray
        figure.addChild(riderHead)
        if mounted && player.rider == .girl {
            let hair = SKShapeNode(ellipseOf: CGSize(width: 5, height: 15)); hair.fillColor = .brown
            hair.strokeColor = .clear; hair.position = CGPoint(x: 8, y: 4); figure.addChild(hair)
        }
        riderBody.isHidden = !mounted; riderHead.isHidden = !mounted
        if unicorn {
            let hornPath = CGMutablePath(); hornPath.move(to: CGPoint(x: -3, y: 46))
            hornPath.addLine(to: CGPoint(x: 0, y: 69)); hornPath.addLine(to: CGPoint(x: 5, y: 46)); hornPath.closeSubpath()
            let horn = SKShapeNode(path: hornPath); horn.fillColor = .systemYellow; horn.strokeColor = .brown; figure.addChild(horn)
            for side in [-1.0, 1.0] {
                let path = CGMutablePath(); path.move(to: CGPoint(x: side * 10, y: 5))
                path.addQuadCurve(to: CGPoint(x: side * 70, y: 25), control: CGPoint(x: side * 48, y: 48))
                path.addLine(to: CGPoint(x: side * 63, y: 10)); path.addLine(to: CGPoint(x: side * 55, y: 12))
                path.addLine(to: CGPoint(x: side * 45, y: -8)); path.addLine(to: CGPoint(x: side * 35, y: 1))
                path.addQuadCurve(to: CGPoint(x: side * 10, y: 5), control: CGPoint(x: side * 20, y: -10)); path.closeSubpath()
                let wing = SKShapeNode(path: path); wing.fillColor = .white; wing.strokeColor = .lightGray; wing.lineWidth = 1.5
                wing.zPosition = -0.1; figure.addChild(wing); wings.append(wing)
            }
        }
        setScale(ponyScale)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    func eat() {
        headNode?.run(.repeat(.sequence([.moveBy(x: 0, y: -3, duration: 0.2), .moveBy(x: 0, y: 3, duration: 0.2)]), count: 4))
    }
    func flickTail() {
        tailNode?.run(.sequence([.rotate(toAngle: 0.5, duration: 0.15), .rotate(toAngle: -0.3, duration: 0.15), .rotate(toAngle: 0, duration: 0.2)]))
    }
    func flightMotion(time: Double) {
        let gliding = Int(time) % 9 >= 6
        let stretch = gliding ? 0.78 : 0.65 + 0.3 * sin(time * 3.5)
        for wing in wings { wing.yScale = CGFloat(stretch) }
    }
    func render(point: RidePoint, facing: RideFacing, gait: RideGait, moving: Bool, time: Double, jumpHeight: Double) {
        position = CGPoint(x: point.x, y: point.y)
        let target = Double(facing.rawValue) * .pi / 4 - .pi / 2
        if firstDirection { lastDirection = target; firstDirection = false }
        let delta = atan2(sin(target - lastDirection), cos(target - lastDirection))
        lastDirection += delta * 0.22
        figure.zRotation = CGFloat(lastDirection)
        let cadence = gait == .walk ? 5.0 : (gait == .trot ? 9.0 : 12.0)
        let phase = moving ? Int(time * cadence) % 4 : 0
        for (index, leg) in legs.enumerated() {
            let direction = (index == 0 || index == 3) ? 1.0 : -1.0
            let stride = moving ? sin(Double(phase) * .pi / 2) * direction * 6 : 0
            leg.position.y = CGFloat(index < 2 ? 15 : -19) + CGFloat(stride)
            leg.zRotation = jumpHeight > 1 ? CGFloat(direction * 0.5) : CGFloat(stride * 0.03)
        }
        figure.position.y = CGFloat(jumpHeight) + (moving && jumpHeight == 0 ? CGFloat(phase % 2) * 1.5 : 0)
        shadow.setScale(jumpHeight > 1 ? 0.8 : 1)
        zPosition = CGFloat(700 - point.y)
    }
}
