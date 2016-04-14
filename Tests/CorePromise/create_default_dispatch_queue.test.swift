//
//  create_default_dispatch_queue.test.swift
//  PromiseKit
//
//  Created by David Rodriguez on 4/14/16.
//  Copyright © 2016 Max Howell. All rights reserved.
//

import XCTest
@testable import PromiseKit

class create_default_dispatch_queue_Tests_Swift: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        
        create_default_promise_dispatch_queue = { () -> dispatch_queue_t in dispatch_get_main_queue() }
    }
    
    func testThenWithDefaultQueue() {
        var fulfilled = false
        let testExpectation = expectationWithDescription("resolving")
        Promise(1).then { (_) -> Promise<Void> in
            fulfilled = true
            testExpectation.fulfill()
            return Promise()
        }
        XCTAssertFalse(fulfilled)
        
        waitForExpectationsWithTimeout(1) { _ in
            XCTAssertTrue(fulfilled)
        }
    }
    
    func testThenWithDifferentQueue() {
        create_default_promise_dispatch_queue = { () -> dispatch_queue_t in
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
        }
        
        var fulfilled = false
        let testExpectation = expectationWithDescription("resolving")
        Promise(1).then { (_) -> Promise<Void> in
            XCTAssertFalse(NSThread.isMainThread());
            
            fulfilled = true
            testExpectation.fulfill()
            return Promise()
        }
        XCTAssertFalse(fulfilled)
        
        waitForExpectationsWithTimeout(1) { _ in
            XCTAssertTrue(fulfilled)
        }
    }
    
    func testThenWithZalgo() {
        create_default_promise_dispatch_queue = { () -> dispatch_queue_t in zalgo }
        
        var fulfilled = false
        Promise(1).then { _ in
            fulfilled = true
        }
        XCTAssertTrue(fulfilled)
    }
    
    func testErrorWithDefaultQueue() {
        var rejected = false
        let err = NSError(domain: "test", code: 0, userInfo: nil)
        let testExpectation = expectationWithDescription("resolving")
        Promise(error: err).then {
            XCTFail()
            }.error { _ in
                rejected = true
                testExpectation.fulfill()
        }
        
        XCTAssertFalse(rejected)
        
        waitForExpectationsWithTimeout(1) { _ in
            XCTAssertTrue(rejected)
        }
    }
    
    func testErrorWithDifferentQueue() {
        create_default_promise_dispatch_queue = { () -> dispatch_queue_t in
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
        }
        
        var rejected = false
        let err = NSError(domain: "test", code: 0, userInfo: nil)
        let testExpectation = expectationWithDescription("resolving")
        Promise(error: err).then {
            XCTFail()
            }.error { _ in
                XCTAssertFalse(NSThread.isMainThread());
                
                rejected = true
                testExpectation.fulfill()
        }
        
        XCTAssertFalse(rejected)
        
        waitForExpectationsWithTimeout(1) { _ in
            XCTAssertTrue(rejected)
        }
    }
    
    func testErrorWithZalgo() {
        create_default_promise_dispatch_queue = { () -> dispatch_queue_t in zalgo }
        
        var rejected = false
        let err = NSError(domain: "test", code: 0, userInfo: nil)
        Promise(error: err).then {
            XCTFail()
            }.error { _ in
                rejected = true
        }
        XCTAssertTrue(rejected)
    }
    
    func testAlwaysWithDefaultQueue() {
        var fulfilled = false
        let testExpectation = expectationWithDescription("resolving")
        Promise(1).always {
            fulfilled = true
            testExpectation.fulfill()
        }
        XCTAssertFalse(fulfilled)
        
        waitForExpectationsWithTimeout(1) { _ in
            XCTAssertTrue(fulfilled)
        }
    }
    
    func testAlwaysWithDifferentQueue() {
        create_default_promise_dispatch_queue = { () -> dispatch_queue_t in
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
        }
        
        var fulfilled = false
        let testExpectation = expectationWithDescription("resolving")
        Promise(1).always {
            XCTAssertFalse(NSThread.isMainThread());
            
            fulfilled = true
            testExpectation.fulfill()
        }
        XCTAssertFalse(fulfilled)
        
        waitForExpectationsWithTimeout(1) { _ in
            XCTAssertTrue(fulfilled)
        }
    }
    
    func testAlwaysWithZalgo() {
        create_default_promise_dispatch_queue = { () -> dispatch_queue_t in zalgo }
        
        var fulfilled = false
        Promise(1).always {
            fulfilled = true
        }
        XCTAssertTrue(fulfilled)
    }
}