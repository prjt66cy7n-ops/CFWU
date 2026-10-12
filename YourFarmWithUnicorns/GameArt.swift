import SwiftUI
import UIKit

extension Palette {
    var color: Color { Color(uiColor: uiColor) }
    var uiColor: UIColor {
        switch self {
        case .pink: return .systemPink
        case .purple: return .systemPurple
        case .blue: return .systemBlue
        case .green: return .systemGreen
        case .red: return .systemRed
        case .blackGold: return UIColor(red: 0.16, green: 0.12, blue: 0.08, alpha: 1)
        }
    }
    var artColumn: Int { Self.allCases.firstIndex(of: self)! }
}

// Atlas regions are rendered in memory. Source sheets stay intact; later
// production atlases can replace these images without changing stable horse IDs.
enum GameArt {
    private static let cache = NSCache<NSString, UIImage>()
    static func region(sheet: String, column: Int, row: Int, columns: Int, rows: Int) -> UIImage? {
        let key = "\(sheet)-\(column)-\(row)" as NSString
        if let image = cache.object(forKey: key) { return image }
        guard let full = UIImage(named: sheet)?.cgImage else { return nil }
        let x = Int(Double(full.width) * Double(column) / Double(columns))
        let y = Int(Double(full.height) * Double(row) / Double(rows))
        let right = Int(Double(full.width) * Double(column + 1) / Double(columns))
        let bottom = Int(Double(full.height) * Double(row + 1) / Double(rows))
        guard let cropped = full.cropping(to: CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(right - x), height: CGFloat(bottom - y))) else { return nil }
        let image = UIImage(cgImage: cropped)
        cache.setObject(image, forKey: key)
        return image
    }
    static func horse(_ horse: Horse) -> UIImage? {
        region(sheet: "HorsePortraitSheet", column: horse.portraitIndex % 4, row: horse.portraitIndex / 4, columns: 4, rows: 4)
    }
    static func rider(_ rider: Rider, palette: Palette) -> UIImage? {
        region(sheet: "RiderPaletteSheet", column: palette.artColumn, row: rider == .girl ? 0 : 1, columns: 6, rows: 2)
    }
    static func pad(_ palette: Palette) -> UIImage? {
        region(sheet: "TackPaletteSheet", column: palette.artColumn, row: 0, columns: 6, rows: 2)
    }
}
struct HorsePortrait: View {
    let horse: Horse
    var body: some View {
        Group {
            if let image = GameArt.horse(horse) { Image(uiImage: image).resizable().scaledToFit() }
            else { Text("🐴").font(.system(size: 60)) }
        }.accessibilityLabel(horse.name)
    }
}
struct RiderPortrait: View {
    let rider: Rider
    let palette: Palette
    var body: some View {
        Group {
            if let image = GameArt.rider(rider, palette: palette) { Image(uiImage: image).resizable().scaledToFit() }
            else { Text(rider == .boy ? "👦" : "👧").font(.system(size: 70)) }
        }.accessibilityLabel("\(rider.rawValue) rider in \(palette.label)")
    }
}
