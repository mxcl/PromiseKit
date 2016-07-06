import XCTest

class UITest_UIImagePickerController_Swift: PMKiOSUITestCase {
    func test_rejects_when_cancelled() {
        let app = XCUIApplication()
        let table = app.tables
        table.cells.staticTexts["1"].tap()
        table.cells.element(boundBy: 0).tap()
        app.navigationBars["Moments"].buttons["Cancel"].tap()

        XCTAssertTrue(value)
    }

#if false
    func test_fulfills_with_edited_image() {
        let app = XCUIApplication()
        app.tables.cells.staticTexts["2"].tap()
        app.tables.children(matching: .cell).element(boundBy: 1).tap()
        app.collectionViews.children(matching: .cell).element(boundBy: 0).tap()

        // XCUITesting fails to tap this button, hence this test disabled
        app.children(matching: .window).element(boundBy: 0).buttons["Choose"].forceTap()

        XCTAssertTrue(value)
    }
#endif

    func test_fulfills_with_image() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["3"].tap()
        tablesQuery.children(matching: .cell).element(boundBy: 1).tap()
        app.collectionViews.children(matching: .cell).element(boundBy: 0).tap()

        XCTAssertTrue(value)
    }

    func test_fulfills_with_data() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["4"].tap()
        tablesQuery.children(matching: .cell).element(boundBy: 1).tap()
        app.collectionViews.children(matching: .cell).element(boundBy: 0).tap()

        XCTAssertTrue(value)
    }
}


extension XCUIElement {
    func forceTap() {
        if self.isHittable {
            self.tap()
        }
        else {
            let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            coordinate.tap()
        }
    }
}
