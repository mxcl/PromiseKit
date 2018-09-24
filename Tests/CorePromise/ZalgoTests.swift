import XCTest
import PromiseKit

class ZalgoTests: XCTestCase {
    func test1() {
        var resolved = false
        Promise.value(1).done(on: nil) { _ in
            resolved = true
        }.silenceWarning()
        XCTAssertTrue(resolved)
    }

    func test2() {
        let p1 = Promise.value(1).map(on: nil) { x in
            return 2
        }
        XCTAssertEqual(p1.value!, 2)
        
        var x = 0
        
        let (p2, seal) = Promise<Int>.pending()
        p2.done(on: nil) { _ in
            x = 1
        }.silenceWarning()
        XCTAssertEqual(x, 0)
        
        seal.fulfill(1)
        XCTAssertEqual(x, 1)
    }

    // returning a pending promise from its own zalgo’d then handler doesn’t hang
    func test3() {
        let ex = (expectation(description: ""), expectation(description: ""))

        var p1: Promise<Void>!
        p1 = after(.milliseconds(100)).then(on: nil) { _ -> Promise<Void> in
            ex.0.fulfill()
            return p1
        }

        p1.catch { err in
            defer{ ex.1.fulfill() }
            guard case PMKError.returnedSelf = err else { return XCTFail() }
        }

        waitForExpectations(timeout: 1)
    }

    // return a sealed promise from its own zalgo’d then handler doesn’t hang
    func test4() {
        let ex = expectation(description: "")
        let p1 = Promise.value(1)
        p1.then(on: nil) { _ -> Promise<Int> in
            ex.fulfill()
            return p1
        }.silenceWarning()
        waitForExpectations(timeout: 1)
    }
}
