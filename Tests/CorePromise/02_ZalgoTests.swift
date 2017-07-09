import XCTest
import PromiseKit

class ZalgoTests: XCTestCase {
    func test1() {
        var resolved = false
        Promise(value: 1).then(on: zalgo) { _ in
            resolved = true
        }
        XCTAssertTrue(resolved)
    }

    func test2() {
        let p1 = Promise(value: 1).then(on: zalgo) { x in
            return 2
        }
        XCTAssertEqual(p1.value!, 2)
        
        var x = 0
        
        let (p2, f, _) = Promise<Int>.pending()
        p2.then(on: zalgo) { _ in
            x = 1
        }
        XCTAssertEqual(x, 0)
        
        f(1)
        XCTAssertEqual(x, 1)
    }

    // returning a pending promise from its own zalgo’d then handler doesn’t hang
    func test3() {
        autoreleasepool {
            let ex = (expectation(description: ""), expectation(description: ""))

            InjectedErrorUnhandler = { err in
                ex.1.fulfill()
                guard case PMKError.returnedSelf = err else { return XCTFail() }
            }

            var p1: Promise<Void>!
            p1 = after(interval: .milliseconds(100)).then(on: zalgo) { _ -> Promise<Void> in
                ex.0.fulfill()
                return p1
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    // return a sealed promise from its own zalgo’d then handler doesn’t hang
    func test4() {
        let ex = expectation(description: "")
        let p1 = Promise(value: 1)
        p1.then(on: zalgo) { _ -> Promise<Int> in
            ex.fulfill()
            return p1
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
