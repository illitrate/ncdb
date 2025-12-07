// NCDB Accessibility Tests
// Tests for VoiceOver, Dynamic Type, and accessibility compliance

import XCTest

// MARK: - Accessibility Test Case

final class AccessibilityTests: XCTestCase {

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

    // MARK: - VoiceOver Navigation

    func test_movieList_allCellsAccessible() {
        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        // Check each visible cell has accessibility
        for cell in movieList.cells.allElementsBoundByIndex.prefix(5) {
            XCTAssertTrue(cell.isAccessibilityElement || cell.descendants(matching: .any).count > 0)
        }
    }

    func test_movieCard_hasAccessibilityLabel() {
        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        let firstCell = movieList.cells.firstMatch

        // Cell should have meaningful accessibility info
        let label = firstCell.label
        XCTAssertFalse(label.isEmpty, "Movie cell should have accessibility label")
    }

    func test_buttons_haveAccessibilityLabels() {
        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        movieList.cells.firstMatch.tap()

        // Check action buttons
        let watchButton = app.buttons["Mark as Watched"]
        if watchButton.exists {
            XCTAssertFalse(watchButton.label.isEmpty)
        }

        let favoriteButton = app.buttons["Add to Favorites"]
        if favoriteButton.exists {
            XCTAssertFalse(favoriteButton.label.isEmpty)
        }
    }

    func test_tabBar_buttonsAccessible() {
        let tabBar = app.tabBars.firstMatch

        // All tabs should be accessible
        XCTAssertTrue(tabBar.buttons["Movies"].exists)
        XCTAssertTrue(tabBar.buttons["Ranking"].exists)
        XCTAssertTrue(tabBar.buttons["News"].exists)
        XCTAssertTrue(tabBar.buttons["Profile"].exists)
    }

    // MARK: - Accessibility Traits

    func test_interactiveElements_haveButtonTrait() {
        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        movieList.cells.firstMatch.tap()

        // Action buttons should have button trait
        let watchButton = app.buttons["Mark as Watched"]
        if watchButton.exists {
            // XCUIElement doesn't expose traits directly,
            // but we can verify it's recognized as a button
            XCTAssertTrue(watchButton.elementType == .button)
        }
    }

    func test_images_haveAccessibleDescriptions() {
        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        movieList.cells.firstMatch.tap()

        // Poster image should have description
        let posterImage = app.images["posterImage"]
        if posterImage.exists {
            // Image should either have label or be hidden from accessibility
            let label = posterImage.label
            XCTAssertTrue(!label.isEmpty || !posterImage.isAccessibilityElement)
        }
    }

    // MARK: - Dynamic Type

    func test_movieList_adaptsToLargeText() {
        // Note: Dynamic Type testing requires launching with accessibility settings
        // This is a basic structure for the test

        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        // Verify content is visible and scrollable
        XCTAssertTrue(movieList.cells.firstMatch.isHittable)
    }

    func test_settings_textScales() {
        app.tabBars.buttons["Profile"].tap()
        app.buttons["Settings"].tap()

        // Settings should remain usable with large text
        XCTAssertTrue(app.navigationBars["Settings"].exists)

        // All settings options should be visible/scrollable
        let settingsList = app.tables.firstMatch
        XCTAssertTrue(settingsList.exists)
    }

    // MARK: - Color Contrast

    func test_buttons_visibleInBothModes() {
        // This test verifies buttons exist and are hittable
        // Actual color contrast testing requires visual inspection
        // or specialized accessibility audit tools

        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        movieList.cells.firstMatch.tap()

        // Primary action buttons should be hittable
        let watchButton = app.buttons["Mark as Watched"]
        if watchButton.exists {
            XCTAssertTrue(watchButton.isHittable)
        }
    }

    // MARK: - Focus Order

    func test_movieDetail_logicalFocusOrder() {
        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        movieList.cells.firstMatch.tap()

        // Collect accessible elements in order
        let accessibleElements = app.descendants(matching: .any)
            .allElementsBoundByIndex
            .filter { $0.isAccessibilityElement }

        // First accessible element should be navigation/back button
        // Following elements should be in logical reading order
        XCTAssertGreaterThan(accessibleElements.count, 0)
    }

    // MARK: - Reduce Motion

    func test_appFunctions_withReduceMotion() {
        // Note: Testing reduce motion requires system settings change
        // This verifies core functionality works regardless

        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        // Core functionality should work
        movieList.cells.firstMatch.tap()
        XCTAssertTrue(app.navigationBars.buttons["Back"].exists)

        app.navigationBars.buttons["Back"].tap()
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))
    }

    // MARK: - Screen Reader Announcements

    func test_watchToggle_announcesStateChange() {
        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        movieList.cells.firstMatch.tap()

        let watchButton = app.buttons["Mark as Watched"]
        if watchButton.exists {
            watchButton.tap()

            // Button label should change to reflect new state
            let watchedButton = app.buttons["Watched"]
            XCTAssertTrue(watchedButton.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Minimum Touch Target

    func test_buttons_meetMinimumTouchTarget() {
        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 5))

        movieList.cells.firstMatch.tap()

        // Check button sizes (44x44 minimum)
        let watchButton = app.buttons["Mark as Watched"]
        if watchButton.exists {
            let frame = watchButton.frame
            // Note: Actual size may be larger due to padding
            XCTAssertGreaterThanOrEqual(frame.width, 44)
            XCTAssertGreaterThanOrEqual(frame.height, 44)
        }
    }

    // MARK: - Accessibility Audit

    func test_performAccessibilityAudit() throws {
        // iOS 17+ accessibility audit API
        if #available(iOS 17.0, *) {
            app.tabBars.buttons["Movies"].tap()

            let movieList = app.collectionViews["movieList"]
            XCTAssertTrue(movieList.waitForExistence(timeout: 5))

            // Perform accessibility audit
            try app.performAccessibilityAudit()
        }
    }

    func test_profileScreen_accessibilityAudit() throws {
        if #available(iOS 17.0, *) {
            app.tabBars.buttons["Profile"].tap()

            // Allow time for content to load
            sleep(1)

            // Audit with specific checks
            try app.performAccessibilityAudit(for: [
                .dynamicType,
                .contrast,
                .hitRegion
            ])
        }
    }
}

// MARK: - Accessibility Audit Extension

@available(iOS 17.0, *)
extension XCUIApplication {
    /// Perform accessibility audit and collect results
    func performAccessibilityAudit(
        for auditTypes: Set<XCUIAccessibilityAuditType> = .all
    ) throws {
        try self.performAccessibilityAudit(for: auditTypes) { issue in
            // Log issue details
            print("Accessibility Issue: \(issue.auditType) - \(issue.description)")

            // Return true to fail test on this issue, false to ignore
            // Some issues may be acceptable based on design decisions
            switch issue.auditType {
            case .contrast:
                // Fail on contrast issues
                return true
            case .hitRegion:
                // Fail on touch target issues
                return true
            default:
                // Log but don't fail on other issues
                return false
            }
        }
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    /// Check if element is announced by VoiceOver
    var isAnnouncedByVoiceOver: Bool {
        isAccessibilityElement && !label.isEmpty
    }
}
