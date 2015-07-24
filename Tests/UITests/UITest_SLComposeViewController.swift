import XCTest

class TestSLComposeViewController_Swift: XCTestCase {

    var toggle: XCUIElement {
        // calling this ensures that any other ViewController has dismissed
        // as a side-effect since otherwise the switch won't be found
        return XCUIApplication().tables.switches.element
    }

    var value: Bool {
        return (toggle.value as! String) == "1"
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
        XCTAssertFalse(value)
    }

    func test_can_cancel() {
        let app = XCUIApplication()
        app.tables.staticTexts["5"].tap()
        app.alerts["No Facebook Account"].collectionViews.buttons["Cancel"].tap()

        sleep(3)  // takes longer than usual

        XCTAssertTrue(value)
    }
}
