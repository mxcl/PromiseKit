//
//  JSPromise.swift
//  PMKJSA+Tests
//
//  Created by Lois Di Qual on 3/1/18.
//

import Foundation
import XCTest
import PromiseKit
import JavaScriptCore

@available(iOS 10.0, *)
@objc protocol JSPromiseProtocol: JSExport {
    func then(_: JSValue, _: JSValue) -> JSPromise
}

@available(iOS 10.0, *)
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
        
        // 2.2.5: onFulfilled/onRejected must be called as functions (with no `this` value)
        guard let undefined = JSValue(undefinedIn: context) else {
            XCTFail("Couldn't create `undefined` value")
            fatalError()
        }
        
        // Calls a JS handler and throws any potential exception wrapped in a JSError
        func call(handler: JSValue, arguments: [JSValue]) throws -> JSValue? {
            
            // Create a new exception handler that will store a potential exception
            // thrown in the handler. Save the value of the old handler.
            var caughtException: JSValue?
            let savedExceptionHandler = context.exceptionHandler
            context.exceptionHandler = { context, exception in
                caughtException = exception
            }
            
            // Call the handler
            let returnValue = handler.invokeMethod("call", withArguments: arguments)
            context.exceptionHandler = savedExceptionHandler
            
            // If an exception was caught, throw it
            if let exception = caughtException {
                throw JSError(reason: exception)
            }
            
            // 2.2.7.1: If we have a return value that is not `undefined`, return it
            if let returnValue = returnValue, !returnValue.isUndefined {
                return returnValue
            } else {
                return nil
            }
        }
        
        let newPromise = Promise<JSValue>.pending()
        
        promise.done { value in
            
            // 2.2.1: ignored if not a function
            guard onFulfilled.isObject else {
                newPromise.resolver.fulfill(value)
                return
            }
            
            do {
                let returnValue = try call(handler: onFulfilled, arguments: [undefined, value])
                if let returnValue = returnValue {
                    newPromise.resolver.fulfill(returnValue)
                } else {
                    newPromise.resolver.fulfill(value)
                }
            } catch {
                newPromise.resolver.reject(error)
            }
            
        }.catch { error in
            
            // 2.2.1: ignored if not a function
            guard let jsError = error as? JSError, onRejected.isObject else {
                newPromise.resolver.reject(error)
                return
            }
            
            do {
                let returnValue = try call(handler: onRejected, arguments: [undefined, jsError.reason])
                if let returnValue = returnValue {
                    newPromise.resolver.fulfill(returnValue)
                } else {
                    newPromise.resolver.reject(jsError)
                }
            } catch {
                newPromise.resolver.reject(error)
            }
        }
        
        return JSPromise(promise: newPromise.promise)
    }
}
