import PromiseKit
import UIKit
import XCTest

class UITest_UIImagePickerController_Swift: XCTestCase {

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

    func test_rejects_when_cancelled() {
        let app = XCUIApplication()
        let table = app.tables
        table.cells.staticTexts["1"].tap()
        table.cells.elementBoundByIndex(0).tap()
        app.navigationBars["Moments"].buttons["Cancel"].tap()

        XCTAssertTrue(value)
    }

#if false   // XCUITesting doesn’t tap the Choose button :/
    func test_fulfills_with_edited_image() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["2"].tap()
        tablesQuery.buttons["Moments"].tap()
        app.collectionViews.cells["Photo, Landscape, March 12, 2011, 4:17 PM"].tap()
        app.windows.childrenMatchingType(.Other).element.tap()

        XCTAssertTrue(value)
    }
#endif

    func test_fulfills_with_image() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["3"].tap()
        tablesQuery.buttons["Moments"].tap()
        app.collectionViews.cells["Photo, Landscape, March 12, 2011, 4:17 PM"].tap()

        XCTAssertTrue(value)
    }

    func test_fulfills_with_data() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["4"].tap()
        tablesQuery.buttons["Moments"].tap()
        app.collectionViews.cells["Photo, Landscape, March 12, 2011, 4:17 PM"].tap()

        XCTAssertTrue(value)
    }
}
