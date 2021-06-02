#if !os(Linux)

import OHHTTPStubsSwift
import PMKFoundation
import OHHTTPStubs
import PromiseKit
import XCTest

class NSURLSessionTests: XCTestCase {
    func test1() {
        let json: NSDictionary = ["key1": "value1", "key2": ["value2A", "value2B"]]

        stub(condition: { $0.url!.host == "example.com" }) { _ in
            HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }

        let ex = expectation(description: "")
        let rq = URLRequest(url: URL(string: "http://example.com")!)
        firstly {
            URLSession.shared.dataTask(.promise, with: rq)
        }.compactMap {
            try JSONSerialization.jsonObject(with: $0.data) as? NSDictionary
        }.done { rsp in
            XCTAssertEqual(json, rsp)
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 5)
    }

    func test2() {

        // test that URLDataPromise chains thens
        // this test because I don’t trust the Swift compiler

        let dummy = ("fred" as NSString).data(using: String.Encoding.utf8.rawValue)!

        stub(condition: { $0.url!.host == "example.com" }) { _ in
            return HTTPStubsResponse(data: dummy, statusCode: 200, headers: [:])
        }

        let ex = expectation(description: "")
        let rq = URLRequest(url: URL(string: "http://example.com")!)

        after(.milliseconds(100)).then {
            URLSession.shared.dataTask(.promise, with: rq)
        }.done { x in
            XCTAssertEqual(x.data, dummy)
            ex.fulfill()
        }.cauterize()

        waitForExpectations(timeout: 5)
    }

    /// test that our convenience String constructor applies
    func test3() {
        let dummy = "fred"

        stub(condition: { $0.url!.host == "example.com" }) { _ in
            let data = dummy.data(using: .utf8)!
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [:])
        }

        let ex = expectation(description: "")
        let rq = URLRequest(url: URL(string: "http://example.com")!)

        after(.milliseconds(100)).then {
            URLSession.shared.dataTask(.promise, with: rq)
        }.map(String.init(data:urlResponse:)).done {
            XCTAssertEqual($0, dummy)
            ex.fulfill()
        }.cauterize()

        waitForExpectations(timeout: 5)
    }

    override func tearDown() {
        //OHHTTPStubs.removeAllStubs()
    }
}

#endif
