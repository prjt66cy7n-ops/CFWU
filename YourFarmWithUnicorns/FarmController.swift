import SwiftUI

@MainActor final class FarmController: ObservableObject {
    @Published private(set) var farm = SavedFarm()
    @Published var message: String?
    @Published var storageBlocked = false
    struct Reward: Identifiable { let id = UUID(); let area: FarmArea }
    @Published var reward: Reward?
    private let store: SaveStore
    var active: Player? { farm.players.first { $0.id == farm.activeProfileID } }
    init(store: SaveStore? = nil) {
        self.store = store ?? Self.testStore() ?? SaveStore(url: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("YourFarmWithUnicorns/profiles.json"))
        do { farm = try self.store.load() }
        catch {
            do { try self.store.preserveInvalidSave(); message = "The saved game could not be read. A recovery copy was kept. You can create a new player." }
            catch { storageBlocked = true; message = "The saved game could not be read or safely backed up. Please close the app and check device storage before trying again." }
        }
        refreshDay()
    }
    private static func testStore() -> SaveStore? {
        #if DEBUG
        // UI fixtures use their own random temporary save, never a child's real file.
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--ui-test-store"), arguments.indices.contains(index + 1),
              let id = UUID(uuidString: arguments[index + 1]) else { return nil }
        let store = SaveStore(url: FileManager.default.temporaryDirectory
            .appendingPathComponent("cfwu-ui-\(id.uuidString).json"))
        if arguments.contains("--ui-test-flight-ready"), !FileManager.default.fileExists(atPath: store.url.path) {
            var player = Player(name: "Flight Farmer", rider: .girl, palette: .purple)
            player.refreshDay(); player.selectedHorseID = "sunny"
            player.tack = Tack(saddlePad: true, saddle: true, bridle: true)
            player.musicEnabled = false; player.sfxEnabled = false
            for area in [FarmArea.stables, .washBay, .paddock] {
                for activity in area.activityIDs.sorted().prefix(3) { _ = player.completeActivity(area: area, activity: activity) }
            }
            player.wandSpot = 0
            var farm = SavedFarm(); farm.players = [player]; farm.activeProfileID = player.id
            do { try store.save(farm) } catch { assertionFailure("Could not prepare isolated UI fixture: \(error)") }
        }
        return store
        #else
        return nil
        #endif
    }
    func save() {
        guard !storageBlocked else { return }
        do { try store.save(farm) }
        catch { message = "Your changes could not be saved. Please check device storage and try again." }
    }
    func create(name: String, rider: Rider, palette: Palette) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !storageBlocked else { return }
        reward = nil
        var player = Player(name: name, rider: rider, palette: palette)
        player.refreshDay(); farm.players.append(player); farm.activeProfileID = player.id; save()
    }
    func switchPlayer(_ id: UUID) {
        guard farm.players.contains(where: { $0.id == id }) else { return }
        reward = nil
        save(); farm.activeProfileID = id; refreshDay(); save()
    }
    func edit(name: String, rider: Rider, palette: Palette) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        update { $0.name = name; $0.rider = rider; $0.palette = palette }
    }
    func update(_ change: (inout Player) -> Void) {
        guard let index = farm.players.firstIndex(where: { $0.id == farm.activeProfileID }) else { return }
        change(&farm.players[index]); save()
    }
    func selectHorse(_ id: String) { update { $0.selectHorse(id) } }
    func recordActivity(area: String, activity: String) {
        guard let area = FarmArea(rawValue: area) else { return }
        refreshDay()
        var awarded = false
        update { awarded = $0.completeActivity(area: area, activity: activity) }
        if awarded { reward = Reward(area: area) }
    }
    func discoverWand(at spot: Int) {
        refreshDay()
        update { _ = $0.discoverWand(at: spot) }
    }
    func clearReward(_ id: UUID) { if reward?.id == id { reward = nil } }
    func refreshDay() {
        let previousPlayers = farm.players
        let previousActive = farm.activeProfileID
        for index in farm.players.indices {
            farm.players[index].refreshDay()
            for area in FarmArea.ribbonAreas {
                let saved = farm.players[index].completedActivities[area.rawValue, default: []]
                if saved.intersection(area.activityIDs).count >= 3 { farm.players[index].ribbons.insert(area.rawValue) }
            }
        }
        if farm.activeProfileID == nil { farm.activeProfileID = farm.players.first?.id }
        if farm.players != previousPlayers || farm.activeProfileID != previousActive { save() }
    }
}
