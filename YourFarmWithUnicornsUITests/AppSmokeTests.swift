import XCTest

final class AppSmokeTests: XCTestCase {
    @MainActor func testLaunchStableChoresRibbonHorseSelectionAndNavigation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-store", UUID().uuidString]
        app.launch()
        let name = app.textFields["player-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 15))
        name.tap(); name.typeText("CI Farmer\n")
        app.buttons["save-character"].tap()
        XCTAssertTrue(app.staticTexts["CI Farmer’s Farm"].waitForExistence(timeout: 5))
        app.buttons["visit-stables"].tap()
        let canvas = app.otherElements["farm-task-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        drag(canvas, from: CGPoint(x: 150, y: 95), to: CGPoint(x: 470, y: 325))
        assertCompleted(app)
        app.buttons["activity-stableWater"].tap()
        drag(canvas, from: CGPoint(x: 150, y: 95), to: CGPoint(x: 180, y: 335))
        world(canvas, CGPoint(x: 180, y: 430)).tap()
        drag(canvas, from: CGPoint(x: 180, y: 335), to: CGPoint(x: 505, y: 260))
        assertCompleted(app)
        app.buttons["activity-sweepStable"].tap()
        for _ in 0..<3 { drag(canvas, from: CGPoint(x: 150, y: 95), to: CGPoint(x: 790, y: 205)) }
        assertCompleted(app)
        XCTAssertEqual(app.otherElements["ribbon-stables"].label, "Stables ribbon earned")
        app.buttons["choose-horse"].tap()
        XCTAssertTrue(app.buttons["horse-daisy"].waitForExistence(timeout: 5))
        app.buttons["horse-daisy"].tap()
        app.buttons["home"].tap()
        XCTAssertTrue(app.staticTexts["Daisy · Pink"].waitForExistence(timeout: 5))
        for place in ["washBay", "paddock", "chickenCoop", "farmhouse", "arena", "roundYard"] {
            app.buttons["visit-\(place)"].tap()
            XCTAssertTrue(app.buttons["home"].waitForExistence(timeout: 5)); app.buttons["home"].tap()
        }
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["CI Farmer’s Farm"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Daisy · Pink"].exists)
        XCTAssertEqual(app.otherElements["ribbon-stables"].label, "Stables ribbon earned")
    }
    @MainActor func testWandDiscoveryFlightEarlyHomeAndCompleteReplay() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-store", UUID().uuidString, "--ui-test-flight-ready"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Sunny · Purple"].waitForExistence(timeout: 15))
        app.buttons["visit-farmhouse"].tap()
        app.buttons["wand-search-0"].tap()
        XCTAssertTrue(app.staticTexts["🪄 Your wand is waiting at the stables"].waitForExistence(timeout: 5))
        app.buttons["home"].tap()
        startFlight(app)
        app.buttons["home"].tap()
        XCTAssertTrue(app.staticTexts["Sunny · Purple"].waitForExistence(timeout: 5))
        startFlight(app)
        // Await the genuine 38-second scene, without advancing its clock in a fixture.
        XCTAssertTrue(app.staticTexts["Sunny · Purple"].waitForExistence(timeout: 55))
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["Sunny · Purple"].waitForExistence(timeout: 15))
        app.buttons["visit-stables"].tap()
        XCTAssertTrue(app.buttons["launch-wand"].waitForExistence(timeout: 5))
    }
    @MainActor private func startFlight(_ app: XCUIApplication) {
        app.buttons["visit-stables"].tap()
        app.buttons["launch-wand"].tap()
        let wand = app.descendants(matching: .any).matching(identifier: "wand-drag").firstMatch
        let target = app.descendants(matching: .any).matching(identifier: "wand-target").firstMatch
        XCTAssertTrue(wand.waitForExistence(timeout: 5)); XCTAssertTrue(target.exists)
        wand.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.2, thenDragTo: target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        XCTAssertTrue(app.otherElements["unicorn-flight"].waitForExistence(timeout: 5))
    }
    @MainActor private func assertCompleted(_ app: XCUIApplication) {
        let result = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Tap the activity to play again")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5))
    }
    @MainActor private func world(_ canvas: XCUIElement, _ point: CGPoint) -> XCUICoordinate {
        let frame = canvas.frame
        let scale = min(frame.width / 1000, frame.height / 580)
        let x = ((frame.width - 1000 * scale) / 2 + point.x * scale) / frame.width
        let y = ((frame.height - 580 * scale) / 2 + (580 - point.y) * scale) / frame.height
        return canvas.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
    }
    @MainActor private func drag(_ canvas: XCUIElement, from: CGPoint, to: CGPoint) {
        world(canvas, from).press(forDuration: 0.2, thenDragTo: world(canvas, to))
    }
}
