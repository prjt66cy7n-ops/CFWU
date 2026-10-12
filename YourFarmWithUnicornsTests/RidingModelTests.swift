import XCTest
@testable import YourFarmWithUnicorns

final class RidingModelTests: XCTestCase {
    func testCatalogHasThirteenUniqueHorsesAndRequiredSizes() {
        XCTAssertEqual(HorseCatalog.all.count, 13)
        XCTAssertEqual(Set(HorseCatalog.all.map(\.id)).count, 13)
        XCTAssertEqual(HorseCatalog.horse(id: "roo").coat, .bay)
        XCTAssertEqual(HorseCatalog.horse(id: "daisy").size, .pony)
        XCTAssertEqual(HorseCatalog.horse(id: "bruno").size, .draft)
    }
    func testSwitchingHorsePreservesOutfitAndTack() {
        var child = Player(name: "Charlotte", rider: .girl, palette: .purple)
        child.tack = Tack(saddlePad: true, saddle: true, bridle: true)
        child.selectHorse("bruno")
        XCTAssertEqual(child.selectedHorseID, "bruno")
        XCTAssertEqual(child.tack, Tack(saddlePad: true, saddle: true, bridle: true))
        XCTAssertEqual(child.palette, .purple)
        child.selectHorse("unknown")
        XCTAssertEqual(child.selectedHorseID, "bruno")
    }
    func testEightDirectionsQuantizeCorrectly() {
        for facing in RideFacing.allCases { XCTAssertEqual(RideFacing.from(facing.vector), facing) }
    }
    func testJoystickBoundsAndRelease() {
        var ride = ArenaRide()
        for _ in 0..<1000 { ride.step(seconds: 0.1, input: RidePoint(x: -20, y: -20)) }
        XCTAssertGreaterThanOrEqual(ride.position.x, ArenaRide.inset)
        XCTAssertGreaterThanOrEqual(ride.position.y, ArenaRide.inset)
        let stopped = ride.position
        ride.step(seconds: 0.1, input: .zero)
        XCTAssertEqual(ride.position, stopped)
    }
    func testJumpStartsOnCorrectApproachAndLandsBeyondPole() {
        var ride = ArenaRide(); ride.position = RidePoint(x: 280, y: 190)
        ride.step(seconds: 0.1, input: RidePoint(x: 0, y: 1))
        XCTAssertTrue(ride.isJumping)
        for _ in 0..<7 { ride.step(seconds: 0.1, input: .zero) }
        XCTAssertFalse(ride.isJumping)
        XCTAssertGreaterThan(ride.position.y, 240)
        XCTAssertEqual(ride.completedJumps, [0])
        XCTAssertEqual(ride.jumpHeight, 0)
    }
    func testParallelApproachDoesNotJump() {
        var ride = ArenaRide(); ride.position = RidePoint(x: 250, y: 220)
        ride.step(seconds: 0.1, input: RidePoint(x: 1, y: 0))
        XCTAssertFalse(ride.isJumping)
        XCTAssertTrue(ride.completedJumps.isEmpty)
    }
    func testCompletingCourseEmitsExactlyOneCompletion() {
        var ride = ArenaRide(); var completions = 0
        for jump in ride.course.jumps.reversed() {
            ride.position = jump.center - jump.normal * 50
            for _ in 0..<14 {
                ride.step(seconds: 0.1, input: jump.normal)
                if ride.justCompletedCourse { completions += 1 }
            }
            for _ in 0..<10 { ride.step(seconds: 0.1, input: .zero) }
        }
        XCTAssertTrue(ride.courseComplete)
        XCTAssertEqual(completions, 1)
        ride.chooseCourse(1)
        XCTAssertFalse(ride.courseComplete)
        XCTAssertEqual(ride.course.id, "rainbow")
    }
    func testPlayfulFallenPoleCanBeResetAndRunoutCanRetry() {
        var ride = ArenaRide(); var sawRunout = false
        for attempt in 1...12 {
            ride.position = RidePoint(x: 280, y: 190)
            ride.step(seconds: 0.1, input: RidePoint(x: 0, y: 1))
            if attempt == 11 {
                sawRunout = ride.feedback?.contains("detour") == true
                XCTAssertFalse(ride.isJumping)
            }
            for _ in 0..<8 { ride.step(seconds: 0.1, input: .zero) }
            if attempt == 7 {
                XCTAssertTrue(ride.fallenPoles.contains(0))
                ride.resetPole(0); XCTAssertTrue(ride.fallenPoles.isEmpty)
            }
            for _ in 0..<10 { ride.step(seconds: 0.1, input: .zero) }
        }
        XCTAssertTrue(sawRunout)
        XCTAssertTrue(ride.completedJumps.contains(0))
    }
    func testRoundYardEmitsGaitAndPoleActivities() {
        var ride = RoundYardRide(); ride.togglePoles()
        var events: [String] = []
        for _ in 0..<180 { ride.step(seconds: 0.1); events += ride.completedActivities }
        XCTAssertEqual(events.filter { $0 == "walk" }.count, 1)
        XCTAssertEqual(events.filter { $0 == "groundPoles" }.count, 1)
    }
    func testChangingGaitRequiresWholeNewCircuit() {
        var ride = RoundYardRide()
        for _ in 0..<100 { ride.step(seconds: 0.1) }
        ride.setGait(.trot)
        var events: [String] = []
        for _ in 0..<100 { ride.step(seconds: 0.1); events += ride.completedActivities }
        XCTAssertTrue(events.isEmpty)
    }
    func testDirectionChangeSlowsAndResumesSameGait() {
        var ride = RoundYardRide(); ride.setGait(.canter); ride.changeDirection()
        for _ in 0..<7 { ride.step(seconds: 0.1) }
        XCTAssertTrue(ride.isTurning); XCTAssertLessThan(ride.speedMultiplier, 0.2)
        for _ in 0..<9 { ride.step(seconds: 0.1) }
        XCTAssertFalse(ride.isTurning); XCTAssertEqual(ride.direction, -1)
        XCTAssertEqual(ride.gait, .canter); XCTAssertEqual(ride.speedMultiplier, 1)
    }
    func testInvalidTimeOrInputDoesNotCorruptPositions() {
        var arena = ArenaRide(); let position = arena.position
        arena.step(seconds: .nan, input: RidePoint(x: 1, y: 0))
        arena.step(seconds: 0.1, input: RidePoint(x: .infinity, y: 0))
        XCTAssertEqual(arena.position, position)
        var yard = RoundYardRide(); let angle = yard.angle
        yard.step(seconds: -.infinity)
        XCTAssertEqual(yard.angle, angle)
    }
}
