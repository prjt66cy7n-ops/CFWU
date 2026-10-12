import XCTest
@testable import YourFarmWithUnicorns

final class GameplayTests: XCTestCase {
    private let day = Date(timeIntervalSince1970: 1_720_000_000)
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!; return calendar
    }
    func testThreeDistinctStableActivitiesAwardOnlyOneRibbon() {
        var player = Player(name: "Child", rider: .girl, palette: .pink)
        for _ in 0..<5 { XCTAssertFalse(player.completeActivity(area: .stables, activity: "feed", now: day, calendar: calendar)) }
        XCTAssertEqual(player.completedActivities["stables"], ["feed"])
        XCTAssertFalse(player.completeActivity(area: .stables, activity: "stableWater", now: day, calendar: calendar))
        XCTAssertTrue(player.completeActivity(area: .stables, activity: "sweepStable", now: day, calendar: calendar))
        XCTAssertFalse(player.completeActivity(area: .stables, activity: "sweepStable", now: day, calendar: calendar))
        XCTAssertEqual(player.ribbons, ["stables"])
    }
    func testTasksCanBeCompletedInAnyOrderAndUnknownIDsDoNotCount() {
        var player = Player(name: "Child", rider: .boy, palette: .blue)
        for activity in ["treats", "eggs", "straw"] { _ = player.completeActivity(area: .chickenCoop, activity: activity, now: day, calendar: calendar) }
        XCTAssertEqual(player.ribbons, ["chickenCoop"])
        XCTAssertFalse(player.completeActivity(area: .chickenCoop, activity: "vegetables", now: day, calendar: calendar))
        XCTAssertEqual(player.completedActivities["chickenCoop"]?.count, 3)
        XCTAssertFalse(player.completeActivity(area: .farmhouse, activity: "cook", now: day, calendar: calendar))
        XCTAssertFalse(player.ribbons.contains("farmhouse"))
    }
    func testWandRequiresThreeRibbonsCorrectSpotAndOnlyOneDiscovery() {
        var player = Player(name: "Child", rider: .girl, palette: .purple)
        player.refreshDay(now: day, calendar: calendar); player.wandSpot = 2
        XCTAssertFalse(player.discoverWand(at: 2, now: day, calendar: calendar))
        player.ribbons = ["stables", "paddock", "chickenCoop"]
        XCTAssertFalse(player.discoverWand(at: 1, now: day, calendar: calendar))
        XCTAssertTrue(player.discoverWand(at: 2, now: day, calendar: calendar))
        XCTAssertTrue(player.canFly)
        XCTAssertFalse(player.discoverWand(at: 2, now: day, calendar: calendar))
        player.refreshDay(now: day.addingTimeInterval(86400), calendar: calendar)
        XCTAssertFalse(player.canFly); XCTAssertFalse(player.wandFound); XCTAssertTrue(player.ribbons.isEmpty)
    }
    func testDailyRewardsAndWandStaySeparateAfterSave() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        var first = Player(name: "A", rider: .girl, palette: .pink)
        let second = Player(name: "B", rider: .boy, palette: .green)
        first.refreshDay(now: day, calendar: calendar)
        first.ribbons = ["stables", "paddock", "chickenCoop"]
        XCTAssertTrue(first.discoverWand(at: first.wandSpot, now: day, calendar: calendar))
        let store = SaveStore(url: dir.appendingPathComponent("profiles.json"))
        var farm = SavedFarm(); farm.players = [first, second]; farm.activeProfileID = second.id
        try store.save(farm)
        let saved = try store.load()
        XCTAssertTrue(saved.players[0].canFly); XCTAssertFalse(saved.players[1].canFly)
        XCTAssertEqual(saved.activeProfileID, second.id)
    }
    func testBucketsRequireTapPlacementFillAndDelivery() {
        for activity in [FarmActivity.stableWater, .paddockWater] {
            var game = ChoreGame(activity: activity)
            game.tapTarget(); game.dropAtDestination(); XCTAssertFalse(game.completed)
            game.dropAtTap(); game.dropAtDestination(); XCTAssertFalse(game.completed)
            game.tapTarget(); XCTAssertTrue(game.bucketFull)
            game.dropAtDestination(); XCTAssertTrue(game.completed)
        }
    }
    func testManureRequiresScoopingEachOfFivePiles() {
        var game = ChoreGame(activity: .manure)
        game.dropAtDestination(item: 0); XCTAssertTrue(game.collection.isEmpty)
        for index in 0..<5 { game.tapTarget(index); game.dropAtDestination(item: index); game.dropAtDestination(item: index) }
        XCTAssertEqual(game.collection.count, 5); XCTAssertTrue(game.completed)
    }
    func testEggsAndStrawRequireEachNestAndIgnoreInvalidIndexes() {
        for activity in [FarmActivity.eggs, .straw] {
            var game = ChoreGame(activity: activity)
            game.tapTarget(-1); game.dropAtDestination(item: 9); XCTAssertTrue(game.collection.isEmpty)
            game.dropAtDestination(item: 0); XCTAssertFalse(game.completed)
            for index in 0..<4 { game.tapTarget(index); game.dropAtDestination(item: index) }
            XCTAssertEqual(game.collection.count, 4); XCTAssertTrue(game.completed)
        }
    }
    func testCleaningRequiresRealTravelAndTroughMustRefillAfterClean() {
        var trough = ChoreGame(activity: .trough)
        trough.tapTarget(); XCTAssertFalse(trough.completed)
        trough.scrub(distance: 0); trough.scrub(distance: .nan); XCTAssertEqual(trough.progress, 0)
        trough.scrub(distance: 10000); XCTAssertFalse(trough.completed)
        for _ in 0..<7 { trough.scrub(distance: 80) }
        XCTAssertEqual(trough.stage, 1); XCTAssertFalse(trough.completed)
        trough.tapTarget(); XCTAssertTrue(trough.completed)
        for activity in [FarmActivity.brush, .sweepStable, .sweepCoop, .grain] {
            var game = ChoreGame(activity: activity)
            for _ in 0..<8 { game.scrub(distance: 80) }
            XCTAssertTrue(game.completed, activity.rawValue)
        }
    }
    func testWashingRequiresWetScrubAndRinse() {
        var game = ChoreGame(activity: .wash)
        for _ in 0..<4 { game.scrub(distance: 80) }
        XCTAssertEqual(game.stage, 1); XCTAssertFalse(game.completed)
        for _ in 0..<8 { game.scrub(distance: 80) }
        XCTAssertEqual(game.stage, 2); XCTAssertFalse(game.completed)
        for _ in 0..<4 { game.scrub(distance: 80) }
        XCTAssertTrue(game.completed)
    }
    func testAllFourHoovesMustBeLiftedAndPicked() {
        var game = ChoreGame(activity: .hooves)
        for index in 0..<4 {
            game.tapTarget(index); XCTAssertEqual(game.liftedHoof, index)
            for _ in 0..<3 { game.tapTarget(index) }
            XCTAssertEqual(game.hoofPicks[index], 3)
        }
        XCTAssertTrue(game.completed); XCTAssertEqual(game.collection.count, 4)
    }
    func testEquippedTackCanBeRemovedAndReappliedWithoutAutoCompletion() {
        var game = ChoreGame(activity: .tack, tack: Tack(saddlePad: true, saddle: true, bridle: true))
        XCTAssertFalse(game.completed)
        game.equip(0); XCTAssertFalse(game.completed)
        game.removeTack(1); XCTAssertFalse(game.tack.saddle)
        game.equip(1); XCTAssertTrue(game.completed)
        XCTAssertTrue(game.tack.saddlePad); XCTAssertTrue(game.tack.bridle)
    }
    func testCoopWaterNeedsSustainedHoldingAndFenceMustActuallyBeBroken() {
        var water = ChoreGame(activity: .coopWater)
        water.holdWater(seconds: 1000); XCTAssertFalse(water.completed)
        for _ in 0..<19 { water.holdWater(seconds: 0.1) }
        XCTAssertTrue(water.completed)
        var fence = ChoreGame(activity: .fence, brokenFence: false)
        for _ in 0..<9 { fence.tapTarget() }
        XCTAssertFalse(fence.completed)
        fence = ChoreGame(activity: .fence)
        for _ in 0..<5 { fence.tapTarget() }
        XCTAssertTrue(fence.completed)
    }
    func testRepeatableFoodAndFreshSceneState() {
        for activity in [FarmActivity.feed, .hay, .treats] {
            var game = ChoreGame(activity: activity); game.dropAtDestination(); XCTAssertTrue(game.completed)
            game = ChoreGame(activity: activity); XCTAssertFalse(game.completed); XCTAssertEqual(game.progress, 0)
        }
    }
    func testAllThirteenUnicornsRetainSizeAndChosenPaletteAndHideTack() {
        for horse in HorseCatalog.all {
            var player = Player(name: "Child", rider: .girl, palette: .green); player.selectHorse(horse.id)
            player.tack = Tack(saddlePad: true, saddle: true, bridle: true)
            let appearance = UnicornAppearance(player: player)
            XCTAssertEqual(appearance.sourceHorseID, horse.id); XCTAssertEqual(appearance.size, horse.size)
            XCTAssertEqual(appearance.palette, .green); XCTAssertTrue(appearance.winged); XCTAssertTrue(appearance.whiteBaseCoat)
            XCTAssertFalse(appearance.tackVisible)
            XCTAssertEqual(player.tack, Tack(saddlePad: true, saddle: true, bridle: true))
        }
    }
    func testFlightTimingAndOptionalStars() {
        var flight = FlightGame()
        flight.tapStar(); XCTAssertEqual(flight.rainbowStars, 0)
        for _ in 0..<26 { flight.step(seconds: 0.1) }
        XCTAssertEqual(flight.phase, .flying)
        flight.tapStar(); XCTAssertEqual(flight.rainbowStars, 1)
        for _ in 0..<330 { flight.step(seconds: 0.1) }
        XCTAssertEqual(flight.phase, .finale)
        for _ in 0..<30 { flight.step(seconds: 0.1) }
        XCTAssertEqual(flight.phase, .finished)
        XCTAssertEqual(flight.elapsed, FlightGame.duration)
    }
    func testHomeExitsFlightImmediatelyAndInvalidTimeCannotAdvanceIt() {
        var flight = FlightGame()
        flight.step(seconds: .nan); flight.step(seconds: -1); XCTAssertEqual(flight.elapsed, 0)
        flight.home(); XCTAssertEqual(flight.phase, .finished)
        flight.step(seconds: 0.1); XCTAssertEqual(flight.elapsed, 0)
    }
}
