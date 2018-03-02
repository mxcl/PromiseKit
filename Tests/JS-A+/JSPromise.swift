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
        
        // 2.2.5: onFulfilled/onRejected must be called as functions (with no `this` value)
        guard let undefined = JSValue(undefinedIn: context) else {
            XCTFail("Couldn't create `undefined` value")
            fatalError()
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
        
        let newPromise = Promise<JSValue>.pending()
        
        promise.done { value in
            
            // 2.2.1: ignored if not a function
            guard onFulfilled.isObject else {
                newPromise.resolver.fulfill(value)
                return
            }
            
            do {
                try call(handler: onFulfilled, arguments: [undefined, value])
                newPromise.resolver.fulfill(value)
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
                try call(handler: onRejected, arguments: [undefined, jsError.reason])
                newPromise.resolver.reject(jsError)
            } catch {
                newPromise.resolver.reject(error)
            }
        }
        
        return JSPromise(promise: newPromise.promise)
    }
}
