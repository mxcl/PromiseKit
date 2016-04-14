//
//  PMKDefaultDispatchQueue.test.swift
//  PromiseKit
//
//  Created by David Rodriguez on 4/14/16.
//  Copyright © 2016 Max Howell. All rights reserved.
//

import XCTest
@testable import PromiseKit

class PMKDefaultDispatchQueueTest_Swift: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        
        PMKDefaultDispatchQueue = { () -> dispatch_queue_t in dispatch_get_main_queue() }
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
        PMKDefaultDispatchQueue = { () -> dispatch_queue_t in
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
        PMKDefaultDispatchQueue = { () -> dispatch_queue_t in zalgo }
        
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
        PMKDefaultDispatchQueue = { () -> dispatch_queue_t in
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
        PMKDefaultDispatchQueue = { () -> dispatch_queue_t in zalgo }
        
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
        PMKDefaultDispatchQueue = { () -> dispatch_queue_t in
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
        PMKDefaultDispatchQueue = { () -> dispatch_queue_t in zalgo }
        
        var fulfilled = false
        Promise(1).always {
            fulfilled = true
        }
        XCTAssertTrue(fulfilled)
    }
}