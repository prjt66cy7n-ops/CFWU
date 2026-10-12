import SpriteKit
import SwiftUI

enum FarmLandscape {
    static let locations: [(FarmArea, CGPoint)] = [
        (.stables, CGPoint(x: 235, y: 425)), (.washBay, CGPoint(x: 375, y: 400)),
        (.arena, CGPoint(x: 655, y: 365)), (.roundYard, CGPoint(x: 835, y: 175)),
        (.paddock, CGPoint(x: 230, y: 170)), (.chickenCoop, CGPoint(x: 105, y: 300)),
        (.farmhouse, CGPoint(x: 535, y: 160))
    ]
    // Shared draft layout keeps flight above the same farm as the map.
    // Approved scene exports replace these shapes during final art integration.
    static func make(playerName: String) -> SKNode {
        let root = SKNode()
        if let background = GameArt.background(sheet: "FarmEnvironmentSheet", column: 1, row: 1,
                                               size: CGSize(width: 1000, height: 620)) {
            root.addChild(background)
            let paintedLocations: [(FarmArea, CGPoint)] = [
                (.stables, CGPoint(x: 270, y: 495)), (.washBay, CGPoint(x: 435, y: 480)),
                (.arena, CGPoint(x: 665, y: 365)), (.roundYard, CGPoint(x: 855, y: 165)),
                (.paddock, CGPoint(x: 235, y: 210)), (.chickenCoop, CGPoint(x: 140, y: 345)),
                (.farmhouse, CGPoint(x: 550, y: 130))
            ]
            for (area, point) in paintedLocations {
                let button = SKShapeNode(rectOf: CGSize(width: area == .washBay ? 120 : 150, height: 48), cornerRadius: 18)
                button.name = "area-\(area.rawValue)"; button.position = point
                button.fillColor = UIColor(red: 1, green: 0.94, blue: 0.8, alpha: 0.94)
                button.strokeColor = .brown; button.lineWidth = 2
                let label = SKLabelNode(text: "\(area.icon) \(area.title)")
                label.fontName = "AvenirNext-DemiBold"; label.fontSize = area == .washBay ? 15 : 17
                label.fontColor = .brown; label.verticalAlignmentMode = .center; button.addChild(label)
                root.addChild(button)
            }
            let sign = SKShapeNode(rectOf: CGSize(width: 350, height: 48), cornerRadius: 16)
            sign.position = CGPoint(x: 440, y: 582); sign.fillColor = UIColor(red: 1, green: 0.94, blue: 0.8, alpha: 0.96)
            sign.strokeColor = .brown
            let title = SKLabelNode(text: "\(playerName)’s Farm")
            title.fontName = "AvenirNext-DemiBold"; title.fontSize = min(26, 500 / CGFloat(max(20, playerName.count + 7)))
            title.fontColor = .brown; title.verticalAlignmentMode = .center; sign.addChild(title); root.addChild(sign)
            return root
        }
        let ground = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 1000, height: 620))
        ground.fillColor = UIColor(red: 0.66, green: 0.82, blue: 0.46, alpha: 1); ground.strokeColor = .clear; root.addChild(ground)
        for index in 0..<3 {
            let hill = SKShapeNode(ellipseOf: CGSize(width: 600, height: 220))
            hill.position = CGPoint(x: 100 + index * 360, y: 665)
            hill.fillColor = UIColor(red: 0.41, green: 0.66, blue: 0.43, alpha: 1); hill.strokeColor = .clear; root.addChild(hill)
        }
        let lake = SKShapeNode(ellipseOf: CGSize(width: 260, height: 95))
        lake.fillColor = .systemTeal; lake.strokeColor = .white; lake.position = CGPoint(x: 795, y: 525); root.addChild(lake)
        let lakeText = SKLabelNode(text: "Lake"); lakeText.fontSize = 19; lakeText.fontColor = .white
        lakeText.position = lake.position; root.addChild(lakeText)
        for (area, point) in locations {
            let building = SKNode(); building.name = "area-\(area.rawValue)"; building.position = point
            let width: CGFloat = area == .washBay ? 125 : (area == .arena ? 250 : 155)
            let height: CGFloat = area == .arena ? 145 : (area == .washBay ? 95 : 125)
            let base = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: area == .roundYard ? 62 : 16)
            base.fillColor = [.arena, .roundYard].contains(area) ? UIColor(red: 0.93, green: 0.77, blue: 0.53, alpha: 1) : .brown.withAlphaComponent(0.75)
            if area == .paddock { base.fillColor = .systemGreen.withAlphaComponent(0.45) }
            base.strokeColor = .white; base.lineWidth = 4; building.addChild(base)
            let icon = SKLabelNode(text: area.icon); icon.fontSize = 43; icon.verticalAlignmentMode = .center
            icon.position.y = 8; building.addChild(icon)
            let label = SKLabelNode(text: area.title); label.fontName = "AvenirNext-DemiBold"; label.fontSize = area == .washBay ? 17 : 20
            label.fontColor = .white; label.position.y = -40; building.addChild(label)
            root.addChild(building)
        }
        let car = SKLabelNode(text: "🚙"); car.fontSize = 32; car.fontColor = .white
        car.position = CGPoint(x: 645, y: 140); root.addChild(car)
        let carLabel = SKLabelNode(text: "White Model Y"); carLabel.fontSize = 11; carLabel.fontColor = .darkGray
        carLabel.position = CGPoint(x: 650, y: 120); root.addChild(carLabel)
        let sign = SKLabelNode(text: "\(playerName)’s Farm")
        sign.fontName = "AvenirNext-DemiBold"; sign.fontSize = min(28, 700 / CGFloat(max(20, playerName.count + 7)))
        sign.fontColor = .brown; sign.position = CGPoint(x: 450, y: 550); root.addChild(sign)
        return root
    }
}
final class FarmScene: SKScene {
    var onVisit: ((FarmArea) -> Void)?
    private var playerName = "Your"
    override init() {
        super.init(size: CGSize(width: 1000, height: 620)); scaleMode = .aspectFit
        backgroundColor = UIColor(red: 0.66, green: 0.82, blue: 0.46, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func didMove(to view: SKView) { rebuild() }
    func updateName(_ name: String) { if playerName != name { playerName = name; rebuild() } }
    private func rebuild() { removeAllChildren(); addChild(FarmLandscape.make(playerName: playerName)) }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        for hit in nodes(at: point) {
            var current: SKNode? = hit
            while let node = current {
                if let name = node.name, name.hasPrefix("area-"), let area = FarmArea(rawValue: String(name.dropFirst(5))) {
                    onVisit?(area); return
                }
                current = node.parent
            }
        }
    }
}
