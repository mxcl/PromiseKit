import PromiseKit
import Social
import XCTest

class Test_SLRequest_Swift: XCTestCase {
    func testSLRequest() {
        // I tried to just override SLRequest, but Swift wouldn't let me
        // then use the long initializer, and an exception is thrown inside
        // init()

        swizzle(SLRequest.self, #selector(SLRequest.perform(handler:))) {
            let url = URL(string: "https://api.twitter.com/1.1/statuses/user_timeline.json")
            let params = ["foo": "bar"]
            let rq = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, url: url, parameters: params)!

            let ex = expectation(description: "")
            rq.promise().then { x -> Void in
                XCTAssertEqual(x, NSData())
                ex.fulfill()
            }
            waitForExpectations(timeout: 1, handler: nil)
        }
    }
}

extension SLRequest {
    @objc private func pmk_performRequestWithHandler(_ handler: SLRequestHandler) {
        after(interval: 0.0).then { _ -> Void in
            let rsp = HTTPURLResponse(url: URL(string: "http://example.com")!, statusCode: 200, httpVersion: "2.0", headerFields: [:])
            handler(Data(), rsp, nil)
        }
    }
}
