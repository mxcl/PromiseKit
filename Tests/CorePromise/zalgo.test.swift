import XCTest
import PromiseKit

class ZalgoTestCase_Swift: XCTestCase {
    func test1() {
        var resolved = false
        Promise(1).then(on: zalgo) { _ in
            resolved = true
        }
        XCTAssertTrue(resolved)
    }

    func test2() {
        let p1 = Promise(1).then(on: zalgo) { x in
            return 2
        }
        XCTAssertEqual(p1.value!, 2)
        
        var x = 0
        
        let (p2, f, _) = Promise<Int>.pendingPromise()
        p2.then(on: zalgo) { _ in
            x = 1
        }
        XCTAssertEqual(x, 0)
        
        f(1)
        XCTAssertEqual(x, 1)
    }

    // returning a pending promise from its own zalgo’d then handler doesn’t hang
    func test3() {
        let ex = expectation(withDescription: "")
        var p1: Promise<Void>!
        p1 = after(0.1).then(on: zalgo) { _ -> Promise<Void> in
            ex.fulfill()
            return p1
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    // return a sealed promise from its own zalgo’d then handler doesn’t hang
    func test4() {
        let ex = expectation(withDescription: "")
        let p1 = Promise(1)
        p1.then(on: zalgo) { _ -> Promise<Int> in
            ex.fulfill()
            return p1
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testZalgoDataRace() {
        let e1 = expectation(withDescription: "")

        //will crash if zalgo doesn't protect handlers
        stressDataRace(e1, stressFunction: { promise in
            promise.then(on: zalgo) { s -> Void in
                XCTAssertEqual("ok", s)
                return
            }
        }, fulfill: {
            return "ok"
        })
        
        waitForExpectations(withTimeout: 10, handler: nil)
    }

}


func stressDataRace<T: Equatable>(_ e1: XCTestExpectation, iterations: Int = 1000, stressFactor: Int = 10, stressFunction: (Promise<T>) -> Void, fulfill f: () -> T) {
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "the.domain.of.Zalgo", attributes: .concurrent)

    for _ in 0..<iterations {
        let (promise, fulfill, _) = Promise<T>.pendingPromise()

        DispatchQueue.concurrentPerform(iterations: stressFactor) { n in
            stressFunction(promise)
        }

        queue.async(group: group) {
            fulfill(f())
        }
    }

    group.notify(queue: queue) {
        e1.fulfill()
    }
}
