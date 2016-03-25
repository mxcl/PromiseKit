import PromiseKit
import Social
import XCTest

class Test_SLRequest_Swift: XCTestCase {
    func testSLRequest() {
        // I tried to just override SLRequest, but Swift wouldn't let me
        // then use the long initializer, and an exception is thrown inside
        // init()

        swizzle(SLRequest.self, #selector(SLRequest.performRequestWithHandler(_:))) {
            let url = NSURL(string: "https://api.twitter.com/1.1/statuses/user_timeline.json")
            let params = ["foo": "bar"]
            let rq = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.GET, URL: url, parameters: params)

            let ex = expectationWithDescription("")
            rq.promise().then { x -> Void in
                XCTAssertEqual(x, NSData())
                ex.fulfill()
            }
            waitForExpectationsWithTimeout(1, handler: nil)
        }
    }
}

extension SLRequest {
    @objc private func pmk_performRequestWithHandler(handler: SLRequestHandler) {
        after(0.0).then { _ -> Void in
            let rsp = NSHTTPURLResponse(URL: NSURL(string: "http://example.com")!, statusCode: 200, HTTPVersion: "2.0", headerFields: [:])
            handler(NSData(), rsp, nil)
        }
    }
}
