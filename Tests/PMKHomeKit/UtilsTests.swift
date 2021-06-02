//
//  UtilsTests.swift
//  PMKHKTests
//
//  Created by Chris Chares on 7/25/18.
//  Copyright © 2018 Max Howell. All rights reserved.
//

#if canImport(HomeKit) && !os(tvOS) && !os(watchOS)

import XCTest
import PromiseKit
@testable import PMKHomeKit

class UtilsTests: XCTestCase {
    
    var strongProxy: PromiseProxy<Int>? = PromiseProxy()
    
    override func setUp() {
        strongProxy = PromiseProxy()
    }
    
    override func tearDown() {
        strongProxy = nil
    }
    
    // The proxy should create a retain cycle until the promise is resolved
    func testRetainCycle() {
        weak var weakVar = strongProxy
        XCTAssertNotNil(weakVar)
        
        let exp = expectation(description: "")
        strongProxy = nil
        after(.milliseconds(50))
        .done {
            XCTAssertNotNil(weakVar)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // Once resolved, the proxy should break the retain cycle
    func testRelease() {
        weak var weakVar = strongProxy
        XCTAssertNotNil(weakVar)
        
        let exp = expectation(description: "")
        strongProxy!.fulfill(42)
        strongProxy = nil
        
        after(.milliseconds(50))
        .done {
            XCTAssertNil(weakVar)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // Cancel should reject with a PMKError
    func testCancel() {
        let proxy = strongProxy!
        proxy.cancel()
        XCTAssertNotNil(proxy.promise.error)
    }
}

#endif
