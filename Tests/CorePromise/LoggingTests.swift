@testable import PromiseKit
import Dispatch
import XCTest

class LoggingTests: XCTestCase {

/**
     
     // Verify LoggingPolicy directs output correctly
     
     The test should emit the following log messages twice
     
     PromiseKit: warning: `wait()` called on main thread!
     PromiseKit: warning: pending promise deallocated
     PromiseKit:cauterized-error: purposes
     
*/
    func testLogging() {
        
        var logOutput: String? = nil
        
        enum ForTesting: Error {
            case purposes
        }
        
        // Test Logging to Console, the default behavior
        PromiseKit.log(PromiseKit.LogEvent.waitOnMainThread)
        PromiseKit.log(PromiseKit.LogEvent.pendingPromiseDeallocated)
        PromiseKit.log(PromiseKit.LogEvent.cauterized(ForTesting.purposes))
        PromiseKit.waitOnLogging()
        // Now test no logging
        PromiseKit.conf.loggingPolicy = .none
        PromiseKit.log(PromiseKit.LogEvent.waitOnMainThread)
        PromiseKit.log(PromiseKit.LogEvent.pendingPromiseDeallocated)
        PromiseKit.log(PromiseKit.LogEvent.cauterized(ForTesting.purposes))
        XCTAssertNil(logOutput)
        // Switch back to logging to console
        PromiseKit.conf.loggingPolicy = .console
        PromiseKit.log(PromiseKit.LogEvent.waitOnMainThread)
        PromiseKit.log(PromiseKit.LogEvent.pendingPromiseDeallocated)
        PromiseKit.log(PromiseKit.LogEvent.cauterized(ForTesting.purposes))
        PromiseKit.waitOnLogging()
        // Custom logger
        let loggingClosure: (PromiseKit.LogEvent) -> () = { event in
            logOutput = "\(event)"
        }
        PromiseKit.conf.loggingPolicy = .custom(loggingClosure)
        PromiseKit.log(PromiseKit.LogEvent.waitOnMainThread)
        PromiseKit.waitOnLogging()
        XCTAssertEqual(logOutput!, "waitOnMainThread")
        logOutput = nil
        PromiseKit.log(PromiseKit.LogEvent.pendingPromiseDeallocated)
        PromiseKit.waitOnLogging()
        XCTAssertEqual(logOutput!, "pendingPromiseDeallocated")
        logOutput = nil
        PromiseKit.log(PromiseKit.LogEvent.cauterized(ForTesting.purposes))
        PromiseKit.waitOnLogging()
        XCTAssertTrue(logOutput!.contains ("cauterized"))
        XCTAssertTrue(logOutput!.contains ("ForTesting.purposes"))
    }

    // Verify waiting on main thread in Promise is logged
    func testPromiseWaitOnMainThreadLogged() throws {
        
        enum ForTesting: Error {
            case purposes
        }
        
        var logOutput: String? = nil
        let loggingClosure: (PromiseKit.LogEvent) -> () = { event in
            logOutput = "\(event)"
        }
        PromiseKit.conf.loggingPolicy = .custom(loggingClosure)
        let promiseResolver = Promise<String>.pending()
        let workQueue = DispatchQueue(label: "worker")
        workQueue.async {
            promiseResolver.resolver.fulfill ("PromiseFulfilled")
        }
        let promisedString = try promiseResolver.promise.wait()
        XCTAssertEqual("PromiseFulfilled", promisedString)
        PromiseKit.waitOnLogging()
        XCTAssertEqual(logOutput!, "waitOnMainThread")
    }
    
    // Verify Promise.cauterize() is logged
    func testCauterizeIsLogged() {
        
        enum ForTesting: Error {
            case purposes
        }

        var logOutput: String? = nil
        let loggingClosure: (PromiseKit.LogEvent) -> () = { event in
            logOutput = "\(event)"
        }
        PromiseKit.conf.loggingPolicy = .custom(loggingClosure)
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
        PromiseKit.waitOnLogging()
        ex = expectation(description: "read")
        let readQueue = DispatchQueue(label: "readQueue")
        readQueue.async {
            var outputSet = false
            while !outputSet {
                if let logOutput = logOutput {
                    XCTAssertTrue (logOutput.contains("cauterized"))
                    XCTAssertTrue (logOutput.contains("ForTesting.purposes"))
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
        
        enum ForTesting: Error {
            case purposes
        }
        
        var logOutput: String? = nil
        let loggingClosure: (PromiseKit.LogEvent) -> () = { event in
            logOutput = "\(event)"
        }
        PromiseKit.conf.loggingPolicy = .custom(loggingClosure)
        let guaranteeResolve = Guarantee<String>.pending()
        let workQueue = DispatchQueue(label: "worker")
        workQueue.async {
            guaranteeResolve.resolve("GuaranteeFulfilled")
        }
        let guaranteedString = guaranteeResolve.guarantee.wait()
        XCTAssertEqual("GuaranteeFulfilled", guaranteedString)
        PromiseKit.waitOnLogging()
        XCTAssertEqual(logOutput!, "waitOnMainThread")
    }
    
    //TODO Verify pending promise dealocation is logged

}
