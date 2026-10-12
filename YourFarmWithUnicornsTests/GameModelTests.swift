import XCTest
@testable import YourFarmWithUnicorns

final class GameModelTests: XCTestCase {
    func testIndependentProfilesSurviveSaveAndRename() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = SaveStore(url: folder.appendingPathComponent("profiles.json"))
        var first = Player(name: "Alice", rider: .girl, palette: .purple)
        let second = Player(name: "Bob", rider: .boy, palette: .blue)
        first.ribbons = ["stables"]; first.wandFound = true; first.tack.saddle = true
        first.name = "Charlotte"
        var farm = SavedFarm(); farm.players = [first, second]; farm.activeProfileID = second.id
        try store.save(farm)
        let loaded = try store.load()
        XCTAssertEqual(loaded.players, [first, second])
        XCTAssertEqual(loaded.activeProfileID, second.id)
        XCTAssertTrue(loaded.players[1].ribbons.isEmpty)
        XCTAssertFalse(loaded.players[1].wandFound)
        XCTAssertEqual(loaded.players[0].id, first.id)
    }
    func testDailyResetPreservesChoices() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var player = Player(name: "Alice", rider: .girl, palette: .purple)
        player.refreshDay(now: Date(timeIntervalSince1970: 0), calendar: calendar)
        player.ribbons = ["stables"]; player.wandFound = true
        player.completedActivities = ["stables": ["feed"]]
        player.tack.saddle = true; player.musicEnabled = false
        player.refreshDay(now: Date(timeIntervalSince1970: 3600), calendar: calendar)
        XCTAssertEqual(player.ribbons, ["stables"])
        player.refreshDay(now: Date(timeIntervalSince1970: 86400), calendar: calendar)
        XCTAssertTrue(player.ribbons.isEmpty); XCTAssertFalse(player.wandFound)
        XCTAssertTrue(player.completedActivities.isEmpty)
        XCTAssertTrue(player.tack.saddle); XCTAssertFalse(player.musicEnabled)
        XCTAssertEqual(player.palette, .purple)
    }
    func testCorruptSaveIsPreserved() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = SaveStore(url: folder.appendingPathComponent("profiles.json"))
        let invalid = Data("broken".utf8)
        try invalid.write(to: store.url)
        XCTAssertThrowsError(try store.load())
        try store.preserveInvalidSave()
        let backups = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("unreadable-") }
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: backups[0]), invalid)
    }
}
