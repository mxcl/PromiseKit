import WatchConnectivity
import Foundation
import PromiseKit
import XCTest

import Foundation

@available(iOS 9.0, *)
@available(iOSApplicationExtension 9.0, *)
class Test_WatchConnectivity_Swift: XCTestCase {
    class MockSession: WCSession {

        var fail = false

        override func sendMessage(message: [String : AnyObject], replyHandler: (([String : AnyObject]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
            if fail {
                errorHandler?(NSError(domain: "Test", code: 1, userInfo: [:]))
            } else {
                replyHandler?(["response": "Success"])
            }
        }
    }

    func testSuccess() {

        let ex = expectationWithDescription("Success callback")
        let session = MockSession.defaultSession() as! MockSession
        session.fail = false
        session.sendMessage(["message": "test"]).then { response -> () in
            XCTAssertEqual(response as! [String: String], ["response": "Success"])
            ex.fulfill()
        }.error { _ in
            XCTFail("Should not fail")
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testFailure() {
        class MockFailSession: WCSession {
            private override func sendMessage(message: [String : AnyObject], replyHandler: (([String : AnyObject]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
                errorHandler?(NSError(domain: "Test", code: 1, userInfo: [:]))
            }
        }

        let ex = expectationWithDescription("Error callback")
        let session = MockSession.defaultSession() as! MockSession
        session.fail = true
        session.sendMessage(["message": "test"]).then { response -> () in
            XCTFail("Should not succeed")
        }.error { error in
            XCTAssertEqual((error as NSError).domain, "Test")
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
