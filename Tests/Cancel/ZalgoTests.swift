import XCTest
import PromiseKit

class ZalgoTests: XCTestCase {
    func test1() {
        var resolved = false
        cancellable(Promise.value(1)).done(on: nil) { _ in
            resolved = true
        }.catch(policy: .allErrors) { _ in
            resolved = false
        }.cancel()
        XCTAssertTrue(resolved)
    }

    func test2() {
        let p1 = cancellable(Promise.value(1)).map(on: nil) { _ in
            return 2
        }
        p1.cancel()
        XCTAssertEqual(p1.value!, 2)
        
        var x = 0
        
        let ex = expectation(description: "")
        let (p2, seal) = CancellablePromise<Int>.pending()
        p2.cancel()
        p2.done(on: nil) { _ in
            x = 1
        }.catch(policy: .allErrors) { _ in
            x = 2
            ex.fulfill()
        }
        XCTAssertEqual(x, 0)
        
        seal.fulfill(1)
        waitForExpectations(timeout: 1)
        XCTAssertEqual(x, 2)
    }

    // returning a pending promise from its own zalgo’d then handler doesn’t hang
    func test3Succeed() {
        let ex = (expectation(description: ""), expectation(description: ""))

        var p1: CancellablePromise<Void>!
        p1 = cancellable(after(.milliseconds(100))).then(on: nil) { _ -> CancellablePromise<Void> in
            p1.cancel()
            ex.0.fulfill()
            return p1
        }

        p1.catch(policy: .allErrors) { err in
            defer{ ex.1.fulfill() }
            guard case PMKError.returnedSelf = err else { return XCTFail() }
        }

        waitForExpectations(timeout: 1)
    }

    // returning a pending promise from its own zalgo’d then handler doesn’t hang
    func test3Cancel() {
        let ex = expectation(description: "")

        var p1: CancellablePromise<Void>!
        p1 = cancellable(after(.milliseconds(100))).then(on: nil) { _ -> CancellablePromise<Void> in
            XCTFail()
            return p1
        }
        p1.cancel()

        p1.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }

        waitForExpectations(timeout: 1)
    }

    // return a sealed promise from its own zalgo’d then handler doesn’t hang
    func test4() {
        let ex = expectation(description: "")
        let p1 = cancellable(Promise.value(1))
        p1.then(on: nil) { _ -> CancellablePromise<Int> in
            ex.fulfill()
            return p1
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        waitForExpectations(timeout: 1)
    }
}
