//
//  AllTests.swift
//  PMKJSA+Tests
//
//  Created by Lois Di Qual on 2/28/18.
//

#if swift(>=3.2)

import XCTest
import PromiseKit
import JavaScriptCore

class AllTests: XCTestCase {
    
    func testAll() {
        
        let scriptPath = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("build/build.js")
        guard FileManager.default.fileExists(atPath: scriptPath.path) else {
            return print("Skipping JS-A+: see README for instructions on how to build")
        }
        
        guard let script = try? String(contentsOf: scriptPath) else {
            return XCTFail("Couldn't read content of test suite JS file")
        }
        
        let context = JSUtils.sharedContext
        
        // Add a global exception handler
        context.exceptionHandler = { context, exception in
            guard let exception = exception else {
                return XCTFail("Unknown JS exception")
            }
            JSUtils.printStackTrace(exception: exception, includeExceptionDescription: true)
        }
        
        // Setup mock functions (timers, console.log, etc)
        let environment = MockNodeEnvironment()
        environment.setup(with: context)
        
        // Expose JSPromise in the javascript context
        context.setObject(JSPromise.self, forKeyedSubscript: "JSPromise" as NSString)
        
        // Create adapter
        guard let adapter = JSValue(object: NSDictionary(), in: context) else {
            fatalError("Couldn't create adapter")
        }
        adapter.setObject(JSAdapter.resolved, forKeyedSubscript: "resolved" as NSString)
        adapter.setObject(JSAdapter.rejected, forKeyedSubscript: "rejected" as NSString)
        adapter.setObject(JSAdapter.deferred, forKeyedSubscript: "deferred" as NSString)
        
        // Evaluate contents of `build.js`, which exposes `runTests` in the global context
        context.evaluateScript(script)
        guard let runTests = context.objectForKeyedSubscript("runTests") else {
            return XCTFail("Couldn't find `runTests` in JS context")
        }
        
        // Create a callback that's called whenever there's a failure
        let onFail: @convention(block) (JSValue, JSValue) -> Void = { test, error in
            guard let test = test.toString(), let error = error.toString() else {
                return XCTFail("Unknown test failure")
            }
            XCTFail("\(test) failed: \(error)")
        }
        let onFailValue: JSValue = JSValue(object: onFail, in: context)
        
        // Create a new callback that we'll send to `runTest` so that it notifies when tests are done running.
        let expectation = self.expectation(description: "async")
        let onDone: @convention(block) (JSValue) -> Void = { failures in
            expectation.fulfill()
        }
        let onDoneValue: JSValue = JSValue(object: onDone, in: context)
        
        // If there's a need to only run one specific test, uncomment the next line and comment the one after
        // let testName: JSValue = JSValue(object: "2.3.1", in: context)
        let testName = JSUtils.undefined
        
        // Call `runTests`
        runTests.call(withArguments: [adapter, onFailValue, onDoneValue, testName])
        self.wait(for: [expectation], timeout: 60)
    }
}

#endif
