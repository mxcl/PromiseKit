import XCTest

class UITest_SLComposeViewController_Swift: PMKiOSUITestCase {
    func test_can_cancel() {
        let app = XCUIApplication()
        app.tables.staticTexts["5"].tap()

        sleep(5) // takes longer than usual

        app.alerts.buttons["Cancel"].tap()

        sleep(3)  // takes longer than usual (this may only pass when you look at it)

        XCTAssertTrue(value)
    }
}
