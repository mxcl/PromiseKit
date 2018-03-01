//
//  AllTests.swift
//  PMKJSA+Tests
//
//  Created by Lois Di Qual on 2/28/18.
//

import XCTest
import PromiseKit
import JavaScriptCore

@available(iOS 10.0, *)
class MockNodeEnvironment {
    
    private var timers: [Int: Timer] = [:]
    
    func setup(with context: JSContext) {
        
        // console.log
        if let console = context.objectForKeyedSubscript("console") {
            let consoleLog: @convention(block) () -> Void = {
                guard let arguments = JSContext.currentArguments(), let format = arguments.first as? JSValue else {
                    return
                }
                
                let otherArguments = arguments.dropFirst().flatMap { ($0 as? JSValue)?.toObject() as? CVarArg }
                if otherArguments.count == 0 {
                    print(format)
                } else {
                    let format = format.toString().replacingOccurrences(of: "%s", with: "%@")
                    let output = String(format: format, arguments: otherArguments)
//                    print(format)
                    print(output)
                }
            }
            console.setObject(consoleLog, forKeyedSubscript: "log" as NSString)
        }
        
        // setTimeout
        let setTimeout: @convention(block) (JSValue, Double) -> Int = { function, intervalMs in
            let timerID = self.addTimer(interval: intervalMs / 1000, repeats: false, function: function)
            return timerID
        }
        context.setObject(setTimeout, forKeyedSubscript: "setTimeout" as NSString)
        
        // clearTimeout
        let clearTimeout: @convention(block) (Int) -> Void = { timeoutID in
            self.removeTimer(timerID: timeoutID)
        }
        context.setObject(clearTimeout, forKeyedSubscript: "clearTimeout" as NSString)
        
        // setInterval
        let setInterval: @convention(block) (JSValue, Double) -> Int = { function, intervalMs in
            let timerID = self.addTimer(interval: intervalMs / 1000, repeats: true, function: function)
            return timerID
        }
        context.setObject(setInterval, forKeyedSubscript: "setInterval" as NSString)
        
        // clearInterval
        let clearInterval: @convention(block) (Int) -> Void = { intervalID in
            self.removeTimer(timerID: intervalID)
        }
        context.setObject(clearInterval, forKeyedSubscript: "clearInterval" as NSString)
    }
    
    private func addTimer(interval: TimeInterval, repeats: Bool, function: JSValue) -> Int {
        let hash = UUID().uuidString.hash
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            DispatchQueue.main.async {
                function.call(withArguments: [])
            }
        }
        timers[hash] = timer
        return hash
    }
    
    private func removeTimer(timerID: Int) {
        timers[timerID]?.invalidate()
        timers[timerID] = nil
    }
}

@available(iOS 10.0, *)
class AllTests: XCTestCase {
    func testAll() {
        
        let environment = MockNodeEnvironment()
        
        guard let context = JSContext() else {
            return XCTFail()
        }
        
        let bundle = Bundle(for: AllTests.self)
        guard let scriptPath = bundle.url(forResource: "build", withExtension: "js", subdirectory: "build") else {
            return XCTFail("Couldn't find test suite")
        }
        
        guard let script = try? String(contentsOf: scriptPath) else {
            return XCTFail("Couldn't read content of test suite JS file")
        }
        
        // Add a global exception handler
        context.exceptionHandler = { context, exception in
            
            guard let exception = exception,
                let message = exception.toString(),
                let lineNumber = exception.objectForKeyedSubscript("line"),
                let column = exception.objectForKeyedSubscript("column") else {
                return XCTFail("Unknown JS exception")
            }
            
            print("JS Exception at \(lineNumber):\(column): \(message)")
            
            if let stacktrace = exception.objectForKeyedSubscript("stack").toString() {
                let lines = stacktrace.split(separator: "\n").map { "\t> \($0)" }.joined(separator: "\n")
                print(lines)
            }
            
            XCTFail("JS exception")
        }
        
        // Setup mock functions (timers, console.log, etc)
        environment.setup(with: context)
        
        // Evaluate contents of `build.js`, which exposes `runTests` in the global context
        context.evaluateScript(script)
        guard let runTests = context.objectForKeyedSubscript("runTests") else {
            return XCTFail("Couldn't find `runTests` in JS context")
        }
        
        // Create a new callback that we'll send to `runTest` so that it notifies when tests are done running.
        let expectation = self.expectation(description: "async")
        let callback: @convention(block) (JSValue) -> Void = { failures in
            expectation.fulfill()
            print(failures.toString())
        }
        context.setObject(callback, forKeyedSubscript: "mainCallback" as NSString)
        guard let callbackValue = context.objectForKeyedSubscript("mainCallback") else {
            return XCTFail("Couldn't create callback value")
        }
        
        // Call `runTests`
        runTests.call(withArguments: [callbackValue])
        self.wait(for: [expectation], timeout: 10)
    }
}
