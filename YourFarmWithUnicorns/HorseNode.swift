import SpriteKit
import UIKit

// Painted body sections sit over articulated legs, with rider/tack and wings
// rendered independently. Rotation provides eight overhead facings.
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
    private var wings: [SKNode] = []
    private var tailNode: SKShapeNode?
    private var headNode: SKShapeNode?
    private var carePortrait: SKNode?
    private var careLegs: [SKSpriteNode] = []
    private var liftedCareLeg: Int?
    private var paintedHead: SKSpriteNode?
    private var paintedTail: SKSpriteNode?
    private var angledPlayer: Player?
    private var angledFacing: RideFacing?
    private var lunging = false
    func setLunging(_ enabled: Bool) { lunging = enabled; angledFacing = nil }
    var bridleAttachment: CGPoint {
        let direction = angledFacing?.vector ?? RidePoint(x: 1, y: 0)
        return CGPoint(x: direction.x * 25, y: 51 + direction.y * 12)
    }
    private let angledFigure = SKNode()
    private var angledLegs: [SKSpriteNode] = []
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
            hair.name = "rider-hair"; hair.zPosition = 0.6
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
        if mounted { paintOverhead(player: player, unicorn: unicorn) }
        if unicorn { paintWings() }
        if !mounted && !unicorn,
           let image = GameArt.silhouette(sheet: "HorseBodySheet", index: player.horse.portraitIndex) {
            let painted = SKNode(); painted.zPosition = 1
            if let full = image.cgImage {
                let height = 96 * image.size.height / image.size.width
                if let upper = full.cropping(to: CGRect(x: 0, y: 0, width: CGFloat(full.width), height: CGFloat(full.height) * 0.67)) {
                    let body = SKSpriteNode(texture: SKTexture(cgImage: upper))
                    body.size = CGSize(width: 96, height: height * 0.67)
                    body.position.y = height * 0.165; painted.addChild(body)
                }
                let cuts: [CGFloat] = [0, 0.34, 0.6, 0.82, 1]
                for index in 0..<4 {
                    let x = cuts[index] * CGFloat(full.width), span = (cuts[index + 1] - cuts[index]) * CGFloat(full.width)
                    guard let slice = full.cropping(to: CGRect(x: x, y: CGFloat(full.height) * 0.66,
                                                              width: span, height: CGFloat(full.height) * 0.34)) else { continue }
                    let leg = SKSpriteNode(texture: SKTexture(cgImage: slice))
                    leg.size = CGSize(width: 96 * (cuts[index + 1] - cuts[index]), height: height * 0.34)
                    leg.anchorPoint = CGPoint(x: 0.5, y: 1)
                    leg.position = CGPoint(x: 96 * ((cuts[index] + cuts[index + 1]) / 2 - 0.5), y: -height * 0.16)
                    painted.addChild(leg); careLegs.append(leg)
                }
            }
            figure.isHidden = true; addChild(painted); carePortrait = painted
            // Care portraits face left; keep saved tack visible on their actual body.
            let items: [(Bool, UIImage?, CGPoint, CGSize)] = [
                (player.tack.saddlePad, GameArt.pad(player.palette), CGPoint(x: 4, y: 16), CGSize(width: 34, height: 28)),
                (player.tack.saddle, GameArt.region(sheet: "CareTackSheet", column: 0, row: 3, columns: 4, rows: 4),
                 CGPoint(x: 4, y: 19), CGSize(width: 28, height: 27)),
                (player.tack.bridle, GameArt.region(sheet: "CareTackSheet", column: 2, row: 3, columns: 4, rows: 4),
                 CGPoint(x: -33, y: 18), CGSize(width: 20, height: 27))
            ]
            for (visible, image, location, size) in items where visible {
                guard let image else { continue }
                let tack = SKSpriteNode(texture: SKTexture(image: image)); tack.size = size
                tack.position = location; tack.zPosition = 2; addChild(tack)
            }
        }
        setScale(ponyScale)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    private func paintOverhead(player: Player, unicorn: Bool) {
        let sheet = unicorn ? "UnicornOverheadSheet" : "HorseOverheadSheet"
        guard let image = GameArt.silhouette(sheet: sheet, index: player.horse.portraitIndex), let full = image.cgImage else { return }
        let preserved: [SKNode] = legs.map { $0 as SKNode } + [pad, saddle, bridle, riderBody, riderHead] + wings
        for node in figure.children {
            if node.name != "rider-hair" && !preserved.contains(where: { $0 === node }) { node.isHidden = true }
        }
        // Overlapping image sections avoid seams while head and tail articulate.
        let segments: [(Double, Double, CGFloat)] = [(0, 0.4, 1), (0.38, 0.8, 0), (0.76, 1, 2)]
        let drawnHeight: CGFloat = 91
        for (start, end, part) in segments {
            let rect = CGRect(x: 0, y: CGFloat(start) * CGFloat(full.height), width: CGFloat(full.width), height: CGFloat(end - start) * CGFloat(full.height))
            guard let cropped = full.cropping(to: rect) else { continue }
            let sprite = SKSpriteNode(texture: SKTexture(cgImage: cropped))
            sprite.size = CGSize(width: drawnHeight * image.size.width / image.size.height, height: drawnHeight * CGFloat(end - start))
            sprite.position.y = drawnHeight * CGFloat(0.5 - (start + end) / 2)
            sprite.zPosition = 0.1
            if unicorn { sprite.shader = maneShader(palette: player.palette) }
            figure.addChild(sprite)
            if part == 1 { paintedHead = sprite }
            if part == 2 { paintedTail = sprite }
        }
        for node in [pad, saddle, bridle, riderBody, riderHead] { node.zPosition = 0.5 }
    }
    private func maneShader(palette: Palette) -> SKShader {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        palette.uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // Only purple hair changes colour; white coat, markings and horn stay intact.
        return SKShader(source: """
        void main() {
            vec4 pixel = texture2D(u_texture, v_tex_coord);
            vec3 rgb = pixel.rgb / max(pixel.a, 0.001);
            if (rgb.b > rgb.g * 1.25 && rgb.r > rgb.g * 1.2 && rgb.b > rgb.r * 0.8) {
                float light = max(rgb.r, rgb.b);
                vec3 hair = mix(u_hair.rgb * 0.3, min(vec3(1.0), u_hair.rgb + vec3(0.28)), light);
                pixel.rgb = hair * pixel.a;
            }
            gl_FragColor = pixel;
        }
        """, uniforms: [SKUniform(name: "u_hair", vectorFloat3: SIMD3(Float(red), Float(green), Float(blue)))])
    }
    private func paintWings() {
        guard let image = GameArt.silhouette(sheet: "UnicornWing", index: 0, columns: 1, rows: 1) else { return }
        for wing in wings { wing.removeFromParent() }
        wings = []
        for side: CGFloat in [-1, 1] {
            let wing = SKSpriteNode(texture: SKTexture(image: image))
            wing.size = CGSize(width: 74, height: 74 * image.size.height / image.size.width)
            wing.anchorPoint = CGPoint(x: 0.03, y: 0.68); wing.position = CGPoint(x: side * 8, y: 6)
            wing.xScale = side; wing.zPosition = -0.1; figure.addChild(wing); wings.append(wing)
        }
    }
    func liftCareLeg(_ index: Int?) {
        guard liftedCareLeg != index else { return }
        liftedCareLeg = index
        for (legIndex, leg) in careLegs.enumerated() {
            leg.run(.rotate(toAngle: legIndex == index ? (legIndex < 2 ? 0.85 : -0.85) : 0, duration: 0.22), withKey: "hoof-lift")
        }
    }
    func eat() {
        headNode?.run(.repeat(.sequence([.moveBy(x: 0, y: -3, duration: 0.2), .moveBy(x: 0, y: 3, duration: 0.2)]), count: 4))
        carePortrait?.run(.repeat(.sequence([.rotate(toAngle: 0.035, duration: 0.25), .rotate(toAngle: 0, duration: 0.25)]), count: 4))
        paintedHead?.run(.repeat(.sequence([.rotate(toAngle: 0.08, duration: 0.2), .rotate(toAngle: 0, duration: 0.2)]), count: 4))
    }
    func flickTail() {
        tailNode?.run(.sequence([.rotate(toAngle: 0.5, duration: 0.15), .rotate(toAngle: -0.3, duration: 0.15), .rotate(toAngle: 0, duration: 0.2)]))
        paintedTail?.run(.sequence([.rotate(toAngle: 0.25, duration: 0.15), .rotate(toAngle: -0.2, duration: 0.15), .rotate(toAngle: 0, duration: 0.2)]))
    }
    func flightMotion(time: Double) {
        let gliding = Int(time) % 9 >= 6
        let stretch = gliding ? 0.78 : 0.65 + 0.3 * sin(time * 3.5)
        for (index, wing) in wings.enumerated() {
            wing.yScale = CGFloat(stretch)
            wing.xScale = CGFloat(index == 0 ? -1 : 1) * CGFloat(gliding ? 1 : 0.72 + 0.28 * sin(time * 3.5))
        }
    }
    func enableAngledRiding(player: Player) {
        angledPlayer = player; figure.isHidden = true; addChild(angledFigure)
    }
    private func renderAngled(player: Player, point: RidePoint, facing: RideFacing, gait: RideGait,
                              moving: Bool, time: Double, jumpHeight: Double) {
        position = CGPoint(x: point.x, y: point.y)
        if angledFacing != facing {
            angledFacing = facing; angledFigure.removeAllChildren(); angledLegs = []
            if let image = GameArt.silhouette(sheet: "HorseRide-\(player.horse.id)", index: facing.rawValue, columns: 4, rows: 2),
               let full = image.cgImage {
                let height: CGFloat = 76, width = height * image.size.width / image.size.height
                if let upper = full.cropping(to: CGRect(x: 0, y: 0, width: CGFloat(full.width), height: CGFloat(full.height) * 0.68)) {
                    let body = SKSpriteNode(texture: SKTexture(cgImage: upper))
                    body.size = CGSize(width: width, height: height * 0.68)
                    body.position.y = height * 0.66; angledFigure.addChild(body)
                }
                for index in 0..<4 {
                    let span = CGFloat(full.width) / 4
                    guard let lower = full.cropping(to: CGRect(x: CGFloat(index) * span, y: CGFloat(full.height) * 0.67,
                                                               width: span, height: CGFloat(full.height) * 0.33)) else { continue }
                    let leg = SKSpriteNode(texture: SKTexture(cgImage: lower))
                    leg.size = CGSize(width: width / 4, height: height * 0.33)
                    leg.anchorPoint = CGPoint(x: 0.5, y: 1)
                    leg.position = CGPoint(x: width * (CGFloat(index) / 4 - 0.375), y: height * 0.33)
                    angledFigure.addChild(leg); angledLegs.append(leg)
                }
                for node in [pad, saddle, riderBody, riderHead] {
                    node.removeFromParent(); node.position.x = 0; angledFigure.addChild(node)
                }
                pad.position.y = 39; saddle.position.y = 42; riderBody.position.y = 49; riderHead.position.y = 63
                riderBody.zPosition = 2; riderHead.zPosition = 3
                for node in [pad, saddle, riderBody, riderHead] { node.isHidden = lunging || (node === pad && !player.tack.saddlePad) || (node === saddle && !player.tack.saddle) }
                if lunging {
                    let halter = SKShapeNode(ellipseOf: CGSize(width: 13, height: 8))
                    halter.position = bridleAttachment; halter.strokeColor = player.palette.uiColor
                    halter.lineWidth = 2; halter.fillColor = .clear; angledFigure.addChild(halter)
                }
                if player.rider == .girl && !lunging {
                    let hair = SKShapeNode(ellipseOf: CGSize(width: 5, height: 14))
                    hair.position = CGPoint(x: 8, y: 54); hair.fillColor = .brown; hair.strokeColor = .clear
                    hair.zPosition = 2; angledFigure.addChild(hair)
                }
            }
        }
        let cadence = gait == .walk ? 5.0 : (gait == .trot ? 9.0 : 12.0)
        for (index, leg) in angledLegs.enumerated() {
            let phase = time * cadence + Double(index) * .pi / 2
            leg.zRotation = jumpHeight > 1 ? (index < 2 ? 0.35 : -0.35) : (moving ? CGFloat(sin(phase) * 0.12) : 0)
            leg.yScale = jumpHeight > 1 ? 0.7 : 1
        }
        angledFigure.position.y = CGFloat(jumpHeight) + (moving ? CGFloat(abs(sin(time * cadence)) * 1.5) : 0)
        shadow.setScale(jumpHeight > 1 ? 0.8 : 1); zPosition = CGFloat(700 - point.y)
    }
    func render(point: RidePoint, facing: RideFacing, gait: RideGait, moving: Bool, time: Double, jumpHeight: Double) {
        if let player = angledPlayer {
            renderAngled(player: player, point: point, facing: facing, gait: gait, moving: moving, time: time, jumpHeight: jumpHeight)
            return
        }
        position = CGPoint(x: point.x, y: point.y)
        let target = Double(facing.rawValue) * .pi / 4 - .pi / 2
        if firstDirection { lastDirection = target; firstDirection = false }
        let delta = atan2(sin(target - lastDirection), cos(target - lastDirection))
        lastDirection += delta * 0.22
        figure.zRotation = CGFloat(lastDirection)
        let cadence = gait == .walk ? 5.0 : (gait == .trot ? 9.0 : 12.0)
        let cycle = time * cadence
        let offsets: [Double] = gait == .walk ? [0, .pi, .pi * 1.5, .pi * 0.5] :
            (gait == .trot ? [0, .pi, .pi, 0] : [0, 0.8, .pi, .pi + 0.8])
        for (index, leg) in legs.enumerated() {
            let direction = (index == 0 || index == 3) ? 1.0 : -1.0
            let stride = moving ? sin(cycle + offsets[index]) * (gait == .walk ? 4 : 7) : 0
            leg.position.y = CGFloat(index < 2 ? 15 : -19) + CGFloat(stride)
            leg.zRotation = jumpHeight > 1 ? CGFloat(direction * 0.5) : CGFloat(stride * 0.03)
        }
        figure.position.y = CGFloat(jumpHeight) + (moving && jumpHeight == 0 ? CGFloat(abs(sin(cycle * 2))) * 1.5 : 0)
        if moving { tailNode?.zRotation = CGFloat(sin(cycle * 0.5) * 0.12) }
        if moving {
            paintedTail?.zRotation = CGFloat(sin(cycle * 0.5) * 0.1)
            paintedHead?.zRotation = CGFloat(sin(cycle) * 0.025)
        }
        shadow.setScale(jumpHeight > 1 ? 0.8 : 1)
        zPosition = CGFloat(700 - point.y)
    }
}
