//
//  AllTests.swift
//  PMKJSA+Tests
//
//  Created by Lois Di Qual on 2/28/18.
//

import XCTest
import PromiseKit
import JavaScriptCore

class AllTests: XCTestCase {
    func testAll() {
        guard let context = JSContext() else {
            return XCTFail()
        }
        
        guard let scriptPath = Bundle(for: AllTests.self).url(forResource: "build", withExtension: "js", subdirectory: "build") else {
            return XCTFail("Couldn't find test suite")
        }
        
        guard let script = try? String(contentsOf: scriptPath) else {
            return XCTFail("Couldn't read content of test suite JS file")
        }
        
        context.exceptionHandler = { context, exception in
            
            guard let exception = exception, let message = exception.toString() else {
                return XCTFail("Unknown JS exception")
            }
            
            //print("JS Exception: \(message)")
            
            if let stacktrace = exception.objectForKeyedSubscript("stack").toString(),
                let lineNumber = exception.objectForKeyedSubscript("line"),
                let column = exception.objectForKeyedSubscript("column") {
                //print("\(stacktrace)")
            }
            
            if let message = exception.toString() {
                XCTFail("JS Exception: \(message)")
            } else {
                XCTFail("Unknown JS exception")
            }
        }
        
        let consoleLog: @convention(block) (String) -> Void = { str in
            print("Log: \(str)")
        }
        
        context.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString)
        
        // Evaluate contents of `build.js`, which exposes `promisesAplusTests` in the global context
        context.evaluateScript(script, withSourceURL: scriptPath)
        
        let result = context.evaluateScript("promisesAplusTests")
        
//        let result = context.evaluateScript("require('promises-aplus-tests')")
        
    }
}
