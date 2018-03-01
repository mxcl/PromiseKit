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
                
                let otherArguments = arguments.dropFirst()
                if otherArguments.count == 0 {
                    print(format)
                } else {
                    
                    let otherArguments = otherArguments.flatMap { $0 as? JSValue }
                    let format = format.toString().replacingOccurrences(of: "%s", with: "%@")
                    
                    // TODO: fix this format hack
                    let expectedTypes = " \(format)".split(separator: "%").dropFirst().flatMap { $0.first }.map { String($0) }
                    
                    let typedArguments = otherArguments.enumerated().flatMap { index, value -> CVarArg? in
                        let expectedType = expectedTypes[index]
                        let converted: CVarArg
                        switch expectedType {
                        case "s": converted = value.toString()
                        case "d": converted = value.toInt32()
                        case "f": converted = value.toDouble()
                        default: converted = value.toString()
                        }
                        return converted
                    }
                    
                    let output = String(format: format, arguments: typedArguments)
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

@objc protocol JSPromiseProtocol: JSExport {
    
}

class JSPromise: NSObject, JSPromiseProtocol {
    
    class Error: CustomNSError {
        let reason: String
        init(reason: String) {
            self.reason = reason
        }
    }
    
    let promise = Promise<JSValue>.pending()
}

@objc protocol JSAdapterProtocol: JSExport {
    func resolved() -> JSPromise
    func rejected() -> JSPromise
    func deferred() -> JSValue
}

@objc class JSAdapter: NSObject, JSAdapterProtocol {
    
    let context: JSContext
    
    init(context: JSContext) {
        self.context = context
    }
    
    func resolved() -> JSPromise {
        return JSPromise()
    }

    func rejected() -> JSPromise {
        return JSPromise()
    }

    func deferred() -> JSValue {

        guard let object = JSValue(object: NSDictionary(), in: context) else {
            fatalError("Couldn't create object")
        }

        let promise = JSPromise()

        // promise
        object.setObject(promise, forKeyedSubscript: "promise" as NSString)

        // resolve
        let resolve: @convention(block) (JSValue) -> Void = { value in
            promise.promise.resolver.fulfill(value)
        }
        object.setObject(resolve, forKeyedSubscript: "resolve" as NSString)

        // reject
        let reject: @convention(block) (JSValue) -> Void = { reason in
            let error = JSPromise.Error(reason: reason.toString())
            promise.promise.resolver.reject(error)
        }
        object.setObject(reject, forKeyedSubscript: "reject" as NSString)

        return object
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
            
            XCTFail("JS Exception at \(lineNumber):\(column): \(message)")
            
            if let stacktrace = exception.objectForKeyedSubscript("stack").toString() {
                let lines = stacktrace.split(separator: "\n").map { "\t> \($0)" }.joined(separator: "\n")
                print(lines)
            }
        }
        
        // Setup mock functions (timers, console.log, etc)
        environment.setup(with: context)
        
        // Expose JSPromise and JSAdapter in the javascript context
        context.setObject(JSAdapter.self, forKeyedSubscript: "JSAdapter" as NSString)
        context.setObject(JSPromise.self, forKeyedSubscript: "JSPromise" as NSString)
        
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
        let adapter = JSAdapter(context: context)
        runTests.call(withArguments: [adapter, callbackValue])
        self.wait(for: [expectation], timeout: 10)
    }
}
