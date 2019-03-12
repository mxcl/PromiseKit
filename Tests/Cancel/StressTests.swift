@testable import PromiseKit
import Dispatch
import XCTest

class StressTests: XCTestCase {
    func testThenDataRace() {
        let e1 = expectation(description: "")
        let e2 = expectation(description: "")
        var errorCounter = 0

        //will crash if then doesn't protect handlers
        stressDataRace(expectation: e1, iterations: 1000, stressFunction: { promise in
            promise.done { s in
                XCTFail()
                XCTAssertEqual("ok", s)
                return
            }.catch(policy: .allErrors) {
                if !$0.isCancelled {
                    XCTFail()
                }
                errorCounter += 1
                if errorCounter == 1000 {
                    e2.fulfill()
                }
            }.cancel()
        }, fulfill: { "ok" })

        waitForExpectations(timeout: 10, handler: nil)
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testThensAreSequentialForLongTime() {
        var values = [Int]()
        let ex = expectation(description: "")
        var promise = cancellize(DispatchQueue.global().async(.promise){ 0 })
        let N = 1000
        for x in 1..<N {
            promise = promise.then { y -> CancellablePromise<Int> in
                values.append(y)
                XCTFail()
                return cancellize(DispatchQueue.global().async(.promise) { x })
            }
        }
        promise.done { x in
            values.append(x)
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testZalgoDataRace() {
        let e1 = expectation(description: "")
        let e2 = expectation(description: "")
        var errorCounter = 0

        //will crash if zalgo doesn't protect handlers
        stressDataRace(expectation: e1, iterations: 1000, stressFunction: { promise in
            promise.done(on: nil) { s in
                XCTAssertEqual("ok", s)
            }.catch(policy: .allErrors) {
                if !$0.isCancelled {
                    XCTFail()
                }
                errorCounter += 1
                if errorCounter == 1000 {
                    e2.fulfill()
                }
            }.cancel()
        }, fulfill: {
            return "ok"
        })

        waitForExpectations(timeout: 10, handler: nil)
    }
    
    class StressTask: CancellableTask {
        init() {
            isCancelled = true
        }
        
        func cancel() {
        }
        
        var isCancelled: Bool
    }
    
    func testCancelContextConcurrentReadWrite() {
        let e1 = expectation(description: "")
        let context = CancelContext()
        func consume(error: Swift.Error?) { }
        
        stressRace(expectation: e1, iterations: 1000, stressFactor: 1000, stressFunction: {
            consume(error: context.cancelledError)
        }, fulfillFunction: {
            context.cancel()
        })
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelContextConcurrentAppend() {
        let e1 = expectation(description: "")
        let context = CancelContext()
        let promise = CancellablePromise()
        let task = StressTask()
        
        stressRace(expectation: e1, iterations: 1000, stressFactor: 100, stressFunction: {
            context.append(task: task, reject: nil, thenable: promise)
        }, fulfillFunction: {
            context.append(task: task, reject: nil, thenable: promise)
        })
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testCancelContextConcurrentCancel() {
        let e1 = expectation(description: "")
        let context = CancelContext()
        let promise = CancellablePromise()
        let task = StressTask()
        
        stressRace(expectation: e1, iterations: 500, stressFactor: 10, stressFunction: {
            context.append(task: task, reject: nil, thenable: promise)
        }, fulfillFunction: {
            context.cancel()
        })
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}

private enum Error: Swift.Error {
    case Dummy
}

private func stressDataRace<T: Equatable>(expectation e1: XCTestExpectation, iterations: Int = 1000, stressFactor: Int = 10, stressFunction: @escaping (CancellablePromise<T>) -> Void, fulfill f: @escaping () -> T) {
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "the.domain.of.Zalgo", attributes: .concurrent)

    for _ in 0..<iterations {
        let (promise, seal) = CancellablePromise<T>.pending()

        DispatchQueue.concurrentPerform(iterations: stressFactor) { _ in
            stressFunction(promise)
        }

        queue.async(group: group) {
            seal.fulfill(f())
        }
    }

    group.notify(queue: queue, execute: e1.fulfill)
}

private func stressRace(expectation e1: XCTestExpectation, iterations: Int = 10000, stressFactor: Int = 1000, stressFunction: @escaping () -> Void, fulfillFunction: @escaping () -> Void) {
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "the.domain.of.Zalgo", attributes: .concurrent)
    
    for _ in 0..<iterations {
        DispatchQueue.concurrentPerform(iterations: stressFactor) { _ in
            _ = stressFunction()
        }
        
        queue.async(group: group) {
            fulfillFunction()
        }
    }
    
    group.notify(queue: queue, execute: e1.fulfill)
}
