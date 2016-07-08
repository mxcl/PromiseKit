import OHHTTPStubs
import Foundation
import PromiseKit
import XCTest

class Test_NSURLConnection_Swift: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
    }

    func test1() {
        let json = ["key1": "value1", "key2": ["value2A", "value2B"]]

        OHHTTPStubs.stubRequestsPassingTest({ Bool($0.URL!.host == "example.com") }) { _ in
            return OHHTTPStubsResponse(JSONObject: json, statusCode: 200, headers: nil)
        }

        let ex = expectation(description: "")
        NSURLConnection.GET("http://example.com").asDictionary().then { rsp -> Void in
            XCTAssertEqual(json, rsp)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
