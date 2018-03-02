//
//  AllTests.swift
//  PMKJSA+Tests
//
//  Created by Lois Di Qual on 2/28/18.
//

import XCTest
import PromiseKit
import JavaScriptCore

@objc protocol JSPromiseProtocol: JSExport {
    func then(_: JSValue, _: JSValue) -> JSPromise
}

class JSPromise: NSObject, JSPromiseProtocol {
    
    class JSError: CustomNSError {
        let reason: JSValue
        init(reason: JSValue) {
            self.reason = reason
        }
    }
    
    let promise: Promise<JSValue>
    
    init(promise: Promise<JSValue>) {
        self.promise = promise
    }
    
    func then(_ onFulfilled: JSValue, _ onRejected: JSValue) -> JSPromise {
        
        guard let context = JSContext.current() else {
            XCTFail("Couldn't get current JS context")
            fatalError()
        }
        
        let newPromise = Promise<JSValue>.pending()
        
        // TODO: Use tap. Fails because it's not async in case promise is already resolved.
        _ = promise.ensure {
            guard let result = self.promise.result else {
                return
            }
            
            // Spec requires onFulfilled/onRejected to be called as pure functions (without `this`)
            // See 2.2.5
            guard let this = JSValue(undefinedIn: context) else {
                return XCTFail("Couldn't create `undefined` value")
            }
            
            // Calls a JS handler and throws any potential exception wrapped in a JSError
            func call(handler: JSValue, arguments: [JSValue]) throws {
                let savedExceptionHandler = context.exceptionHandler
                context.exceptionHandler = { _ in }
                handler.invokeMethod("call", withArguments: arguments)
                if let exception = context.exception {
                    throw JSError(reason: exception)
                }
                context.exceptionHandler = savedExceptionHandler
            }
            
            switch result {
            case .fulfilled(let value):
                
                // Ignore handlers that are not functions
                guard onFulfilled.isObject else {
                    newPromise.resolver.fulfill(value)
                    return
                }
                
                do {
                    try call(handler: onFulfilled, arguments: [this, value])
                    newPromise.resolver.fulfill(value)
                } catch {
                    newPromise.resolver.reject(error)
                }
                
            case .rejected(let error):
                
                // Ignore handlers that are not functions
                guard let jsError = error as? JSError, onRejected.isObject else {
                    newPromise.resolver.reject(error)
                    return
                }
                
                do {
                    try call(handler: onRejected, arguments: [this, jsError.reason])
                    newPromise.resolver.reject(jsError)
                } catch {
                    newPromise.resolver.reject(error)
                }
            }
        }
        
        return JSPromise(promise: newPromise.promise)
    }
}

let resolved: @convention(block) (JSValue) -> JSPromise = { value in
    return JSPromise(promise: .value(value))
}

let rejected: @convention(block) (JSValue) -> JSPromise = { reason in
    let error = JSPromise.JSError(reason: reason)
    let promise = Promise<JSValue>(error: error)
    return JSPromise(promise: promise)
}

let deferred: @convention(block) () -> JSValue = {
    
    let context = JSContext.current()
    
    guard let object = JSValue(object: NSDictionary(), in: context) else {
        fatalError("Couldn't create object")
    }
    
    let pendingPromise = Promise<JSValue>.pending()
    let jsPromise = JSPromise(promise: pendingPromise.promise)
    
    // promise
    object.setObject(jsPromise, forKeyedSubscript: "promise" as NSString)
    
    // resolve
    let resolve: @convention(block) (JSValue) -> Void = { value in
        pendingPromise.resolver.fulfill(value)
    }
    object.setObject(resolve, forKeyedSubscript: "resolve" as NSString)
    
    // reject
    let reject: @convention(block) (JSValue) -> Void = { reason in
        let error = JSPromise.JSError(reason: reason)
        pendingPromise.resolver.reject(error)
    }
    object.setObject(reject, forKeyedSubscript: "reject" as NSString)
    
    return object
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
        context.setObject(JSPromise.self, forKeyedSubscript: "JSPromise" as NSString)
        
        // Create adapter
        guard let adapter = JSValue(object: NSDictionary(), in: context) else {
            fatalError("Couldn't create adapter")
        }
        adapter.setObject(resolved, forKeyedSubscript: "resolved" as NSString)
        adapter.setObject(rejected, forKeyedSubscript: "rejected" as NSString)
        adapter.setObject(deferred, forKeyedSubscript: "deferred" as NSString)
        
        // Evaluate contents of `build.js`, which exposes `runTests` in the global context
        context.evaluateScript(script)
        guard let runTests = context.objectForKeyedSubscript("runTests") else {
            return XCTFail("Couldn't find `runTests` in JS context")
        }
        
        // Create a new callback that we'll send to `runTest` so that it notifies when tests are done running.
        let expectation = self.expectation(description: "async")
        let callback: @convention(block) (JSValue) -> Void = { failures in
            expectation.fulfill()
        }
        context.setObject(callback, forKeyedSubscript: "mainCallback" as NSString)
        guard let callbackValue = context.objectForKeyedSubscript("mainCallback") else {
            return XCTFail("Couldn't create callback value")
        }
        
        // Call `runTests`
        runTests.call(withArguments: [adapter, callbackValue])
        self.wait(for: [expectation], timeout: 1000)
    }
}
