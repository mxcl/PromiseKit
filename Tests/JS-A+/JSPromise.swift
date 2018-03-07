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
    
    let promise: Promise<JSValue>
    
    init(promise: Promise<JSValue>) {
        self.promise = promise
    }
    
    func then(_ onFulfilled: JSValue, _ onRejected: JSValue) -> JSPromise {
        
        // Keep a reference to the returned promise so we can comply to 2.3.1
        var returnedPromiseRef: Promise<JSValue>?
        
        let afterFulfill = promise.then { value -> Promise<JSValue> in
            
            // 2.2.1: ignored if not a function
            guard JSUtils.isFunction(value: onFulfilled) else {
                return .value(value)
            }
            
            // Call `onFulfilled`
            // 2.2.5: onFulfilled/onRejected must be called as functions (with no `this` value)
            guard let returnValue = try JSUtils.call(function: onFulfilled, arguments: [JSUtils.undefined, value]) else {
                return .value(value)
            }
            
            // Extract JSPromise.promise if available, or use plain return value
            if let jsPromise = returnValue.toObjectOf(JSPromise.self) as? JSPromise {
                
                // 2.3.1: if returned value is the promise that `then` returned, throw TypeError
                if jsPromise.promise === returnedPromiseRef {
                    throw JSUtils.JSError(reason: JSUtils.typeError(message: "Returned self"))
                }
                return jsPromise.promise
            } else {
                return .value(returnValue)
            }
        }
        
        let afterReject = promise.recover { error -> Promise<JSValue> in
            
            // 2.2.1: ignored if not a function
            guard let jsError = error as? JSUtils.JSError, JSUtils.isFunction(value: onRejected) else {
                throw error
            }
            
            // Call `onRejected`
            // 2.2.5: onFulfilled/onRejected must be called as functions (with no `this` value)
            guard let returnValue = try JSUtils.call(function: onRejected, arguments: [JSUtils.undefined, jsError.reason]) else {
                throw error
            }
            
            // Extract JSPromise.promise if available, or use plain return value
            if let jsPromise = returnValue.toObjectOf(JSPromise.self) as? JSPromise {
                
                // 2.3.1: if returned value is the promise that `then` returned, throw TypeError
                if jsPromise.promise === returnedPromiseRef {
                    throw JSUtils.JSError(reason: JSUtils.typeError(message: "Returned self"))
                }
                return jsPromise.promise
            } else {
                return .value(returnValue)
            }
        }
        
        let newPromise = Promise<Result<JSValue>> { resolver in
            _ = promise.tap(resolver.fulfill)
        }.then(on: nil) { result -> Promise<JSValue> in
            switch result {
            case .fulfilled: return afterFulfill
            case .rejected: return afterReject
            }
        }
        returnedPromiseRef = newPromise
        
        return JSPromise(promise: newPromise)
    }
}
