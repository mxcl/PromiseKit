@testable import PromiseKit
import Dispatch
import XCTest

class LoggingTests: XCTestCase {

/**
     
     // Verify LoggingPolicy directs output correctly
     
     The test should emit the following log messages:
     
     PromiseKit: warning: `wait()` called on main thread!
     PromiseKit: warning: pending promise deallocated
     PromiseKit:cauterized-error: purposes
     This is an error message
     
*/
    func testLogging() {
        
        var logOutput: String? = nil
        
        enum ForTesting: Error {
            case purposes
        }
        
        // Test Logging to Console, the default behavior
        conf.loggingClosure (.waitOnMainThread)
        conf.loggingClosure (.pendingPromiseDeallocated)
        conf.loggingClosure (.cauterized(ForTesting.purposes))
        conf.loggingClosure (.misc("This is an error message"))
        XCTAssertNil(logOutput)
        // Now test no logging
        conf.loggingClosure = { event in }
        conf.loggingClosure (.waitOnMainThread)
        conf.loggingClosure (.pendingPromiseDeallocated)
        conf.loggingClosure (.cauterized(ForTesting.purposes))
        conf.loggingClosure (.misc("This is an error message"))
        XCTAssertNil(logOutput)
        let loggingClosure: (PromiseKit.LogEvent) -> () = { event in
            switch event {
            case .waitOnMainThread:
                logOutput = "\(event)"
            case .pendingPromiseDeallocated:
                logOutput = "\(event)"
            case .cauterized:
                // Using an enum with associated value does not convert to a string properly in
                // earlier versions of swift
                logOutput = "cauterized"
            case .misc (let errorMessage):
                logOutput = errorMessage
            }
        }
        conf.loggingClosure = loggingClosure
        conf.loggingClosure (.waitOnMainThread)
        XCTAssertEqual(logOutput!, "waitOnMainThread")
        logOutput = nil
        conf.loggingClosure (.pendingPromiseDeallocated)
        XCTAssertEqual(logOutput!, "pendingPromiseDeallocated")
        logOutput = nil
        conf.loggingClosure (.cauterized(ForTesting.purposes))
        XCTAssertEqual(logOutput!, "cauterized")
        logOutput = nil
        conf.loggingClosure (.misc("This is an error message"))
        XCTAssertEqual(logOutput!, "This is an error message")
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
        conf.loggingClosure = loggingClosure
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
        
        enum ForTesting: Error {
            case purposes
        }

        var logOutput: String? = nil
        let loggingClosure: (PromiseKit.LogEvent) -> () = { event in
            switch event {
            case .waitOnMainThread:
                logOutput = "\(event)"
            case .pendingPromiseDeallocated:
                logOutput = "\(event)"
            case .cauterized:
                // Using an enum with associated value does not convert to a string properly in
                // earlier versions of swift
                logOutput = "cauterized"
            case .misc (let errorMessage):
                logOutput = errorMessage           }
        }
        conf.loggingClosure = loggingClosure
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
                if let logOutput = logOutput {
                    XCTAssertEqual(logOutput, "cauterized")
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
            switch event {
            case .waitOnMainThread:
                logOutput = "\(event)"
            case .pendingPromiseDeallocated:
                logOutput = "\(event)"
            case .cauterized:
                // Using an enum with associated value does not convert to a string properly in
                // earlier versions of swift
                logOutput = "cauterized"
            case .misc (let errorMessage):
                logOutput = errorMessage          }
        }
        conf.loggingClosure = loggingClosure
        let guaranteeResolve = Guarantee<String>.pending()
        let workQueue = DispatchQueue(label: "worker")
        workQueue.async {
            guaranteeResolve.resolve("GuaranteeFulfilled")
        }
        let guaranteedString = guaranteeResolve.guarantee.wait()
        XCTAssertEqual("GuaranteeFulfilled", guaranteedString)
        XCTAssertEqual(logOutput!, "waitOnMainThread")
    }
    
    //TODO Verify pending promise dealocation is logged

}
