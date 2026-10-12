import XCTest

final class NovaPlayerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        let bundle = Bundle(for: Self.self)
        let video = try XCTUnwrap(bundle.url(forResource: "sample", withExtension: "mp4", subdirectory: "Fixtures")
                                 ?? bundle.url(forResource: "sample", withExtension: "mp4"))
        app.launchArguments = [video.path]
        app.launch()
        XCTAssertTrue(app.buttons["playPause"].waitForExistence(timeout: 10))
    }

    override func tearDown() { app.terminate() }

    func testPlaybackKeyboardMuteAndReturnHome() {
        let button = app.buttons["playPause"]
        let playing = NSPredicate(format: "label == %@", "Pause")
        expectation(for: playing, evaluatedWith: button)
        waitForExpectations(timeout: 10)
        button.click()
        XCTAssertEqual(button.label, "Play")
        app.typeKey("k", modifierFlags: [])
        expectation(for: playing, evaluatedWith: button)
        waitForExpectations(timeout: 5)
        app.typeKey("m", modifierFlags: [])
        XCTAssertEqual(app.buttons["mute"].label, "Unmute")
        // Pause to keep the controls visible while navigating.
        button.click()
        app.buttons["closeVideo"].click()
        XCTAssertFalse(app.buttons["playPause"].exists)
        XCTAssertTrue(app.windows.firstMatch.exists)
    }

    func testSubtitleTrackMenu() {
        app.buttons["playPause"].click()
        app.buttons["tracks"].click()
        XCTAssertTrue(app.staticTexts["Audio & Subtitles"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.popUpButtons["Subtitles"].exists)
        app.popUpButtons["Subtitles"].click()
        app.menuItems["Off"].click()
    }
}
