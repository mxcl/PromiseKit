import Foundation
import OHHTTPStubs
import PromiseKit
import XCTest

class TestNSURLConnection: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
    }

    func test1() {
        let json = ["key1": "value1", "key2": ["value2A", "value2B"]]

        OHHTTPStubs.stubRequestsPassingTest({ ObjCBool($0.URL!.host == "example.com") }) { _ in
            return OHHTTPStubsResponse(JSONObject: json, statusCode: 200, headers: nil)
        }

        let ex = expectationWithDescription("")
        NSURLConnection.GET("http://example.com").then { (rsp: NSDictionary) -> Void in
            XCTAssertEqual(json, rsp)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
