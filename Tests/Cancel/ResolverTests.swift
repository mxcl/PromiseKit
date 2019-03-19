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

        func fetchWithCompletionBlock(block: @escaping(Int?, Error?) -> Void) {
            after(.milliseconds(20)).done {
                block(self.value, self.error)
            }
        }

        func fetchWithCompletionBlock2(block: @escaping(Error?, Int?) -> Void) {
            after(.milliseconds(20)).done {
                block(self.error, self.value)
            }
        }

        func fetchWithCompletionBlock3(block: @escaping(Int, Error?) -> Void) {
            after(.milliseconds(20)).done {
                block(self.value ?? -99, self.error)
            }
        }

        func fetchWithCompletionBlock4(block: @escaping(Error?) -> Void) {
            after(.milliseconds(20)).done {
                block(self.error)
            }
        }
    }

    fileprivate class CancellableKittenFetcher: Cancellable {
        func cancel() {
            finalizer?.cancel()
        }
        
        var isCancelled: Bool {
            return finalizer?.isCancelled ?? false
        }
        
        let value: Int?
        let error: Swift.Error?
        var finalizer: CancellableFinalizer?
        
        init(value: Int?, error: Swift.Error?) {
            self.value = value
            self.error = error
        }
        
        func fetchWithCompletionBlock(block: @escaping(Int?, Swift.Error?) -> Void) {
            finalizer = after(.milliseconds(20)).cancellize().done {_ in
                block(self.value, self.error)
            }.catch(policy: .allErrors) {
                block(nil, $0)
            }
        }
        
        func fetchWithCompletionBlock2(block: @escaping(Swift.Error?, Int?) -> Void) {
            finalizer = after(.milliseconds(20)).cancellize().done {
                block(self.error, self.value)
            }.catch(policy: .allErrors) {
                block($0, nil)
            }
        }
        
        func fetchWithCompletionBlock3(block: @escaping(Int, Swift.Error?) -> Void) {
            finalizer = after(.milliseconds(20)).cancellize().done {
                block(self.value ?? -99, self.error)
            }.catch(policy: .allErrors) {
                block(-99, $0)
            }
        }
        
        func fetchWithCompletionBlock4(block: @escaping(Swift.Error?) -> Void) {
            finalizer = after(.milliseconds(20)).cancellize().done {
                block(self.error)
            }.catch(policy: .allErrors) {
                block($0)
            }
        }
    }
    
   func testSuccess() {
        let ex = expectation(description: "")
        let kittenFetcher = KittenFetcher(value: 2, error: nil)
        CancellablePromise { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.done {
            XCTFail()
            XCTAssertEqual($0, 2)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        waitForExpectations(timeout: 1)
    }

    func testError() {
        let ex = expectation(description: "")
        
        let kittenFetcher = KittenFetcher(value: nil, error: Error.test)
        CancellablePromise { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations(timeout: 1)
    }
    
    func testErrorNoDelay() {
        let ex = expectation(description: "")
        
        CancellablePromise<Int> { seal in
            seal.resolve(nil, Error.test)
        }.catch(policy: .allErrors) { error in
            defer { ex.fulfill() }
            guard case Error.test = error else {
                return XCTFail()
            }
        }.cancel()
        
        waitForExpectations(timeout: 1)
    }
    
    func testErrorCancellableKitten() {
        let ex = expectation(description: "")
        
        let kittenFetcher = CancellableKittenFetcher(value: nil, error: Error.test)
        CancellablePromise(cancellable: kittenFetcher) { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations(timeout: 1)
    }
    
    func testInvalidCallingConvention() {
        let ex = expectation(description: "")

        let kittenFetcher = KittenFetcher(value: nil, error: nil)
        CancellablePromise { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 1)
    }

    func testInvalidCallingConventionCancellableKitten() {
        let ex = expectation(description: "")

        let kittenFetcher = CancellableKittenFetcher(value: nil, error: nil)
        CancellablePromise<Any>(cancellable: kittenFetcher) { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.catch(policy: .allErrors) { (error: Swift.Error) -> Void in
            error.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 1)
    }

    func testInvertedCallingConvention() {
        let ex = expectation(description: "")
        let kittenFetcher = KittenFetcher(value: 2, error: nil)
        CancellablePromise { seal in
            kittenFetcher.fetchWithCompletionBlock2(block: seal.resolve)
        }.done {
            XCTFail()
            XCTAssertEqual($0, 2)
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 1)
    }

    func testInvertedCallingConventionCancellableKitten() {
        let ex = expectation(description: "")
        let kittenFetcher = CancellableKittenFetcher(value: 2, error: nil)
        CancellablePromise(cancellable: kittenFetcher) { seal in
            kittenFetcher.fetchWithCompletionBlock2(block: seal.resolve)
        }.done {
            XCTFail()
            XCTAssertEqual($0, 2)
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 1)
    }

    func testNonOptionalFirstParameter() {
        let ex1 = expectation(description: "")
        let kf1 = KittenFetcher(value: 2, error: nil)
        CancellablePromise { seal in
            kf1.fetchWithCompletionBlock3(block: seal.resolve)
        }.done {
            XCTFail()
            XCTAssertEqual($0, 2)
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? ex1.fulfill() : XCTFail()
        }.cancel()

        let ex2 = expectation(description: "")
        let kf2 = KittenFetcher(value: -100, error: Error.test)
        CancellablePromise { seal in
            kf2.fetchWithCompletionBlock3(block: seal.resolve)
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? ex2.fulfill() : XCTFail()
        }.cancel()

        wait(for: [ex1, ex2] ,timeout: 1)
    }

    func testNonOptionalFirstParameterCancellableKitten() {
        let ex1 = expectation(description: "")
        let kf1 = CancellableKittenFetcher(value: 2, error: nil)
        CancellablePromise(cancellable: kf1) { seal in
            kf1.fetchWithCompletionBlock3(block: seal.resolve)
        }.done {
            XCTAssertEqual($0, 2)
            ex1.fulfill()
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? ex1.fulfill() : XCTFail()
        }.cancel()

        let ex2 = expectation(description: "")
        let kf2 = CancellableKittenFetcher(value: -100, error: Error.test)
        CancellablePromise(cancellable: kf2) { seal in
            kf2.fetchWithCompletionBlock3(block: seal.resolve)
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? ex2.fulfill() : XCTFail()
        }.cancel()

        wait(for: [ex1, ex2] ,timeout: 1)
    }

#if swift(>=3.1)
    func testVoidCompletionValue() {
        let ex1 = expectation(description: "")
        let kf1 = KittenFetcher(value: nil, error: nil)
        CancellablePromise { seal in
            kf1.fetchWithCompletionBlock4(block: seal.resolve)
        }.done(ex1.fulfill).catch(policy: .allErrors) { error in
            error.isCancelled ? ex1.fulfill() : XCTFail()
        }.cancel()

        let ex2 = expectation(description: "")
        let kf2 = KittenFetcher(value: nil, error: Error.test)
        CancellablePromise { seal in
            kf2.fetchWithCompletionBlock4(block: seal.resolve)
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? ex2.fulfill() : XCTFail()
        }.cancel()

        wait(for: [ex1, ex2], timeout: 1)
    }

    func testVoidCompletionValueCancellableKitten() {
        let ex1 = expectation(description: "")
        let kf1 = CancellableKittenFetcher(value: nil, error: nil)
        CancellablePromise(cancellable: kf1) { seal in
            kf1.fetchWithCompletionBlock4(block: seal.resolve)
        }.done(ex1.fulfill).catch(policy: .allErrors) { error in
            error.isCancelled ? ex1.fulfill() : XCTFail()
        }.cancel()

        let ex2 = expectation(description: "")
        let kf2 = CancellableKittenFetcher(value: nil, error: Error.test)
        CancellablePromise(cancellable: kf2) { seal in
            kf2.fetchWithCompletionBlock4(block: seal.resolve)
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? ex2.fulfill() : XCTFail()
        }.cancel()

        wait(for: [ex1, ex2], timeout: 1)
    }
#endif

    func testIsFulfilled() {
        let p1 = Promise.value(()).cancellize()
        p1.cancel()
        
        var success1 = false
        if let r1 = p1.result, case .success = r1 {
            success1 = true
        }
        XCTAssertTrue(success1)
        XCTAssertTrue(p1.isCancelled)
        
        let p2 = CancellablePromise<Int>(error: Error.test)
        p2.cancel()
        var success2 = true
        if let r2 = p2.result {
            if case .success = r2 {
                success2 = true
            } else {
                success2 = false
            }
        }
        XCTAssertFalse(success2)
        XCTAssertTrue(p2.isCancelled)
    }

    func testPendingPromiseDeallocated() {

        // NOTE this doesn't seem to register the `deinit` as covered :(
        // BUT putting a breakpoint in the deinit CLEARLY shows it getting covered…

        class Foo {
            let p = CancellablePromise<Void>.pending()
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
        wait(for: [ex], timeout: 1)
    }
}

private enum Error: Swift.Error {
    case test
}
