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

        let ex = expectation(description: "")
        URLSession.GET("http://example.com").asDictionary().then { rsp -> Void in
            XCTAssertEqual(json, rsp)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test2() {

        // test that URLDataPromise chains thens
        // this test because I don’t trust the Swift compiler

        let dummy = ("fred" as NSString).data(using: String.Encoding.utf8.rawValue)!

        OHHTTPStubs.stubRequestsPassingTest({ Bool($0.URL!.host == "example.com") }) { _ in
            return OHHTTPStubsResponse(data: dummy, statusCode: 200, headers: [:])
        }

        let ex = expectation(description: "")

        after(interval: 0.1).then {
            URLSession.GET("http://example.com")
        }.then { x -> Void in
            XCTAssertEqual(x, dummy)
        }.then(ex.fulfill)

        waitForExpectations(timeout: 1, handler: nil)
    }
}
