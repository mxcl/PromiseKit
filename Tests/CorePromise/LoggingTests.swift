@testable import PromiseKit
import Dispatch
import XCTest

class LoggingTests: XCTestCase {
    /**
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

        conf.logHandler =  { event in
            switch event {
            case .waitOnMainThread, .pendingPromiseDeallocated, .pendingGuaranteeDeallocated:
                logOutput = "\(event)"
            case .cauterized:
                // Using an enum with associated value does not convert to a string properly in
                // earlier versions of swift
                logOutput = "cauterized"
            }
        }
        conf.logHandler(.waitOnMainThread)
        XCTAssertEqual(logOutput!, "waitOnMainThread")
        logOutput = nil
        conf.logHandler(.pendingPromiseDeallocated)
        XCTAssertEqual(logOutput!, "pendingPromiseDeallocated")
        logOutput = nil
        conf.logHandler(.cauterized(ForTesting.purposes))
        XCTAssertEqual(logOutput!, "cauterized")
    }

    // Verify waiting on main thread in Promise is logged
    func testPromiseWaitOnMainThreadLogged() throws {
        
        enum ForTesting: Error {
            case purposes
        }
        
        var logOutput: String? = nil
        conf.logHandler = { event in
            logOutput = "\(event)"
        }
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
        conf.logHandler = { event in
            switch event {
            case .waitOnMainThread, .pendingPromiseDeallocated, .pendingGuaranteeDeallocated:
                logOutput = "\(event)"
            case .cauterized:
                // Using an enum with associated value does not convert to a string properly in
                // earlier versions of swift
                logOutput = "cauterized"
            }
        }
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
        conf.logHandler = { event in
            switch event {
            case .waitOnMainThread, .pendingPromiseDeallocated, .pendingGuaranteeDeallocated:
                logOutput = "\(event)"
            case .cauterized:
                // Using an enum with associated value does not convert to a string properly in
                // earlier versions of swift
                logOutput = "cauterized"
            }
        }
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
        
        var logOutput: String? = nil
        conf.logHandler = { event in
            switch event {
            case .waitOnMainThread, .pendingPromiseDeallocated, .pendingGuaranteeDeallocated:
                logOutput = "\(event)"
            case .cauterized:
                // Using an enum with associated value does not convert to a string properly in
                // earlier versions of swift
                logOutput = "cauterized"
            }
        }
        do {
            let _ = Promise<Int>.pending()
        }
        XCTAssertEqual ("pendingPromiseDeallocated", logOutput!)
    }
    
    // Verify pendingGuaranteeDeallocated is logged
    func testPendingGuaranteeDeallocatedIsLogged() {
        
        var logOutput: String? = nil
        let loggingClosure: (PromiseKit.LogEvent) -> () = { event in
            switch event {
            case .waitOnMainThread, .pendingPromiseDeallocated, .pendingGuaranteeDeallocated:
                logOutput = "\(event)"
            case .cauterized:
                // Using an enum with associated value does not convert to a string properly in
                // earlier versions of swift
                logOutput = "cauterized"
            }
        }
        conf.logHandler = loggingClosure
        do {
            let _ = Guarantee<Int>.pending()
        }
        XCTAssertEqual ("pendingGuaranteeDeallocated", logOutput!)
    }
    
    //TODO Verify pending promise deallocation is logged
}
