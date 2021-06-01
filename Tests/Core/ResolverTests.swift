import PromiseKit
import XCTest

class WrapTests: XCTestCase {
    fileprivate class KittenFetcher {
        let value: Int?
        let error: Error?

        init(value: Int?, error: Error?) {
            self.value = value
            self.error = error
        }

        func fetchWithCompletionBlock(block: @escaping(Int?, Swift.Error?) -> Void) {
            after(.milliseconds(20)).done {
                block(self.value, self.error)
            }
        }

        func fetchWithCompletionBlock2(block: @escaping(Error?, Int?) -> Void) {
            after(.milliseconds(20)).done {
                block(self.error, self.value)
            }
        }

        func fetchWithCompletionBlock3(block: @escaping(Int, Swift.Error?) -> Void) {
            after(.milliseconds(20)).done {
                block(self.value ?? -99, self.error)
            }
        }

        func fetchWithCompletionBlock4(block: @escaping(Error?) -> Void) {
            after(.milliseconds(20)).done {
                block(self.error)
            }
        }

        func fetchWithCompletionBlock5(block: @escaping(Swift.Result<Int, Swift.Error>) -> Void) {
            after(.milliseconds(20)).done {
                if let value = self.value {
                    block(.success(value))
                } else {
                    block(.failure(self.error!))
                }
            }
        }
    }

    func testSuccess() {
        let ex = expectation(description: "")
        let kittenFetcher = KittenFetcher(value: 2, error: nil)
        Promise { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.done {
            XCTAssertEqual($0, 2)
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations(timeout: 1)
    }

    func testError() {
        let ex = expectation(description: "")

        let kittenFetcher = KittenFetcher(value: nil, error: Error.test)
        Promise { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.catch { error in
            defer { ex.fulfill() }
            guard case Error.test = error else {
                return XCTFail()
            }
        }

        waitForExpectations(timeout: 1)
    }

    func testInvalidCallingConvention() {
        let ex = expectation(description: "")

        let kittenFetcher = KittenFetcher(value: nil, error: nil)
        Promise { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.catch { error in
            defer { ex.fulfill() }
            guard case PMKError.invalidCallingConvention = error else {
                return XCTFail()
            }
        }

        waitForExpectations(timeout: 1)
    }

    func testInvertedCallingConvention() {
        let ex = expectation(description: "")
        let kittenFetcher = KittenFetcher(value: 2, error: nil)
        Promise { seal in
            kittenFetcher.fetchWithCompletionBlock2(block: seal.resolve)
        }.done {
            XCTAssertEqual($0, 2)
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations(timeout: 1)

    }

    func testNonOptionalFirstParameter() {
        let ex1 = expectation(description: "")
        let kf1 = KittenFetcher(value: 2, error: nil)
        Promise { seal in
            kf1.fetchWithCompletionBlock3(block: seal.resolve)
        }.done {
            XCTAssertEqual($0, 2)
            ex1.fulfill()
        }.silenceWarning()

        let ex2 = expectation(description: "")
        let kf2 = KittenFetcher(value: -100, error: Error.test)
        Promise { seal in
            kf2.fetchWithCompletionBlock3(block: seal.resolve)
        }.catch { _ in ex2.fulfill() }

        wait(for: [ex1, ex2] ,timeout: 1)
    }

    func testVoidCompletionValue() {
        let ex1 = expectation(description: "")
        let kf1 = KittenFetcher(value: nil, error: nil)
        Promise { seal in
            kf1.fetchWithCompletionBlock4(block: seal.resolve)
        }.done(ex1.fulfill).silenceWarning()

        let ex2 = expectation(description: "")
        let kf2 = KittenFetcher(value: nil, error: Error.test)
        Promise { seal in
            kf2.fetchWithCompletionBlock4(block: seal.resolve)
        }.catch { _ in ex2.fulfill() }

        wait(for: [ex1, ex2], timeout: 1)
    }

    func testSwiftResultSuccess() {
    #if swift(>=5.0)
        let ex = expectation(description: "")
        let kittenFetcher = KittenFetcher(value: 2, error: nil)
        Promise<Int> { seal in
            kittenFetcher.fetchWithCompletionBlock5(block: seal.resolve)
        }.done {
            XCTAssertEqual($0, 2)
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations(timeout: 1)
    #endif
    }

    func testSwiftResultError() {
    #if swift(>=5.0)
        let ex = expectation(description: "")

        let kittenFetcher = KittenFetcher(value: nil, error: Error.test)
        Promise { seal in
            kittenFetcher.fetchWithCompletionBlock5(block: seal.resolve)
        }.catch { error in
            defer { ex.fulfill() }
            guard case Error.test = error else {
                return XCTFail()
            }
        }

        waitForExpectations(timeout: 1)
    #endif
    }

    func testIsFulfilled() {
        XCTAssertNotNil(try? Promise.value(()).result?.get())
        XCTAssertNil(try? Promise<Int>(error: Error.test).result?.get())
    }

    func testPendingPromiseDeallocated() {

        // NOTE this doesn't seem to register the `deinit` as covered :(
        // BUT putting a breakpoint in the deinit CLEARLY shows it getting covered…

        class Foo {
            let p = Promise<Void>.pending()
            var ex: XCTestExpectation!

            deinit {
                after(.milliseconds(100)).done(ex.fulfill)
            }
        }

        let ex = expectation(description: "")
        do {
            // for code coverage report for `Resolver.deinit` warning
            let foo = Foo()
            foo.ex = ex
        }
        wait(for: [ex], timeout: 10)
    }

    func testVoidResolverFulfillAmbiguity() {
        // reference: https://github.com/mxcl/PromiseKit/issues/990

        func foo(success: () -> Void, failure: (Error) -> Void) {
            success()
        }

        func bar() -> Promise<Void> {
            return Promise<Void> { (seal: Resolver<Void>) in
                foo(success: seal.fulfill, failure: seal.reject)
            }
        }

        let ex = expectation(description: "")
        bar().done(ex.fulfill).cauterize()
        wait(for: [ex], timeout: 10)

    #if swift(>=5.2)
        // ^^ ambiguous in Swift 5.0 & 5.1, testing again in next version
        let ex2 = expectation(description: "")
        Guarantee<Void> { seal in
            after(.microseconds(10)).done(seal)
        }.done(ex2.fulfill)
        wait(for: [ex2], timeout: 10)
    #endif
    }
}

private enum Error: Swift.Error {
    case test
}
