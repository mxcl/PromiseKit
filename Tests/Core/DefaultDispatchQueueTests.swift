//
//  PMKDefaultDispatchQueue.test.swift
//  PromiseKit
//
//  Created by David Rodriguez on 4/14/16.
//  Copyright © 2016 Max Howell. All rights reserved.
//

import class Foundation.Thread
@testable import PromiseKit
import Dispatch
import XCTest

private enum Error: Swift.Error { case dummy }


class PMKDefaultDispatchQueueTest: XCTestCase {

    let myQueue = DispatchQueue(label: "myQueue")

    override func setUp() {
        conf.testMode = true  // Allow free setting of default dispatchers
        conf.setDefaultDispatchers(body: myQueue, tail: myQueue)
    }

    override func tearDown() {
        conf.setDefaultDispatchers(body: .main, tail: .main)
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
