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
            if let message = exception?.toString() {
                XCTFail("JS Exception: \(message)")
            } else {
                XCTFail("Unknown JS exception")
            }
        }
        
        context.evaluateScript(script, withSourceURL: scriptPath)
        let result = context.evaluateScript("library")
        
//        let result = context.evaluateScript("require('promises-aplus-tests')")
        
    }
}
