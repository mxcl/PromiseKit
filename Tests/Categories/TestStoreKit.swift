import PromiseKit
import StoreKit
import XCTest

class Test_SKProductsRequest_Swift: XCTestCase {
    func test() {
        class MockProductsRequest: SKProductsRequest {
            override func start() {
                after(0.1).then {
                    self.delegate?.productsRequest(self, didReceiveResponse: SKProductsResponse())
                }
            }
        }

        let ex = expectationWithDescription("")
        MockProductsRequest().promise().then { _ in
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCancellation() {
        class MockProductsRequest: SKProductsRequest {
            override func start() {
                after(0.1).then { _ -> Void in
                    let err = NSError(domain: SKErrorDomain, code: SKErrorPaymentCancelled, userInfo: nil)
                    self.delegate?.request?(self, didFailWithError: err)
                }
            }
        }

        let ex = expectationWithDescription("")
        MockProductsRequest().promise().error(policy: .AllErrors) { err in
            XCTAssert((err as NSError).cancelled)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
