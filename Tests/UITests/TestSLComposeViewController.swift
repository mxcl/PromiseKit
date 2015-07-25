import XCTest

class UITest_SLComposeViewController_Swift: PMKiOSUITestCase {
    func test_can_cancel() {
        let app = XCUIApplication()
        app.tables.staticTexts["5"].tap()
        app.alerts["No Facebook Account"].collectionViews.buttons["Cancel"].tap()

        sleep(3)  // takes longer than usual

        XCTAssertTrue(value)
    }
}
