import PromiseKit
import Dispatch
import XCTest

class CatchableTests: XCTestCase {

    func testFinally() {
        let finallyQueue = DispatchQueue(label: "\(#file):\(#line)", attributes: .concurrent)

        func helper(error: Error, on queue: DispatchQueue = .main, flags: DispatchWorkItemFlags? = nil) {
            let ex = (expectation(description: ""), expectation(description: ""))
            var x = 0
            Promise<Void>(error: error).catch(policy: .allErrors) { _ in
                XCTAssertEqual(x, 0)
                x += 1
                ex.0.fulfill()
            }.finally(on: queue, flags: flags) {
                if let flags = flags, flags.contains(.barrier) {
                    dispatchPrecondition(condition: .onQueueAsBarrier(queue))
                } else {
                    dispatchPrecondition(condition: .onQueue(queue))
                }
                XCTAssertEqual(x, 1)
                x += 1
                ex.1.fulfill()
            }
            wait(for: [ex.0, ex.1], timeout: 5)
        }

        helper(error: Error.dummy)
        helper(error: Error.cancelled)
        helper(error: Error.dummy, on: finallyQueue)
        helper(error: Error.dummy, on: finallyQueue, flags: .barrier)
    }

    func testCauterize() {
        let ex = expectation(description: "")
        let p = Promise<Void>(error: Error.dummy)

        // cannot test specifically that this outputs to console,
        // but code-coverage will note that the line is run
        p.cauterize()

        p.catch { _ in
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }
}


/// `Promise<Void>.recover`
extension CatchableTests {
    func test__void_specialized_full_recover() {

        func helper(error: Swift.Error) {
            let ex = expectation(description: "")
            Promise<Void>(error: error).recover { _ in }.done(ex.fulfill)
            wait(for: [ex], timeout: 5)
        }

        helper(error: Error.dummy)
        helper(error: Error.cancelled)
    }

    func test__void_specialized_full_recover__fulfilled_path() {
        let ex = expectation(description: "")
        Promise().recover { _ in XCTFail() }.done(ex.fulfill)
        wait(for: [ex], timeout: 5)
    }

    func test__void_specialized_conditional_recover() {
        func helper(policy: CatchPolicy, error: Swift.Error, line: UInt = #line) {
            let ex = expectation(description: "")
            var x = 0
            Promise<Void>(error: error).recover(policy: policy) { err in
                guard x < 1 else { throw err }
                x += 1
            }.done(ex.fulfill).silenceWarning()
            wait(for: [ex], timeout: 5)
        }

        for error in [Error.dummy as Swift.Error, Error.cancelled] {
            helper(policy: .allErrors, error: error)
        }
        helper(policy: .allErrorsExceptCancellation, error: Error.dummy)
    }

    func test__void_specialized_conditional_recover__no_recover() {

        func helper(policy: CatchPolicy, error: Error, line: UInt = #line) {
            let ex = expectation(description: "")
            Promise<Void>(error: error).recover(policy: policy) { err in
                throw err
            }.catch(policy: .allErrors) {
                XCTAssertEqual(error, $0 as? Error)
                ex.fulfill()
            }
            wait(for: [ex], timeout: 5)
        }

        for error in [Error.dummy, Error.cancelled] {
            helper(policy: .allErrors, error: error)
        }
        helper(policy: .allErrorsExceptCancellation, error: Error.dummy)
    }

    func test__void_specialized_conditional_recover__ignores_cancellation_but_fed_cancellation() {
        let ex = expectation(description: "")
        Promise<Void>(error: Error.cancelled).recover(policy: .allErrorsExceptCancellation) { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            XCTAssertEqual(Error.cancelled, $0 as? Error)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }

    func test__void_specialized_conditional_recover__fulfilled_path() {
        let ex = expectation(description: "")
        Promise().recover { _ in
            XCTFail()
        }.catch { _ in
            XCTFail()   // this `catch` to ensure we are calling the `recover` variant we think we are
        }.finally {
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }
}


/// `Promise<T>.recover`
extension CatchableTests {
    func test__full_recover() {

        func helper(error: Swift.Error) {
            let ex = expectation(description: "")
            Promise<Int>(error: error).recover { _ in return .value(2) }.done {
                XCTAssertEqual($0, 2)
                ex.fulfill()
            }
            wait(for: [ex], timeout: 5)
        }

        helper(error: Error.dummy)
        helper(error: Error.cancelled)
    }

    func test__full_recover__fulfilled_path() {
        let ex = expectation(description: "")
        Promise.value(1).recover { _ in XCTFail(); return .value(2) }.done{
            XCTAssertEqual($0, 1)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }


    func test__conditional_recover() {
        func helper(policy: CatchPolicy, error: Swift.Error, line: UInt = #line) {
            let ex = expectation(description: "")
            var x = 0
            Promise<Int>(error: error).recover(policy: policy) { err -> Promise<Int> in
                guard x < 1 else { throw err }
                x += 1
                return .value(x)
            }.done {
                XCTAssertEqual($0, x)
                ex.fulfill()
            }.silenceWarning()
            wait(for: [ex], timeout: 5)
        }

        for error in [Error.dummy as Swift.Error, Error.cancelled] {
            helper(policy: .allErrors, error: error)
        }
        helper(policy: .allErrorsExceptCancellation, error: Error.dummy)
    }

    func test__conditional_recover__no_recover() {

        func helper(policy: CatchPolicy, error: Error, line: UInt = #line) {
            let ex = expectation(description: "")
            Promise<Int>(error: error).recover(policy: policy) { err -> Promise<Int> in
                throw err
            }.catch(policy: .allErrors) {
                XCTAssertEqual(error, $0 as? Error)
                ex.fulfill()
            }
            wait(for: [ex], timeout: 5)
        }

        for error in [Error.dummy, Error.cancelled] {
            helper(policy: .allErrors, error: error)
        }
        helper(policy: .allErrorsExceptCancellation, error: Error.dummy)
    }

    func test__conditional_recover__ignores_cancellation_but_fed_cancellation() {
        let ex = expectation(description: "")
        Promise<Int>(error: Error.cancelled).recover(policy: .allErrorsExceptCancellation) { _ -> Promise<Int> in
            XCTFail()
            return .value(1)
        }.catch(policy: .allErrors) {
            XCTAssertEqual(Error.cancelled, $0 as? Error)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }

    func test__conditional_recover__fulfilled_path() {
        let ex = expectation(description: "")
        Promise.value(1).recover { err -> Promise<Int> in
            XCTFail()
            throw err
        }.done {
            XCTAssertEqual($0, 1)
            ex.fulfill()
        }.catch { _ in
            XCTFail()   // this `catch` to ensure we are calling the `recover` variant we think we are
        }
        wait(for: [ex], timeout: 5)
    }

    func testEnsureThen_Error() {
        let ex = expectation(description: "")

        Promise.value(1).done {
            XCTAssertEqual($0, 1)
            throw Error.dummy
        }.ensureThen {
            after(seconds: 0.01)
        }.catch {
            XCTAssertEqual(Error.dummy, $0 as? Error)
        }.finally {
            ex.fulfill()
        }

        wait(for: [ex], timeout: 5)
    }

    func testEnsureThen_Value() {
        let ex = expectation(description: "")

        Promise.value(1).ensureThen {
            after(seconds: 0.01)
        }.done {
            XCTAssertEqual($0, 1)
        }.catch { _ in
            XCTFail()
        }.finally {
            ex.fulfill()
        }

        wait(for: [ex], timeout: 5)
    }
}

/// `Promise<T>.catch(only:)`
extension CatchableTests {
    func testCatchOnly() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.dummy).catch(only: Error.dummy) { _ in
            x.fulfill()
        }.silenceWarning()

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_PatternMatch_1() {
        let x = expectation(description: "Pattern match only Error.dummy")

        Promise<Int>(error: Error.dummy).catch(only: Error.dummy) { _ in
            x.fulfill()
        }.catch(only: Error.cancelled) { _ in
            XCTFail()
            x.fulfill()
        }.silenceWarning()

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_PatternMatch_2() {
        let x = expectation(description: "Pattern match only Error.dummy")

        Promise<Int>(error: Error.dummy).catch(only: Error.cancelled) { _ in
            XCTFail()
            x.fulfill()
        }.catch(only: Error.dummy) { _ in
            x.fulfill()
        }.silenceWarning()

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_BaseCatchIsNotCalledAfterCatchOnlyExecutes() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.dummy).catch(only: Error.dummy) { _ in
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_BaseCatchIsCalledWhenCatchOnlyDoesNotExecute() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.dummy).catch(only: Error.cancelled) { _ in
            XCTFail()
            x.fulfill()
        }.catch { _ in
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_Type() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.dummy).catch(only: Error.self) { _ in
            x.fulfill()
        }.silenceWarning()

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_Type_Ignored() {
        let x = expectation(description: #file + #function)

        enum Foo: Swift.Error {
            case a
        }

        Promise<Int>(error: Error.dummy).catch(only: Foo.self) { _ in
            XCTFail()
        }.catch { _ in
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_Type_PatternMatch_1() {
        let x = expectation(description: "Pattern match only Error.Type")

        Promise<Int>(error: Error.dummy).catch(only: Error.self) { _ in
            x.fulfill()
        }.catch(only: Error.dummy) { _ in
            XCTFail()
            x.fulfill()
        }.silenceWarning()

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_Type_PatternMatch_2() {
        let x = expectation(description: "Pattern match only Error.dummy")

        Promise<Int>(error: Error.dummy).catch(only: Error.dummy) { _ in
            x.fulfill()
        }.catch(only: Error.self) { _ in
            XCTFail()
            x.fulfill()
        }.silenceWarning()

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_Type_BaseCatchIsNotCalledAfterCatchOnlyExecutes() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.dummy).catch(only: Error.self) { _ in
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_Type_Cancellation_Ignore() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.cancelled).catch(only: Error.self) { _ in
            XCTFail()
            x.fulfill()
        }.catch(policy: .allErrors) { _ in
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_Type_Cancellation_Handle() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.cancelled).catch(only: Error.self, policy: .allErrors) { _ in
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testCatchOnly_Mixed() {
        let x = expectation(description: #file + #function)

        enum Foo: Swift.Error { case bar }

        Promise<Int>(error: Foo.bar).catch(only: Error.dummy) { _ in
            XCTFail()
            x.fulfill()
        }.catch(only: Foo.self) { _ in
            x.fulfill()
        }.silenceWarning()

        wait(for: [x], timeout: 5)
    }
}

/// `Promise<T>.recover(only:)`
extension CatchableTests {
    func testRecoverOnly_Object() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.dummy).recover(only: Error.dummy) { _ in
            return Promise.value(1)
        }.done { _ in
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Object_Ignored() {
        let x = expectation(description: #file + #function)

        Promise.value(1).recover(only: Error.dummy) { _ in
            return Promise(error: Error.dummy)
        }.done { _ in
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Object_PatternMatch() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.cancelled).recover(only: Error.dummy) { _ in
            return Promise.value(1)
        }.done { _ in
            XCTFail()
            x.fulfill()
        }.catch(policy: .allErrors) { _ in
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.dummy).recover(only: Error.self) { _ in
            return Promise.value(1)
        }.done { _ in
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type_Ignored() {
        let x = expectation(description: #file + #function)

        Promise.value(1).recover(only: Error.self) { _ in
            return Promise(error: Error.dummy)
        }.done { _ in
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type_PatternMatch() {
        let x = expectation(description: #file + #function)

        enum Foo: Swift.Error {
            case a
        }

        Promise<Int>(error: Error.dummy).recover(only: Foo.self) { _ in
            Promise.value(1)
        }.done { _ in
            XCTFail()
            x.fulfill()
        }.catch { _ in
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type_Cancellation_Ignore() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.cancelled).recover(only: Error.self) { _ in
            return Promise.value(1)
        }.done { _ in
            XCTFail()
            x.fulfill()
        }.catch(policy: .allErrors) { _ in
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type_Cancellation_Handle() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.cancelled).recover(only: Error.self, policy: .allErrors) { _ in
            return Promise.value(1)
        }.done { _ in
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Chaining() {
        let x = expectation(description: #file + #function)

        enum Foo: Swift.Error { case bar }

        Promise<Int>(error: Error.dummy).recover(only: Foo.self) { _ in
            return Promise(error: Foo.bar)
        }.recover(only: Error.dummy) { _ in
            return Promise.value(1)
        }.done { _ in
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_BaseRecoverIsNotCalledAfterRecoverOnlyExecutes() {
        let x = expectation(description: #file + #function)

        Promise<Int>(error: Error.dummy).recover(only: Error.dummy) { _ in
            return Promise.value(1)
        }.recover { _ in
            return Promise(error: Error.dummy)
        }.done { _ in
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Object_DoesNotReturnSelf() {
        let x = expectation(description: #file + #function)
        var promise: Promise<Void>!
        promise = Promise<Void>(error: Error.dummy).recover(only: Error.dummy) { (_) -> Promise<Void> in
            return promise
        }
        promise.catch { err in
            if case PMKError.returnedSelf = err {
                x.fulfill()
            }
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type_DoesNotReturnSelf() {
        let x = expectation(description: #file + #function)
        var promise: Promise<Void>!
        promise = Promise<Void>(error: Error.dummy).recover(only: Error.self) { _ -> Promise<Void> in
            return promise
        }
        promise.catch { err in
            if case PMKError.returnedSelf = err {
                x.fulfill()
            }
        }

        wait(for: [x], timeout: 5)
    }
}

/// `Promise<Void>.recover(only:)`
extension CatchableTests {
    func testRecoverOnly_Object_Void() {
        let x = expectation(description: #file + #function)

        Promise<Void>(error: Error.dummy).recover(only: Error.dummy) { _ in
            return ()
        }.done {
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Object_Void_Fufilled() {
        let x = expectation(description: #file + #function)

        Promise<Void>.value(()).recover(only: Error.dummy) { _ in
            XCTFail()
            x.fulfill()
        }.done {
            x.fulfill()
        }.silenceWarning()

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Object_Void_Ignored() {
        let x = expectation(description: #file + #function)

        enum Foo: Swift.Error { case bar }

        Promise<Void>(error: Error.dummy).recover(only: Foo.bar) { _ in
            XCTFail()
            x.fulfill()
        }.done {
            XCTFail()
            x.fulfill()
        }.catch { _ in
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type_Void() {
        let x = expectation(description: #file + #function)

        Promise<Void>(error: Error.dummy).recover(only: Error.self) { _ in }.done {
            x.fulfill()
        }.catch { _ in
            XCTFail()
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type_Void_Fufilled() {
        let x = expectation(description: #file + #function)

        Promise<Void>.value(()).recover(only: Error.self) { _ in
            XCTFail()
            x.fulfill()
        }.done {
            x.fulfill()
        }.silenceWarning()

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type_Void_Ignored() {
        let x = expectation(description: #file + #function)

        enum Foo: Swift.Error { case bar }

        Promise<Void>(error: Error.dummy).recover(only: Foo.self) { _ in
            XCTFail()
            x.fulfill()
        }.done {
            XCTFail()
            x.fulfill()
        }.catch { _ in
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type_Void_Rethrow() {
        let x = expectation(description: #file + #function)

        Promise<Void>(error: Error.dummy).recover(only: Error.self) { _ in
            throw Error.dummy
        }.done {
            XCTFail()
            x.fulfill()
        }.catch { _ in
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }

    func testRecoverOnly_Type_Void_Cancellation_Ignore() {
        let x = expectation(description: #file + #function)

        Promise<Void>(error: Error.cancelled).recover(only: Error.self) { _ in }.done {
            XCTFail()
            x.fulfill()
        }.catch(policy: .allErrors) { _ in
            x.fulfill()
        }

        wait(for: [x], timeout: 5)
    }
}

private enum Error: CancellableError {
    case dummy
    case cancelled

    var isCancelled: Bool {
        return self == Error.cancelled
    }
}
