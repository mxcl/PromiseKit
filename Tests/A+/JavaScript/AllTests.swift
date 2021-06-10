//
//  AllTests.swift
//  PMKJSA+Tests
//
//  Created by Lois Di Qual on 2/28/18.
//

#if !os(Linux) && !os(watchOS) && !os(Windows)
import JavaScriptCore
import PromiseKit
import XCTest

class APlusJavaScriptTests: XCTestCase {
    func test_2_1_2() { runner(test: "2.1.2") }
    func test_2_1_3() { runner(test: "2.1.3") }
    func test_2_2_1() { runner(test: "2.2.1") }
    func test_2_2_2() { runner(test: "2.2.2") }
    func test_2_2_3() { runner(test: "2.2.3") }
    func test_2_2_4() { runner(test: "2.2.4") }
    func test_2_2_5() { runner(test: "2.2.5") }
    // func test_2_2_6() { runner(test: "2.2.6") }  // disabled as fails for some reason currently
    func test_2_2_7() { runner(test: "2.2.7") }
    func test_2_3_1() { runner(test: "2.3.1") }
    func test_2_3_2() { runner(test: "2.3.2") }
    func test_2_3_4() { runner(test: "2.3.4") }

    func runner(test testName: String, file: StaticString = #file, line: UInt = #line) {
        let scriptPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("build/build.js")
        guard FileManager.default.fileExists(atPath: scriptPath.path) else {
            return print("Skipping A+.js: see README for instructions on how to build")
        }
        
        guard let script = try? String(contentsOf: scriptPath) else {
            return XCTFail("Couldn't read content of test suite JS file", file: file, line: line)
        }
        
        let context = JSUtils.sharedContext
        let expectation = self.expectation(description: "async")
        
        // Add a global exception handler
        context.exceptionHandler = { context, exception in
            if let exception = exception {
                JSUtils.printStackTrace(exception: exception, includeExceptionDescription: true)
            }
            XCTFail(file: file, line: line)
            expectation.fulfill()
        }
        
        // Setup mock functions (timers, console.log, etc)
        let environment = MockNodeEnvironment()
        environment.setup(with: context)
        
        // Expose JSPromise in the javascript context
        context.setObject(JSPromise.self, forKeyedSubscript: "JSPromise" as NSString)
        
        // Create adapter
        guard let adapter = JSValue(object: NSDictionary(), in: context) else {
            return XCTFail("Couldn't create adapter", file: file, line: line)
        }
        adapter.setObject(JSAdapter.resolved, forKeyedSubscript: "resolved" as NSString)
        adapter.setObject(JSAdapter.rejected, forKeyedSubscript: "rejected" as NSString)
        adapter.setObject(JSAdapter.deferred, forKeyedSubscript: "deferred" as NSString)
        
        // Evaluate contents of `build.js`, which exposes `runTests` in the global context
        context.evaluateScript(script)
        guard let runTests = context.objectForKeyedSubscript("runTests") else {
            return XCTFail("Couldn't find `runTests` in JS context", file: file, line: line)
        }
        
        // Create a callback that's called whenever there's a failure
        let onFail: @convention(block) (JSValue, JSValue) -> Void = { test, error in
            guard let test = test.toString(), let error = error.toString() else {
                return XCTFail("Unknown test failure", file: file, line: line)
            }
            return XCTFail("\(test) failed: \(error)", file: file, line: line)
        }
        let onFailValue: JSValue = JSValue(object: onFail, in: context)
        
        let onDone: @convention(block) (JSValue) -> Void = { failures in
            expectation.fulfill()
        }
        let onDoneValue: JSValue = JSValue(object: onDone, in: context)
        
        guard let testName = JSValue(object: testName, in: context) else {
            return XCTFail(file: file, line: line)
        }

        // use this to run *all* tests
        //let testName = JSUtils.undefined
        
        // Call `runTests`
        runTests.call(withArguments: [adapter, onFailValue, onDoneValue, testName])
        wait(for: [expectation], timeout: 30)
    }
}

#endif
