//
//  PMKDefaultDispatchQueue.test.swift
//  PromiseKit
//
//  Created by David Rodriguez on 4/14/16.
//  Copyright © 2016 Max Howell. All rights reserved.
//

import class Foundation.Thread
import PromiseKit
import Dispatch
import XCTest

private enum Error: Swift.Error { case dummy }


class PMKDefaultDispatchQueueTest: XCTestCase {

    let myQueue = DispatchQueue(label: "myQueue")

    override func setUp() {
        // can actually only set the default queue once
        // - See: PMKSetDefaultDispatchQueue
        conf.Q = (myQueue, myQueue)
    }

    override func tearDown() {
        conf.Q = (.main, .main)
    }

    func testOverrodeDefaultThenQueue() {
        let ex = expectation(description: "resolving")

        Promise.value(1).then { _ -> Promise<Void> in
            ex.fulfill()
            XCTAssertFalse(Thread.isMainThread)
            return Promise()
        }.silenceWarning()

        XCTAssertTrue(Thread.isMainThread)

        waitForExpectations(timeout: 1)
    }

    func testOverrodeDefaultCatchQueue() {
        let ex = expectation(description: "resolving")

        Promise<Int>(error: Error.dummy).catch { _ in
            ex.fulfill()
            XCTAssertFalse(Thread.isMainThread)
        }

        XCTAssertTrue(Thread.isMainThread)

        waitForExpectations(timeout: 1)
    }

    func testOverrodeDefaultAlwaysQueue() {
        let ex = expectation(description: "resolving")

        Promise.value(1).ensure {
            ex.fulfill()
            XCTAssertFalse(Thread.isMainThread)
        }.silenceWarning()

        XCTAssertTrue(Thread.isMainThread)

        waitForExpectations(timeout: 1)
    }
}
