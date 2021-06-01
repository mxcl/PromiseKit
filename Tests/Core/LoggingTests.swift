@testable import PromiseKit
import Dispatch
import XCTest

private extension LogEvent {
    var rawDescription: String {
        switch self {
            case .waitOnMainThread: return "waitOnMainThread"
            case .pendingPromiseDeallocated: return "pendingPromiseDeallocated"
            case .pendingGuaranteeDeallocated: return "pendingGuaranteeDeallocated"
            case .cauterized(let a): return "cauterized(\(a))"
            case .nilDispatchQueueWithFlags: return "nilDispatchQueueWithFlags"
            case .extraneousFlagsSpecified: return "extraneousFlagsSpecified"
        }
    }
}

class LoggingTests: XCTestCase {

    enum ForTesting: Error, CustomDebugStringConvertible {
        case purposes
        var debugDescription: String {
            return "purposes"
        }
    }

    var logOutput: String? = nil

    func captureLogger(_ event: LogEvent) {
        logOutput = event.rawDescription
    }

    /**
     The test should emit the following log messages:

     PromiseKit: warning: `wait()` called on main thread!
     PromiseKit: warning: pending promise deallocated
     PromiseKit: warning: pending guarantee deallocated
     PromiseKit:cauterized-error: purposes
    */
    func testLogging() {

        // Test Logging to Console, the default behavior
        conf.logHandler(.waitOnMainThread)
        conf.logHandler(.pendingPromiseDeallocated)
        conf.logHandler(.pendingGuaranteeDeallocated)
        conf.logHandler(.cauterized(ForTesting.purposes))
        XCTAssertNil(logOutput)

        // Now test no logging
        conf.logHandler = { event in }
        conf.logHandler(.waitOnMainThread)
        conf.logHandler(.pendingPromiseDeallocated)
        conf.logHandler(.cauterized(ForTesting.purposes))
        XCTAssertNil(logOutput)

        conf.logHandler = captureLogger
        conf.logHandler(.waitOnMainThread)
        XCTAssertEqual(logOutput!, "waitOnMainThread")
        logOutput = nil
        conf.logHandler(.pendingPromiseDeallocated)
        XCTAssertEqual(logOutput!, "pendingPromiseDeallocated")
        logOutput = nil
        conf.logHandler(.cauterized(ForTesting.purposes))
        XCTAssertEqual(logOutput!, "cauterized(purposes)")
    }

    // Verify waiting on main thread in Promise is logged
    func testPromiseWaitOnMainThreadLogged() throws {

        conf.logHandler = captureLogger
        let promiseResolver = Promise<String>.pending()
        let workQueue = DispatchQueue(label: "worker")
        workQueue.async {
            promiseResolver.resolver.fulfill ("PromiseFulfilled")
        }
        let promisedString = try promiseResolver.promise.wait()
        XCTAssertEqual("PromiseFulfilled", promisedString)
        XCTAssertEqual(logOutput!, "waitOnMainThread")
    }

    // Verify Promise.cauterize() is logged
    func testCauterizeIsLogged() {

        conf.logHandler = captureLogger
        func createPromise() -> Promise<String> {
            let promiseResolver = Promise<String>.pending()

            let queue = DispatchQueue(label: "workQueue")
            queue.async {
                promiseResolver.resolver.reject(ForTesting.purposes)
            }
            return promiseResolver.promise
        }
        var ex = expectation(description: "cauterize")
        firstly {
            createPromise()
        }.ensure {
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
        ex = expectation(description: "read")
        let readQueue = DispatchQueue(label: "readQueue")
        readQueue.async {
            var outputSet = false
            while !outputSet {
                if let logOutput = self.logOutput {
                    XCTAssertEqual(logOutput, "cauterized(purposes)")
                    outputSet = true
                    ex.fulfill()
                }
                if !outputSet {
                    usleep(10000)
                }
            }
        }
        waitForExpectations(timeout: 1)
    }

    // Verify waiting on main thread in Guarantee is logged
    func testGuaranteeWaitOnMainThreadLogged() {

        conf.logHandler = captureLogger
        let guaranteeResolve = Guarantee<String>.pending()
        let workQueue = DispatchQueue(label: "worker")
        workQueue.async {
            guaranteeResolve.resolve("GuaranteeFulfilled")
        }
        let guaranteedString = guaranteeResolve.guarantee.wait()
        XCTAssertEqual("GuaranteeFulfilled", guaranteedString)
        XCTAssertEqual(logOutput!, "waitOnMainThread")
    }

    // Verify pendingPromiseDeallocated is logged
    func testPendingPromiseDeallocatedIsLogged() {

        conf.logHandler = captureLogger
        do {
            let _ = Promise<Int>.pending()
        }
        XCTAssertEqual ("pendingPromiseDeallocated", logOutput!)
    }

    // Verify pendingGuaranteeDeallocated is logged
    func testPendingGuaranteeDeallocatedIsLogged() {
        var logOutput = ""
        conf.logHandler = { logOutput = $0.rawDescription }
        do {
            _ = Guarantee<Int>.pending()
        }
        XCTAssertEqual ("pendingGuaranteeDeallocated", logOutput)
    }

    // Verify nilDispatchQueueWithFlags is logged
    func testNilDispatchQueueWithFlags() {

        conf.logHandler = captureLogger
        Guarantee.value(42).done(on: nil, flags: .barrier) { _ in }
        XCTAssertEqual ("nilDispatchQueueWithFlags", logOutput!)
    }

    // Verify extraneousFlagsSpecified is logged
    func testExtraneousFlagsSpecified() {

        conf.logHandler = captureLogger
        conf.D.return = CurrentThreadDispatcher()
        Guarantee.value(42).done(flags: .barrier) { _ in }
        XCTAssertEqual ("extraneousFlagsSpecified", logOutput!)
    }

}
