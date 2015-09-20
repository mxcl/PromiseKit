import OHHTTPStubs
import PromiseKit
import XCTest

class Test_NSURLSession_Swift: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
    }

    func test1() {
        let json = ["key1": "value1", "key2": ["value2A", "value2B"]]

        OHHTTPStubs.stubRequestsPassingTest({ Bool($0.URL!.host == "example.com") }) { _ in
            return OHHTTPStubsResponse(JSONObject: json, statusCode: 200, headers: nil)
        }

        let ex = expectationWithDescription("")
        NSURLSession.GET("http://example.com").asDictionary().then { rsp -> Void in
            XCTAssertEqual(json, rsp)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2() {

        // test that URLDataPromise chains thens
        // this test because I don’t trust the Swift compiler

        let dummy = ("fred" as NSString).dataUsingEncoding(NSUTF8StringEncoding)!

        OHHTTPStubs.stubRequestsPassingTest({ Bool($0.URL!.host == "example.com") }) { _ in
            return OHHTTPStubsResponse(data: dummy, statusCode: 200, headers: [:])
        }

        let ex = expectationWithDescription("")

        after(0.1).then {
            NSURLSession.GET("http://example.com")
        }.then { x -> Void in
            XCTAssertEqual(x, dummy)
        }.then(ex.fulfill)

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
