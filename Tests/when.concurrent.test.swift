import XCTest
import PromiseKit

class WhenConcurrentTestCase_Swift: XCTestCase {

    func testWhen() {
        let e = expectationWithDescription("")

        let numbers = (0..<42).generate()
        let squareNumbers = numbers.map { $0 * $0 }

        var index = 0
        let maxIndex = 42

        let generator = AnyGenerator<Promise<Int>> {
            guard number = numbers.next() else {
                return nil
            }

            return after(0.01).then {
                return number * number
            }
        }

        when(generator, concurrently: 5)
            .then { numbers -> Void in
                if numbers == squareNumbers {
                    e.fulfill()
                }
            }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

}
