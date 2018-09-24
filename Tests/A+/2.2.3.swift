import PromiseKit
import XCTest

class Test223: XCTestCase {
    func test() {
        describe("2.2.3: If `onRejected` is a function,") {
            describe("2.2.3.1: it must be called after `promise` is rejected, with `promise`’s rejection reason as its first argument.") {
                testRejected { promise, expectation, sentinel in
                    promise.catch { error in
                        if case Error.sentinel(let value) = error {
                            XCTAssertEqual(value, sentinel)
                        } else {
                            XCTFail()
                        }
                        expectation.fulfill()
                    }
                }
            }
            describe("2.2.3.2: it must not be called before `promise` is rejected") {
                specify("rejected after a delay") { d, expectation in
                    var called = false
                    d.promise.catch { _ in
                        called = true
                        expectation.fulfill()
                    }
                    after(ticks: 1) {
                        XCTAssertFalse(called)
                        d.reject(Error.dummy)
                    }
                }
                specify("never rejected") { d, expectation in
                    d.promise.catch { _ in XCTFail() }
                    after(ticks: 1, execute: expectation.fulfill)
                }
            }
            describe("2.2.3.3: it must not be called more than once.") {
                specify("already-rejected") { d, expectation in
                    var timesCalled = 0
                    Promise<Int>(error: Error.dummy).catch { _ in
                        XCTAssertEqual(++timesCalled, 1)
                    }
                    after(ticks: 2) {
                        XCTAssertEqual(timesCalled, 1)
                        expectation.fulfill()
                    }
                }
                specify("trying to reject a pending promise more than once, immediately") { d, expectation in
                    d.promise.catch{_ in expectation.fulfill() }
                    d.reject(Error.dummy)
                    d.reject(Error.dummy)
                }
                specify("trying to reject a pending promise more than once, delayed") { d, expectation in
                    d.promise.catch{_ in expectation.fulfill() }
                    after(ticks: 1) {
                        d.reject(Error.dummy)
                        d.reject(Error.dummy)
                    }
                }
                specify("trying to reject a pending promise more than once, immediately then delayed") { d, expectation in
                    d.promise.catch{_ in expectation.fulfill() }
                    d.reject(Error.dummy)
                    after(ticks: 1) {
                        d.reject(Error.dummy)
                    }
                }
                specify("when multiple `then` calls are made, spaced apart in time") { d, expectation in
                    let mk = { self.expectation(description: "") }
                    let ex = (expectation, mk(), mk(), mk())

                    do {
                        d.promise.catch{ _ in ex.0.fulfill() }
                    }
                    after(ticks: 1) {
                        d.promise.catch{ _ in ex.1.fulfill() }
                    }
                    after(ticks: 2) {
                        d.promise.catch{ _ in ex.2.fulfill() }
                    }
                    after(ticks: 3) {
                        d.reject(Error.dummy)
                        ex.3.fulfill()
                    }
                }
                specify("when `then` is interleaved with rejection") { d, expectation in
                    let ex = (expectation, self.expectation(description: ""))
                    d.promise.catch{ _ in ex.0.fulfill() }
                    d.reject(Error.dummy)
                    d.promise.catch{ _ in ex.1.fulfill() }
                }
            }
        }
    }
}
