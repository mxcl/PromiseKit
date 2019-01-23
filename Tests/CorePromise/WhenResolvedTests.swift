//  Created by Austin Feight on 3/19/16.
//  Copyright © 2016 Max Howell. All rights reserved.

import PromiseKit
import XCTest

class JoinTests: XCTestCase {
    func testImmediates() {
        let successPromise = Promise()

        var joinFinished = false
        when(resolved: successPromise).done(on: nil) { _ in joinFinished = true }
        XCTAssert(joinFinished, "Join immediately finishes on fulfilled promise")
        
        let promise2 = Promise.value(2)
        let promise3 = Promise.value(3)
        let promise4 = Promise.value(4)
        var join2Finished = false
        when(resolved: promise2, promise3, promise4).done(on: nil) { _ in join2Finished = true }
        XCTAssert(join2Finished, "Join immediately finishes on fulfilled promises")
    }

    func testFulfilledAfterAllResolve() {
        let (promise1, seal1) = Promise<Void>.pending()
        let (promise2, seal2) = Promise<Void>.pending()
        let (promise3, seal3) = Promise<Void>.pending()
        
        var finished = false
        when(resolved: promise1, promise2, promise3).done(on: nil) { _ in finished = true }
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        seal1.fulfill_()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        seal2.fulfill_()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        seal3.fulfill_()
        XCTAssert(finished, "All promises have resolved")
    }
}
