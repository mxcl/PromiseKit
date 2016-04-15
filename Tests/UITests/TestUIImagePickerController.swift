import PromiseKit
import UIKit
import XCTest

class UITest_UIImagePickerController_Swift: PMKiOSUITestCase {
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
        app.collectionViews.childrenMatchingType(.Cell).matchingIdentifier("Photo, Landscape, August 08, 2012, 9:52 AM").elementBoundByIndex(0).tap()
        app.windows.childrenMatchingType(.Other).element.tap()

        XCTAssertTrue(value)
    }
#endif

    func test_fulfills_with_image() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["3"].tap()
        tablesQuery.childrenMatchingType(.Cell).elementBoundByIndex(0).tap()
        app.collectionViews.childrenMatchingType(.Cell).matchingPredicate(NSPredicate(format: "SELF.label BEGINSWITH %@", argumentArray: ["Photo, Landscape, August 08, 2012"])).elementBoundByIndex(0).tap()

        XCTAssertTrue(value)
    }

    func test_fulfills_with_data() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["4"].tap()
        tablesQuery.buttons["Moments"].tap()
        app.collectionViews.childrenMatchingType(.Cell).matchingPredicate(NSPredicate(format: "SELF.label BEGINSWITH %@", argumentArray: ["Photo, Landscape, August 08, 2012"])).elementBoundByIndex(0).tap()

        XCTAssertTrue(value)
    }
}
