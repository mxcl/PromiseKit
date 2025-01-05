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
            wait(for: [ex.0, ex.1], timeout: 10)
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
        wait(for: [ex], timeout: 1)
    }
}


/// `Promise<Void>.recover`
extension CatchableTests {
    func test__void_specialized_full_recover() {

        func helper(error: Swift.Error) {
            let ex = expectation(description: "")
            Promise<Void>(error: error).recover { _ in }.done(ex.fulfill)
            wait(for: [ex], timeout: 10)
        }

        helper(error: Error.dummy)
        helper(error: Error.cancelled)
    }

    func test__void_specialized_full_recover__fulfilled_path() {
        let ex = expectation(description: "")
        Promise().recover { _ in XCTFail() }.done(ex.fulfill)
        wait(for: [ex], timeout: 10)
    }

    func test__void_specialized_conditional_recover() {
        func helper(policy: CatchPolicy, error: Swift.Error, line: UInt = #line) {
            let ex = expectation(description: "")
            var x = 0
            Promise<Void>(error: error).recover(policy: policy) { err in
                guard x < 1 else { throw err }
                x += 1
            }.done(ex.fulfill).silenceWarning()
            wait(for: [ex], timeout: 10)
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
            wait(for: [ex], timeout: 10)
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
        wait(for: [ex], timeout: 10)
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
        wait(for: [ex], timeout: 10)
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
            wait(for: [ex], timeout: 10)
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
        wait(for: [ex], timeout: 10)
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
            wait(for: [ex], timeout: 10)
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
            wait(for: [ex], timeout: 10)
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
        wait(for: [ex], timeout: 10)
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
        wait(for: [ex], timeout: 10)
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

        wait(for: [ex], timeout: 10)
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

        wait(for: [ex], timeout: 10)
    }
}

private enum Error: CancellableError {
    case dummy
    case cancelled

    var isCancelled: Bool {
        return self == Error.cancelled
    }
}
