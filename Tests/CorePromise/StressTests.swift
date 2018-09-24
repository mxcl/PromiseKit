import PromiseKit
import Dispatch
import XCTest

class StressTests: XCTestCase {
    func testThenDataRace() {
        let e1 = expectation(description: "")

        //will crash if then doesn't protect handlers
        stressDataRace(expectation: e1, stressFunction: { promise in
            promise.done { s in
                XCTAssertEqual("ok", s)
                return
            }.silenceWarning()
        }, fulfill: { "ok" })

        waitForExpectations(timeout: 10, handler: nil)
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testThensAreSequentialForLongTime() {
        var values = [Int]()
        let ex = expectation(description: "")
        var promise = DispatchQueue.global().async(.promise){ 0 }
        let N = 1000
        for x in 1..<N {
            promise = promise.then { y -> Guarantee<Int> in
                values.append(y)
                XCTAssertEqual(x - 1, y)
                return DispatchQueue.global().async(.promise) { x }
            }
        }
        promise.done { x in
            values.append(x)
            XCTAssertEqual(values, (0..<N).map{ $0 })
            ex.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testZalgoDataRace() {
        let e1 = expectation(description: "")

        //will crash if zalgo doesn't protect handlers
        stressDataRace(expectation: e1, stressFunction: { promise in
            promise.done(on: nil) { s in
                XCTAssertEqual("ok", s)
            }.silenceWarning()
        }, fulfill: {
            return "ok"
        })

        waitForExpectations(timeout: 10, handler: nil)
    }
}

private enum Error: Swift.Error {
    case Dummy
}

private func stressDataRace<T: Equatable>(expectation e1: XCTestExpectation, iterations: Int = 1000, stressFactor: Int = 10, stressFunction: @escaping (Promise<T>) -> Void, fulfill f: @escaping () -> T) {
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "the.domain.of.Zalgo", attributes: .concurrent)

    for _ in 0..<iterations {
        let (promise, seal) = Promise<T>.pending()

        DispatchQueue.concurrentPerform(iterations: stressFactor) { n in
            stressFunction(promise)
        }

        queue.async(group: group) {
            seal.fulfill(f())
        }
    }

    group.notify(queue: queue, execute: e1.fulfill)
}
