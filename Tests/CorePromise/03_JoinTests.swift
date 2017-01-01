//  Created by Austin Feight on 3/19/16.
//  Copyright © 2016 Max Howell. All rights reserved.

import PromiseKit
import XCTest

class JoinTests: XCTestCase {
    func testImmediates() {
        let successPromise = Promise()

        var joinFinished = false
        when(resolved: successPromise).then(on: nil) { _ in joinFinished = true }
        XCTAssert(joinFinished, "Join immediately finishes on fulfilled promise")
        
        let promise2 = Promise(2)
        let promise3 = Promise(3)
        let promise4 = Promise(4)
        var join2Finished = false
        when(resolved: promise2, promise3, promise4).then(on: nil) { _ in join2Finished = true }
        XCTAssert(join2Finished, "Join immediately finishes on fulfilled promises")
    }
    
    func testImmediateErrors() {
        enum E: Error { case dummy }

        let errorPromise = Promise<Void>(error: E.dummy)
        var joinFinished = false
        when(resolved: errorPromise).then(on: nil) { _ in joinFinished = true }
        XCTAssert(joinFinished, "Join immediately finishes on rejected promise")
        
        let errorPromise2 = Promise<Void>(error: E.dummy)
        let errorPromise3 = Promise<Void>(error: E.dummy)
        let errorPromise4 = Promise<Void>(error: E.dummy)
        var join2Finished = false
        when(resolved: errorPromise2, errorPromise3, errorPromise4).then(on: nil) { _ in join2Finished = true }
        XCTAssert(join2Finished, "Join immediately finishes on rejected promises")
    }
    
    func testFulfilledAfterAllResolve() {
        let (promise1, pipe1) = Promise<Void>.pending()
        let (promise2, pipe2) = Promise<Void>.pending()
        let (promise3, pipe3) = Promise<Void>.pending()
        
        var finished = false
        let ex = expectation(description: "")

        let root = when(resolved: promise1, promise2, promise3)
        root.then{ _ in finished = true }
        root.ensure(that: ex.fulfill)

        XCTAssertFalse(finished, "Not all promises have resolved")
        
        pipe1.fulfill()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        pipe2.fulfill()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        pipe3.fulfill()
        XCTAssertFalse(finished, "All promises have resolved, but promises always execute on the next execution-context")

        waitForExpectations(timeout: 1)

        XCTAssert(finished, "All promises have resolved")
    }
}
