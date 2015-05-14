import PromiseKit
import StoreKit
import XCTest

class TestSKProductsRequest: XCTestCase {
    func test() {
        class MockProductsRequest: SKProductsRequest {
            override func start() {
                delegate?.productsRequest(self, didReceiveResponse: SKProductsResponse())
            }
        }

        let ex = expectationWithDescription("")
        MockProductsRequest().promise().then { _ in
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
