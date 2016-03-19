//
//  join.test.swift
//  PromiseKit
//
//  Created by Austin Feight on 3/19/16.
//  Copyright © 2016 Max Howell. All rights reserved.
//

import XCTest
import PromiseKit

class join_test: XCTestCase {}

// MARK: - Variadic Tests
extension join_test {
    func testImmediates() {
        let successPromise = Promise()

        var joinFinished = false
        join(successPromise)
        .then(on: zalgo) { _ in joinFinished = true }
        XCTAssert(joinFinished, "Join immediately finishes on fulfilled promise")
        
        let promise2 = Promise(2)
        let promise3 = Promise(3)
        let promise4 = Promise(4)
        var join2Finished = false
        join(promise2, promise3, promise4)
        .then(on: zalgo) { _ in join2Finished = true }
        XCTAssert(join2Finished, "Join immediately finishes on fulfilled promises")
    }
    
    func testImmediateErrors() {
        let errorPromise = Promise<Void>(error: NSError(domain: "", code: 0, userInfo: nil))
        var joinFinished = false
        join(errorPromise).asVoid()
        .recover(on: zalgo) { _ in joinFinished = true }
        XCTAssert(joinFinished, "Join immediately finishes on rejected promise")
        
        let errorPromise2 = Promise<Void>(error: NSError(domain: "", code: 0, userInfo: nil))
        let errorPromise3 = Promise<Void>(error: NSError(domain: "", code: 0, userInfo: nil))
        let errorPromise4 = Promise<Void>(error: NSError(domain: "", code: 0, userInfo: nil))
        var join2Finished = false
        join(errorPromise2, errorPromise3, errorPromise4).asVoid()
        .recover(on: zalgo) { _ in join2Finished = true }
        XCTAssert(join2Finished, "Join immediately finishes on rejected promises")
    }
    
    func testFulfilledAfterAllResolve() {
        let (promise1, fulfill1, _) = Promise<Void>.pendingPromise()
        let (promise2, fulfill2, _) = Promise<Void>.pendingPromise()
        let (promise3, fulfill3, _) = Promise<Void>.pendingPromise()
        
        var finished = false
        join(promise1, promise2, promise3)
        .then(on: zalgo) { _ in finished = true }
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        fulfill1()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        fulfill2()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        fulfill3()
        XCTAssert(finished, "All promises have resolved")
    }
}

// MARK: - Array Tests
// It's hard to generalize these tests, and easy enough to just copy them whenever one above changes
extension join_test {
    func testImmediatesArray() {
        let successPromise = Promise()
        
        var joinFinished = false
        join([successPromise])
        .then(on: zalgo) { _ in joinFinished = true }
        XCTAssert(joinFinished, "Join immediately finishes on fulfilled promise")
        
        let promise2 = Promise(2)
        let promise3 = Promise(3)
        let promise4 = Promise(4)
        var join2Finished = false
        join([promise2, promise3, promise4])
        .then(on: zalgo) { _ in join2Finished = true }
        XCTAssert(join2Finished, "Join immediately finishes on fulfilled promises")
    }
    
    func testImmediateErrorsArray() {
        let errorPromise = Promise<Void>(error: NSError(domain: "", code: 0, userInfo: nil))
        var joinFinished = false
        join([errorPromise]).asVoid()
        .recover(on: zalgo) { _ in joinFinished = true }
        XCTAssert(joinFinished, "Join immediately finishes on rejected promise")
        
        let errorPromise2 = Promise<Void>(error: NSError(domain: "", code: 0, userInfo: nil))
        let errorPromise3 = Promise<Void>(error: NSError(domain: "", code: 0, userInfo: nil))
        let errorPromise4 = Promise<Void>(error: NSError(domain: "", code: 0, userInfo: nil))
        var join2Finished = false
        join([errorPromise2, errorPromise3, errorPromise4]).asVoid()
        .recover(on: zalgo) { _ in join2Finished = true }
        XCTAssert(join2Finished, "Join immediately finishes on rejected promises")
    }
    
    func testFulfilledAfterAllResolveArray() {
        let (promise1, fulfill1, _) = Promise<Void>.pendingPromise()
        let (promise2, fulfill2, _) = Promise<Void>.pendingPromise()
        let (promise3, fulfill3, _) = Promise<Void>.pendingPromise()
        
        var finished = false
        join([promise1, promise2, promise3])
        .then(on: zalgo) { _ in finished = true }
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        fulfill1()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        fulfill2()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        fulfill3()
        XCTAssert(finished, "All promises have resolved")
    }
}
