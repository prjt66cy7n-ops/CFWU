import SpriteKit
import SwiftUI

enum FarmArea: String, CaseIterable, Identifiable {
    case stables, washBay, arena, roundYard, paddock, chickenCoop, farmhouse
    var id: String { rawValue }
    var title: String {
        switch self {
        case .stables: return "Stables"
        case .washBay: return "Wash Bay"
        case .arena: return "Arena"
        case .roundYard: return "Round Yard"
        case .paddock: return "Paddocks"
        case .chickenCoop: return "Chicken Coop"
        case .farmhouse: return "Farmhouse"
        }
    }
    var icon: String {
        switch self {
        case .stables: return "🐴"
        case .washBay: return "🧽"
        case .arena: return "🏇"
        case .roundYard: return "⭕️"
        case .paddock: return "🌾"
        case .chickenCoop: return "🐔"
        case .farmhouse: return "🏡"
        }
    }
}

// Temporary vector art; concept identifiers are not bundled image assets.
final class FarmScene: SKScene {
    override init() {
        super.init(size: CGSize(width: 1200, height: 800))
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.78, green: 0.9, blue: 0.69, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func didMove(to view: SKView) { drawFarm() }
    override func didChangeSize(_ oldSize: CGSize) { drawFarm() }
    private func drawFarm() {
        removeAllChildren()
        let hill = SKShapeNode(ellipseOf: CGSize(width: size.width * 1.4, height: size.height * 0.5))
        hill.fillColor = UIColor(red: 0.52, green: 0.72, blue: 0.45, alpha: 1)
        hill.strokeColor = .clear; hill.position = CGPoint(x: size.width * 0.5, y: size.height)
        addChild(hill)
        let lake = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.22, height: size.height * 0.14))
        lake.fillColor = .systemTeal; lake.strokeColor = .white
        lake.position = CGPoint(x: size.width * 0.82, y: size.height * 0.12); addChild(lake)
        let label = SKLabelNode(text: "Lake · scenery")
        label.fontName = "AvenirNext-DemiBold"; label.fontSize = 16; label.fontColor = .darkGray
        label.position = lake.position; addChild(label)
    }
}
