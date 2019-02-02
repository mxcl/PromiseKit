//
//  JSAdapter.swift
//  PMKJSA+Tests
//
//  Created by Lois Di Qual on 3/2/18.
//

import Foundation
import JavaScriptCore
import PromiseKit

enum JSAdapter {
    
    static let resolved: @convention(block) (JSValue) -> JSPromise = { value in
        return JSPromise(promise: .value(value))
    }
    
    static let rejected: @convention(block) (JSValue) -> JSPromise = { reason in
        let error = JSUtils.JSError(reason: reason)
        let promise = Promise<JSValue>(error: error)
        return JSPromise(promise: promise)
    }
    
    static let deferred: @convention(block) () -> JSValue = {
        
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
            let error = JSUtils.JSError(reason: reason)
            pendingPromise.resolver.reject(error)
        }
        object.setObject(reject, forKeyedSubscript: "reject" as NSString)
        
        return object
    }
}
