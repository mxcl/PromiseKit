import XCTest

class PMKiOSUITestCase: XCTestCase {

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
}
