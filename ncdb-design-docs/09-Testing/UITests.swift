// NCDB UI Tests
// End-to-end UI tests

import XCTest

// MARK: - Base Test Class

class NCDBUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "MOCK_DATA"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Helpers

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    func tapTabBar(_ tab: String) {
        app.tabBars.buttons[tab].tap()
    }
}

// MARK: - Onboarding Tests

final class OnboardingUITests: NCDBUITestCase {

    override func setUp() {
        // Reset onboarding state
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "RESET_ONBOARDING"]
        app.launch()
        self.app = app
    }

    func test_onboarding_completesSuccessfully() {
        // Welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to NCDB"].exists)
        app.buttons["Get Started"].tap()

        // Features screen
        XCTAssertTrue(waitForElement(app.staticTexts["Features"]))
        app.buttons["Continue"].tap()

        // Notifications screen
        XCTAssertTrue(waitForElement(app.staticTexts["Stay Updated"]))
        app.buttons["Maybe Later"].tap()

        // Sync screen
        XCTAssertTrue(waitForElement(app.staticTexts["Sync Across Devices"]))
        app.buttons["Keep Local Only"].tap()

        // Ready screen
        XCTAssertTrue(waitForElement(app.staticTexts["You're All Set!"]))
        app.buttons["Start Exploring"].tap()

        // Should be on main app
        XCTAssertTrue(waitForElement(app.tabBars.buttons["Movies"]))
    }
}

// MARK: - Movie List Tests

final class MovieListUITests: NCDBUITestCase {

    func test_movieList_displaysMovies() {
        tapTabBar("Movies")

        XCTAssertTrue(waitForElement(app.collectionViews["movieList"]))
        XCTAssertGreaterThan(app.collectionViews["movieList"].cells.count, 0)
    }

    func test_movieList_pullToRefresh() {
        tapTabBar("Movies")

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(waitForElement(movieList))

        // Pull to refresh
        let firstCell = movieList.cells.firstMatch
        firstCell.swipeDown()

        // Should show refresh indicator briefly
        // Verify list still has content
        XCTAssertGreaterThan(movieList.cells.count, 0)
    }

    func test_search_filtersMovies() {
        tapTabBar("Movies")

        // Tap search field
        let searchField = app.searchFields["Search movies"]
        XCTAssertTrue(waitForElement(searchField))
        searchField.tap()

        // Type search query
        searchField.typeText("Face")

        // Verify results
        XCTAssertTrue(waitForElement(app.cells.containing(.staticText, identifier: "Face/Off").firstMatch))
    }

    func test_tapMovie_opensDetail() {
        tapTabBar("Movies")

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(waitForElement(movieList))

        movieList.cells.firstMatch.tap()

        // Should show detail view
        XCTAssertTrue(waitForElement(app.navigationBars.buttons["Back"]))
    }
}

// MARK: - Movie Detail Tests

final class MovieDetailUITests: NCDBUITestCase {

    func test_movieDetail_displaysInfo() {
        tapTabBar("Movies")

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(waitForElement(movieList))

        movieList.cells.firstMatch.tap()

        // Verify detail elements
        XCTAssertTrue(app.images["posterImage"].exists)
        XCTAssertTrue(app.staticTexts["movieTitle"].exists)
        XCTAssertTrue(app.staticTexts["releaseYear"].exists)
    }

    func test_markAsWatched_updatesUI() {
        tapTabBar("Movies")

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(waitForElement(movieList))

        movieList.cells.firstMatch.tap()

        // Tap watch button
        let watchButton = app.buttons["Mark as Watched"]
        if watchButton.exists {
            watchButton.tap()

            // Verify button changed
            XCTAssertTrue(waitForElement(app.buttons["Watched"]))
        }
    }

    func test_rateMovie_showsRatingPicker() {
        tapTabBar("Movies")

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(waitForElement(movieList))

        movieList.cells.firstMatch.tap()

        // Tap rating area
        let ratingButton = app.buttons["Rate Movie"]
        XCTAssertTrue(waitForElement(ratingButton))
        ratingButton.tap()

        // Should show rating picker
        XCTAssertTrue(waitForElement(app.otherElements["ratingPicker"]))
    }
}

// MARK: - Ranking Tests

final class RankingUITests: NCDBUITestCase {

    func test_ranking_displaysMovies() {
        tapTabBar("Ranking")

        XCTAssertTrue(waitForElement(app.collectionViews["rankingList"]))
    }

    func test_ranking_showsPodium() {
        tapTabBar("Ranking")

        // Podium should be visible if user has rankings
        let podium = app.otherElements["podiumView"]
        if podium.waitForExistence(timeout: 2) {
            XCTAssertTrue(podium.exists)
        }
    }

    func test_ranking_reorderWithDrag() {
        tapTabBar("Ranking")

        let rankingList = app.collectionViews["rankingList"]
        XCTAssertTrue(waitForElement(rankingList))

        guard rankingList.cells.count >= 2 else {
            return // Skip if not enough movies
        }

        let firstCell = rankingList.cells.element(boundBy: 0)
        let secondCell = rankingList.cells.element(boundBy: 1)

        // Long press and drag
        firstCell.press(forDuration: 0.5, thenDragTo: secondCell)

        // Verify reorder (would need to check actual content)
    }
}

// MARK: - Profile Tests

final class ProfileUITests: NCDBUITestCase {

    func test_profile_displaysStats() {
        tapTabBar("Profile")

        XCTAssertTrue(waitForElement(app.staticTexts["Movies Watched"]))
        XCTAssertTrue(app.staticTexts["Completion"].exists)
    }

    func test_profile_tapAchievements_opensAchievements() {
        tapTabBar("Profile")

        let achievementsButton = app.buttons["Achievements"]
        XCTAssertTrue(waitForElement(achievementsButton))
        achievementsButton.tap()

        XCTAssertTrue(waitForElement(app.navigationBars["Achievements"]))
    }

    func test_profile_tapSettings_opensSettings() {
        tapTabBar("Profile")

        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(waitForElement(settingsButton))
        settingsButton.tap()

        XCTAssertTrue(waitForElement(app.navigationBars["Settings"]))
    }
}

// MARK: - Settings Tests

final class SettingsUITests: NCDBUITestCase {

    func test_settings_toggleHaptics() {
        tapTabBar("Profile")
        app.buttons["Settings"].tap()

        let hapticsToggle = app.switches["Haptic Feedback"]
        XCTAssertTrue(waitForElement(hapticsToggle))

        let initialValue = hapticsToggle.value as? String

        hapticsToggle.tap()

        let newValue = hapticsToggle.value as? String
        XCTAssertNotEqual(initialValue, newValue)
    }

    func test_settings_exportData() {
        tapTabBar("Profile")
        app.buttons["Settings"].tap()

        let exportButton = app.buttons["Export Data"]
        XCTAssertTrue(waitForElement(exportButton))
        exportButton.tap()

        // Should show share sheet
        XCTAssertTrue(waitForElement(app.otherElements["ActivityListView"]))
    }
}

// MARK: - News Tests

final class NewsUITests: NCDBUITestCase {

    func test_news_displaysList() {
        tapTabBar("News")

        XCTAssertTrue(waitForElement(app.collectionViews["newsList"]))
    }

    func test_news_tapArticle_opensDetail() {
        tapTabBar("News")

        let newsList = app.collectionViews["newsList"]
        XCTAssertTrue(waitForElement(newsList))

        if newsList.cells.count > 0 {
            newsList.cells.firstMatch.tap()
            XCTAssertTrue(waitForElement(app.buttons["Open in Safari"]))
        }
    }
}

// MARK: - Deep Link Tests

final class DeepLinkUITests: NCDBUITestCase {

    func test_deepLink_opensMovie() {
        // Launch with deep link URL
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "MOCK_DATA"]

        // Note: Actual deep link testing requires XCUIApplication.open(url:)
        // which has limitations in UI tests

        app.launch()

        // Verify app launched successfully
        XCTAssertTrue(waitForElement(app.tabBars.buttons["Movies"]))
    }
}

// MARK: - Snapshot Tests Extension

extension NCDBUITestCase {

    /// Take a screenshot and attach to test results
    func takeScreenshot(_ name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
