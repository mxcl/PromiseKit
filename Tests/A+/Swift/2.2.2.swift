import PromiseKit
import XCTest

class Test222: XCTestCase {
    func test() {
        describe("2.2.2: If `onFulfilled` is a function,") {
            describe("2.2.2.1: it must be called after `promise` is fulfilled, with `promise`’s fulfillment value as its first argument.") {
                testFulfilled { promise, expectation, sentinel in
                    promise.done {
                        XCTAssertEqual(sentinel, $0)
                        expectation.fulfill()
                    }.silenceWarning()
                }
            }

            describe("2.2.2.2: it must not be called before `promise` is fulfilled") {
                specify("fulfilled after a delay") { d, expectation in
                    var called = false
                    d.promise.done {
                        called = true
                        expectation.fulfill()
                    }.silenceWarning()
                    after(ticks: 5) {
                        XCTAssertFalse(called)
                        d.fulfill()
                    }
                }
                specify("never fulfilled") { d, expectation in
                    d.promise.done{ XCTFail() }.silenceWarning()
                    after(ticks: 1000, execute: expectation.fulfill)
                }
            }

            describe("2.2.2.3: it must not be called more than once.") {
                specify("already-fulfilled") { _, expectation in
                    let ex = (expectation, mkex())
                    Promise().done {
                        ex.0.fulfill()
                    }.silenceWarning()
                    after(ticks: 1000) {
                        ex.1.fulfill()
                    }
                }
                specify("trying to fulfill a pending promise more than once, immediately") { d, expectation in
                    d.promise.done(expectation.fulfill).silenceWarning()
                    d.fulfill()
                    d.fulfill()
                }
                specify("trying to fulfill a pending promise more than once, delayed") { d, expectation in
                    d.promise.done(expectation.fulfill).silenceWarning()
                    after(ticks: 5) {
                        d.fulfill()
                        d.fulfill()
                    }
                }
                specify("trying to fulfill a pending promise more than once, immediately then delayed") { d, expectation in
                    let ex = (expectation, mkex())
                    d.promise.done(ex.0.fulfill).silenceWarning()
                    d.fulfill()
                    after(ticks: 5) {
                        d.fulfill()
                    }
                    after(ticks: 10, execute: ex.1.fulfill)
                }
                specify("when multiple `then` calls are made, spaced apart in time") { d, expectation in
                    let ex = (expectation, self.expectation(description: ""), self.expectation(description: ""), self.expectation(description: ""))

                    do {
                        d.promise.done(ex.0.fulfill).silenceWarning()
                    }
                    after(ticks: 5) {
                        d.promise.done(ex.1.fulfill).silenceWarning()
                    }
                    after(ticks: 10) {
                        d.promise.done(ex.2.fulfill).silenceWarning()
                    }
                    after(ticks: 15) {
                        d.fulfill()
                        ex.3.fulfill()
                    }
                }
                specify("when `then` is interleaved with fulfillment") { d, expectation in
                    let ex = (expectation, self.expectation(description: ""), self)

                    d.promise.done(ex.0.fulfill).silenceWarning()
                    d.fulfill()
                    d.promise.done(ex.1.fulfill).silenceWarning()
                }
            }
        }
    }
}
