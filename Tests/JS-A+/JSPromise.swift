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
