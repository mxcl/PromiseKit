//  Created by Austin Feight on 3/19/16.
//  Copyright © 2016 Max Howell. All rights reserved.

import PromiseKit
import XCTest

class JoinTests: XCTestCase {
    func testImmediates() {
        let successPromise = CancellablePromise()

        var joinFinished = false
        cancellableWhen(resolved: successPromise).done(on: nil) { _ in joinFinished = true }.cancel()
        XCTAssert(joinFinished, "Join immediately finishes on fulfilled promise")
        
        let promise2 = Promise.value(2)
        let promise3: CancellablePromise = cancellable(Promise.value(3))
        let promise4 = Promise.value(4)
        var join2Finished = false
        cancellableWhen(resolved: CancellablePromise(promise2), promise3, CancellablePromise(promise4)).done(on: nil) { _ in join2Finished = true }.cancel()
        XCTAssert(join2Finished, "Join immediately finishes on fulfilled promises")
    }

   func testFulfilledAfterAllResolve() {
        let (promise1, seal1) = CancellablePromise<Void>.pending()
        let (promise2, seal2) = Promise<Void>.pending()
        let (promise3, seal3) = CancellablePromise<Void>.pending()
        
        var finished = false
        let promise = cancellableWhen(resolved: promise1, CancellablePromise(promise2), promise3).done(on: nil) { _ in finished = true }
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        seal1.fulfill(())
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        seal2.fulfill(())
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        seal3.fulfill(())
        promise.cancel()
        XCTAssert(finished, "All promises have resolved")
    }

    func testCancelledAfterAllResolve() {
        let (promise1, seal1) = CancellablePromise<Void>.pending()
        let (promise2, seal2) = Promise<Void>.pending()
        let (promise3, seal3) = CancellablePromise<Void>.pending()
        
        var cancelled = false
        let ex = expectation(description: "")
        let cp2 = CancellablePromise(promise2)
        cancellableWhen(resolved: promise1, cp2, promise3).done(on: nil) { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            cancelled = $0.isCancelled
            cancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        seal1.fulfill(())
        seal2.fulfill(())
        seal3.fulfill(())
        
        waitForExpectations(timeout: 1)

        XCTAssert(cancelled, "Cancel error caught")
        XCTAssert(promise1.isCancelled, "Promise 1 cancelled")
        XCTAssert(cp2.isCancelled, "Promise 2 cancelled")
        XCTAssert(promise3.isCancelled, "Promise 3 cancelled")
    }
}
