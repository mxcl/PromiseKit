import PromiseKit
import StoreKit
import XCTest

class Test_SKProductsRequest_Swift: XCTestCase {
    func test() {
        class MockProductsRequest: SKProductsRequest {
            override func start() {
                after(0.1).then {
                    self.delegate?.productsRequest(self, didReceive: SKProductsResponse())
                }
            }
        }

        let ex = expectation(withDescription: "")
        MockProductsRequest().promise().then { _ in
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testCancellation() {
        class MockProductsRequest: SKProductsRequest {
            override func start() {
                after(0.1).then { _ -> Void in
                    let err = NSError(domain: SKErrorDomain, code: SKErrorCode.paymentCancelled.rawValue, userInfo: nil)
                    self.delegate?.request?(self, didFailWithError: err)
                }
            }
        }

        let ex = expectation(withDescription: "")
        MockProductsRequest().promise().error(policy: .allErrors) { err in
            XCTAssert((err as NSError).cancelled)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
}
