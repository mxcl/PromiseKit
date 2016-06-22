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
        
        PMKDefaultDispatchQueue = { () -> DispatchQueue in DispatchQueue.main }
    }
    
    func testThenWithDefaultQueue() {
        var fulfilled = false
        let testExpectation = expectation(withDescription: "resolving")
        Promise(1).then { (_) -> Promise<Void> in
            fulfilled = true
            testExpectation.fulfill()
            return Promise()
        }
        XCTAssertFalse(fulfilled)
        
        waitForExpectations(withTimeout: 1) { _ in
            XCTAssertTrue(fulfilled)
        }
    }
    
    func testThenWithDifferentQueue() {
        PMKDefaultDispatchQueue = { () -> DispatchQueue in
            DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosUtility)
        }
        
        var fulfilled = false
        let testExpectation = expectation(withDescription: "resolving")
        Promise(1).then { (_) -> Promise<Void> in
            XCTAssertFalse(Thread.isMainThread());
            
            fulfilled = true
            testExpectation.fulfill()
            return Promise()
        }
        XCTAssertFalse(fulfilled)
        
        waitForExpectations(withTimeout: 1) { _ in
            XCTAssertTrue(fulfilled)
        }
    }
    
    func testThenWithZalgo() {
        PMKDefaultDispatchQueue = { () -> DispatchQueue in zalgo }
        
        var fulfilled = false
        Promise(1).then { _ in
            fulfilled = true
        }
        XCTAssertTrue(fulfilled)
    }
    
    func testErrorWithDefaultQueue() {
        var rejected = false
        let err = NSError(domain: "test", code: 0, userInfo: nil)
        let testExpectation = expectation(withDescription: "resolving")
        Promise(error: err).then {
            XCTFail()
            }.error { _ in
                rejected = true
                testExpectation.fulfill()
        }
        
        XCTAssertFalse(rejected)
        
        waitForExpectations(withTimeout: 1) { _ in
            XCTAssertTrue(rejected)
        }
    }
    
    func testErrorWithDifferentQueue() {
        PMKDefaultDispatchQueue = { () -> DispatchQueue in
            DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosUtility)
        }
        
        var rejected = false
        let err = NSError(domain: "test", code: 0, userInfo: nil)
        let testExpectation = expectation(withDescription: "resolving")
        Promise(error: err).then {
            XCTFail()
            }.error { _ in
                XCTAssertFalse(Thread.isMainThread());
                
                rejected = true
                testExpectation.fulfill()
        }
        
        XCTAssertFalse(rejected)
        
        waitForExpectations(withTimeout: 1) { _ in
            XCTAssertTrue(rejected)
        }
    }
    
    func testErrorWithZalgo() {
        PMKDefaultDispatchQueue = { () -> DispatchQueue in zalgo }
        
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
        let testExpectation = expectation(withDescription: "resolving")
        Promise(1).always {
            fulfilled = true
            testExpectation.fulfill()
        }
        XCTAssertFalse(fulfilled)
        
        waitForExpectations(withTimeout: 1) { _ in
            XCTAssertTrue(fulfilled)
        }
    }
    
    func testAlwaysWithDifferentQueue() {
        PMKDefaultDispatchQueue = { () -> DispatchQueue in
            DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosUtility)
        }
        
        var fulfilled = false
        let testExpectation = expectation(withDescription: "resolving")
        Promise(1).always {
            XCTAssertFalse(Thread.isMainThread());
            
            fulfilled = true
            testExpectation.fulfill()
        }
        XCTAssertFalse(fulfilled)
        
        waitForExpectations(withTimeout: 1) { _ in
            XCTAssertTrue(fulfilled)
        }
    }
    
    func testAlwaysWithZalgo() {
        PMKDefaultDispatchQueue = { () -> DispatchQueue in zalgo }
        
        var fulfilled = false
        Promise(1).always {
            fulfilled = true
        }
        XCTAssertTrue(fulfilled)
    }
}
