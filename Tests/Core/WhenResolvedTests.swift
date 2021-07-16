//  Created by Austin Feight on 3/19/16.
//  Copyright © 2016 Max Howell. All rights reserved.

@testable import PromiseKit
import XCTest

class JoinTests: XCTestCase {
    func testImmediates() {
        let successPromise = Promise()

        var joinFinished = false
        when(resolved: [successPromise]).done(on: nil) { joinFinished = true }
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
        
        seal1.fulfill()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        seal2.fulfill()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        seal3.fulfill()
        XCTAssert(finished, "All promises have resolved")
    }
    
    func testErrorHandlerDoesFire() {
        let ex = expectation(description: "")
        let p1 = Promise<Void>(error: TestError.dummy)
        let p2 = after(.milliseconds(100))
        when(resolved: p1, p2).done { _ in throw TestError.stub }.catch { error in
            XCTAssertTrue(error as? TestError == TestError.stub)
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testAllRejected() {
        let ex = expectation(description: "")
        let p1 = Promise<Void>(error: TestError.dummy)
        let p2 = Promise<Void>(error: TestError.straggler)
        let p3 = Promise<Void>(error: TestError.stub)
        
        when(resolved: p1, p2, p3).done { r1, r2, r3 in
            XCTAssertTrue(r1.error! as! TestError == TestError.dummy)
            XCTAssertTrue(r2.error! as! TestError == TestError.straggler)
            XCTAssertTrue(r3.error! as! TestError == TestError.stub)
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testMixedThenables() {
        let ex = expectation(description: "")
        let p1 = Promise.value(2)
        let g1 = Guarantee.value(4)
        
        when(resolved: p1, g1).done { r1, r2 in
            XCTAssertEqual(try r1.get(), 2)
            XCTAssertEqual(r2, 4)
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testMixedThenablesWithMixedResults() {
        let ex = expectation(description: "")
        let p1 = Promise<Void>(error: TestError.dummy)
        let p2 = Promise.value(2)
        let g1 = Guarantee.value("abc")
        
        when(resolved: p1, p2, g1).done { r1, r2, r3 in
            XCTAssertTrue(r1.error! as! TestError == TestError.dummy)
            XCTAssertEqual(try r2.get(), 2)
            XCTAssertEqual(r3, "abc")
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
}

private enum TestError: Error {
    case dummy
    case straggler
    case stub
}
