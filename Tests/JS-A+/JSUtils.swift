//
//  JSUtils.swift
//  PMKJSA+Tests
//
//  Created by Lois Di Qual on 3/2/18.
//

import Foundation
import JavaScriptCore

enum JSUtils {
    
    class JSError: Error {
        let reason: JSValue
        init(reason: JSValue) {
            self.reason = reason
        }
    }
    
    static let sharedContext: JSContext = {
        guard let context = JSContext() else {
            fatalError("Couldn't create JS context")
        }
        return context
    }()
    
    static var undefined: JSValue {
        guard let undefined = JSValue(undefinedIn: JSUtils.sharedContext) else {
            fatalError("Couldn't create `undefined` value")
        }
        return undefined
    }
    
    static func typeError(message: String) -> JSValue {
        let message = message.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "new TypeError(\"\(message)\")"
        guard let result = sharedContext.evaluateScript(script) else {
            fatalError("Couldn't create TypeError")
        }
        return result
    }
    
    // @warning: relies on lodash to be present
    static func isFunction(value: JSValue) -> Bool {
        guard let context = value.context else {
            return false
        }
        guard let lodash = context.objectForKeyedSubscript("_") else {
            fatalError("Couldn't get lodash in JS context")
        }
        guard let result = lodash.invokeMethod("isFunction", withArguments: [value]) else {
            fatalError("Couldn't invoke _.isFunction")
        }
        return result.toBool()
    }
    
    // Calls a JS function using `Function.prototype.call` and throws any potential exception wrapped in a JSError
    static func call(function: JSValue, arguments: [JSValue]) throws -> JSValue? {
        
        let context = JSUtils.sharedContext
        
        // Create a new exception handler that will store a potential exception
        // thrown in the handler. Save the value of the old handler.
        var caughtException: JSValue?
        let savedExceptionHandler = context.exceptionHandler
        context.exceptionHandler = { context, exception in
            caughtException = exception
        }
        
        // Call the handler
        let returnValue = function.invokeMethod("call", withArguments: arguments)
        context.exceptionHandler = savedExceptionHandler
        
        // If an exception was caught, throw it
        if let exception = caughtException {
            throw JSError(reason: exception)
        }
        
        return returnValue
    }
    
    static func printCurrentStackTrace() {
        guard let exception = JSUtils.sharedContext.evaluateScript("new Error()") else {
            return print("Couldn't get current stack trace")
        }
        printStackTrace(exception: exception, includeExceptionDescription: false)
    }
    
    static func printStackTrace(exception: JSValue, includeExceptionDescription: Bool) {
        guard let lineNumber = exception.objectForKeyedSubscript("line"),
            let column = exception.objectForKeyedSubscript("column"),
            let message = exception.objectForKeyedSubscript("message"),
            let stacktrace = exception.objectForKeyedSubscript("stack")?.toString() else {
                return print("Couldn't print stack trace")
        }
        
        if includeExceptionDescription {
            print("JS Exception at \(lineNumber):\(column): \(message)")
        }
        
        let lines = stacktrace.split(separator: "\n").map { "\t> \($0)" }.joined(separator: "\n")
        print(lines)
    }
}

#if !swift(>=3.2)
extension String {
    func split(separator: Character, omittingEmptySubsequences: Bool = true) -> [String] {
        return characters.split(separator: separator, omittingEmptySubsequences: omittingEmptySubsequences).map(String.init)
    }
    
    var first: Character? {
        return characters.first
    }
}
#endif
