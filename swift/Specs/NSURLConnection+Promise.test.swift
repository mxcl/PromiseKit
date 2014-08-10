import XCTest
import PromiseKit


class TestNSURLConnectionPlusPromise: XCTestCase {

    func resource(fn: String, ext: String = "json") -> NSURLRequest {
        let url = NSBundle(forClass:self.classForCoder).pathForResource(fn, ofType:ext);
        return NSURLRequest(URL:NSURL(string:"file://\(url)"))
    }

    var plainText: NSURLRequest { return resource("plain", ext: "text") }
    var dictionaryJSON: NSURLRequest { return resource("dictionary") }
    var arrayJSON: NSURLRequest { return resource("array") }


    func test_001() {
        let e1 = expectation()
        NSURLConnection.promise(dictionaryJSON).then { (json:NSDictionary) -> Int in
            let hi = json["data"]! as String
            XCTAssertEqual(hi as String, "hi")
            return 1
        }.catch { _->Int in
            return 3
        }.then { (value:Int) -> Void in
            XCTAssertEqual(value, 1)
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCorrectlyErrorsWhenExpectingDictionaryAndGettingText() {
        let e1 = expectation()
        NSURLConnection.promise(plainText).then { (json:NSDictionary) -> Int in
            XCTFail()
            return 1
        }.catch { (err:NSError) -> Int in
            XCTAssertEqual(err.domain, NSCocoaErrorDomain!)
            XCTAssertEqual(err.code, 3840)
            return 1234
        }.then { (value:Int) -> Void in
            XCTAssertEqual(value, 1234)
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCorrectlyErrorsWhenExpectingArrayAndGettingDictionary() {
        let e1 = expectation()
        NSURLConnection.promise(dictionaryJSON).then { (json:NSArray) -> Int in
            XCTFail()
            return 1
        }.catch { (err:NSError) -> Int in
            XCTAssertEqual(err.domain, PMKErrorDomain)
            XCTAssertEqual(err.code, PMKJSONError)
            XCTAssertEqual(err.userInfo[PMKJSONErrorJSONObjectKey] as NSDictionary, ["data": "hi"])
            return 1234
        }.then { (value:Int) -> Void in
            XCTAssertEqual(value, 1234)
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testParsesJSONArray() {
        let e1 = expectation()
        NSURLConnection.promise(arrayJSON).then { (json:NSArray) -> Int in
            let hi = json[1] as String
            XCTAssertEqual(hi as String, "hi")
            e1.fulfill()
            return 1
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testParsesString() {
        let e1 = expectation()
        NSURLConnection.promise(plainText).then{ (txt:String) in
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
