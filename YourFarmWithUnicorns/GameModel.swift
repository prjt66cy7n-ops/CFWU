import Foundation

 enum Rider: String, Codable, CaseIterable { case boy, girl }
 enum Palette: String, Codable, CaseIterable {
    case pink, purple, blue, green, red, blackGold
    var label: String { self == .blackGold ? "Black / Gold" : rawValue.capitalized }
 }
 struct Tack: Codable, Equatable { var saddlePad = false; var saddle = false; var bridle = false }
 struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var rider: Rider
    var palette: Palette
    var selectedHorseID = "roo"
    var tack = Tack()
    var musicEnabled = true
    var sfxEnabled = true
    var dailyDate = ""
    var completedActivities: [String: Set<String>] = [:]
    var ribbons: Set<String> = []
    var wandSpot = Int.random(in: 0..<6)
    var wandFound = false
    init(name: String, rider: Rider, palette: Palette) {
        id = UUID(); self.name = name; self.rider = rider; self.palette = palette
    }
    mutating func refreshDay(now: Date = Date(), calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        let key = "\(parts.year!)-\(parts.month!)-\(parts.day!)"
        guard key != dailyDate else { return }
        dailyDate = key; completedActivities = [:]; ribbons = []; wandFound = false
        wandSpot = Int.random(in: 0..<6)
    }
 }
 struct SavedFarm: Codable {
    var version = 1
    var activeProfileID: UUID?
    var players: [Player] = []
 }
 final class SaveStore {
    let url: URL
    init(url: URL) { self.url = url }
    func load() throws -> SavedFarm {
        guard FileManager.default.fileExists(atPath: url.path) else { return SavedFarm() }
        let saved = try JSONDecoder().decode(SavedFarm.self, from: Data(contentsOf: url))
        guard saved.version == 1,
              Set(saved.players.map(\.id)).count == saved.players.count,
              saved.players.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              saved.activeProfileID == nil || saved.players.contains(where: { $0.id == saved.activeProfileID })
        else { throw CocoaError(.fileReadCorruptFile) }
        return saved
    }
    func save(_ farm: SavedFarm) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(farm).write(to: url, options: .atomic)
    }
    func preserveInvalidSave() throws {
        let backup = url.deletingLastPathComponent().appendingPathComponent("unreadable-\(UUID().uuidString).json")
        try FileManager.default.copyItem(at: url, to: backup)
    }
 }
