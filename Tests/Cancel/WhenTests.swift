import PromiseKit
import Dispatch
import XCTest

class WhenTests: XCTestCase {

    func testEmpty() {
        let e1 = expectation(description: "")
        let promises: [CancellablePromise<Void>] = []
        when(fulfilled: promises).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e1.fulfill() : XCTFail()
        }.cancel()

        let e2 = expectation(description: "")
        when(resolved: promises).done { _ in
            XCTFail()
            e2.fulfill()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e2.fulfill() : XCTFail()
        }.cancel()

        wait(for: [e1, e2], timeout: 1)
    }

    func testInt() {
        let e1 = expectation(description: "")
        let p1 = cancellable(Promise.value(1))
        let p2 = cancellable(Promise.value(2))
        let p3 = cancellable(Promise.value(3))
        let p4 = cancellable(Promise.value(4))

        when(fulfilled: [p1, p2, p3, p4]).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e1.fulfill() : XCTFail()
        }.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testIntAlt() {
        let e1 = expectation(description: "")
        let p1 = cancellable(Promise.value(1))
        let p2 = cancellable(Promise.value(2))
        let p3 = cancellable(Promise.value(3))
        let p4 = cancellable(Promise.value(4))

        when(fulfilled: p1, p2, p3, p4).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e1.fulfill() : XCTFail()
        }.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDoubleTupleSucceed() {
        let e1 = expectation(description: "")
        let p1 = cancellable(Promise.value(1))
        let p2 = cancellable(Promise.value("abc"))
        cancellableWhen(fulfilled: p1, p2).done{ x, y in
            XCTAssertEqual(x, 1)
            XCTAssertEqual(y, "abc")
            e1.fulfill()
        }.silenceWarning()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDoubleTupleCancel() {
        let e1 = expectation(description: "")
        let p1 = cancellable(Promise.value(1))
        let p2 = cancellable(Promise.value("abc"))
        cancellableWhen(fulfilled: p1, p2).done{ _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e1.fulfill() : XCTFail()
        }.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTripleTuple() {
        let e1 = expectation(description: "")
        let p1 = cancellable(Promise.value(1))
        let p2 = cancellable(Promise.value("abc"))
        let p3 = cancellable(Promise.value(1.0))
        cancellableWhen(fulfilled: p1, p2, p3).done { _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e1.fulfill() : XCTFail()
        }.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testQuadrupleTuple() {
        let e1 = expectation(description: "")
        let p1 = cancellable(Promise.value(1))
        let p2 = cancellable(Promise.value("abc"))
        let p3 = cancellable(Promise.value(1.0))
        let p4 = cancellable(Promise.value(true))
        cancellableWhen(fulfilled: p1, p2, p3, p4).done { _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e1.fulfill() : XCTFail()
        }.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testQuintupleTuple() {
        let e1 = expectation(description: "")
        let p1 = cancellable(Promise.value(1))
        let p2 = cancellable(Promise.value("abc"))
        let p3 = cancellable(Promise.value(1.0))
        let p4 = cancellable(Promise.value(true))
        let p5 = cancellable(Promise.value("a" as Character))
        cancellableWhen(fulfilled: p1, p2, p3, p4, p5).done { _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e1.fulfill() : XCTFail()
        }.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testVoid() {
        let e1 = expectation(description: "")
        let p1 = cancellable(Promise.value(1)).done { _ in }
        let p2 = cancellable(Promise.value(2)).done { _ in }
        let p3 = cancellable(Promise.value(3)).done { _ in }
        let p4 = cancellable(Promise.value(4)).done { _ in }

        when(fulfilled: p1, p2, p3, p4).done {
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e1.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRejected() {
        enum Error: Swift.Error { case dummy }

        let e1 = expectation(description: "")
        let p1 = cancellable(after(.milliseconds(100))).map{ true }
        let p2: CancellablePromise<Bool> = cancellable(after(.milliseconds(200))).map{ throw Error.dummy }
        let p3 = cancellable(Promise.value(false))
            
        cancellableWhen(fulfilled: p1, p2, p3).catch(policy: .allErrors) {
            $0.isCancelled ? e1.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProgress() {
        let ex = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = cancellable(after(.milliseconds(10)))
        let p2 = cancellable(after(.milliseconds(20)))
        let p3 = cancellable(after(.milliseconds(30)))
        let p4 = cancellable(after(.milliseconds(40)))

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        when(fulfilled: p1, p2, p3, p4).done { _ in
            XCTAssertEqual(progress.completedUnitCount, 1)
            ex.fulfill()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        progress.resignCurrent()
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProgressDoesNotExceed100PercentSucceed() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = cancellable(after(.milliseconds(10)))
        let p2 = cancellable(after(.milliseconds(20))).done { throw NSError(domain: "a", code: 1, userInfo: nil) }
        let p3 = cancellable(after(.milliseconds(30)))
        let p4 = cancellable(after(.milliseconds(40)))

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        let promise = when(fulfilled: p1, p2, p3, p4)

        progress.resignCurrent()

        promise.catch { _ in
            ex2.fulfill()
        }

        var x = 0
        func finally() {
            x += 1
            if x == 4 {
                XCTAssertLessThanOrEqual(1, progress.fractionCompleted)
                XCTAssertEqual(progress.completedUnitCount, 1)
                ex1.fulfill()
            }
        }

        let q = DispatchQueue.main
        p1.done(on: q, finally).silenceWarning()
        p2.ensure(on: q, finally).silenceWarning()
        p3.done(on: q, finally).silenceWarning()
        p4.done(on: q, finally).silenceWarning()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProgressDoesNotExceed100PercentCancel() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
        let ex3 = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = cancellable(after(.milliseconds(10)))
        let p2 = cancellable(after(.milliseconds(20))).done { throw NSError(domain: "a", code: 1, userInfo: nil) }
        let p3 = cancellable(after(.milliseconds(30)))
        let p4 = cancellable(after(.milliseconds(40)))

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        let promise = when(fulfilled: p1, p2, p3, p4)

        progress.resignCurrent()

        promise.catch(policy: .allErrors) {
            $0.isCancelled ? ex2.fulfill() : XCTFail()
        }
        
        promise.cancel()

        func finally() {
            XCTFail()
        }
        
        func finallyEnsure() {
            ex3.fulfill()
        }
        
        var x = 0
        func catchall(err: Error) {
            XCTAssert(err.isCancelled)
            x += 1
            if x == 4 {
                XCTAssertLessThanOrEqual(1, progress.fractionCompleted)
                XCTAssertEqual(progress.completedUnitCount, 1)
                ex1.fulfill()
            }
        }

        let q = DispatchQueue.main
        p1.done(on: q, finally).catch(policy: .allErrors, catchall)
        p2.ensure(on: q, finallyEnsure).catch(policy: .allErrors, catchall)
        p3.done(on: q, finally).catch(policy: .allErrors, catchall)
        p4.done(on: q, finally).catch(policy: .allErrors, catchall)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUnhandledErrorHandlerDoesNotFire() {
        enum Error: Swift.Error {
            case test
        }

        let ex = expectation(description: "")
        let p1 = CancellablePromise<Int>(error: Error.test)
        let p2 = cancellable(after(.milliseconds(100)))
        cancellableWhen(fulfilled: p1, p2).done{ _ in XCTFail() }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUnhandledErrorHandlerDoesNotFireForStragglers() {
        enum Error: Swift.Error {
            case test
            case straggler
        }

        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
        let ex3 = expectation(description: "")

        let p1 = CancellablePromise<Void>(error: Error.test)
        let p2 = cancellable(after(.milliseconds(100))).done { throw Error.straggler }
        let p3 = cancellable(after(.milliseconds(200))).done { throw Error.straggler }

        cancellableWhen(fulfilled: p1, p2, p3).catch(policy: .allErrors) {
            $0.isCancelled ? ex1.fulfill() : XCTFail()
        }.cancel()

        p2.ensure { after(.milliseconds(100)).done(ex2.fulfill) }.silenceWarning()
        p3.ensure { after(.milliseconds(100)).done(ex3.fulfill) }.silenceWarning()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAllSealedRejectedFirstOneRejects() {
        enum Error: Swift.Error {
            case test1
            case test2
            case test3
        }

        let ex = expectation(description: "")
        let p1 = CancellablePromise<Void>(error: Error.test1)
        let p2 = CancellablePromise<Void>(error: Error.test2)
        let p3 = CancellablePromise<Void>(error: Error.test3)

        when(fulfilled: p1, p2, p3).catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 1)
    }

    func testGuaranteeWhen() {
        let ex1 = expectation(description: "")
        when(resolved: cancellable(Guarantee()), cancellable(Guarantee())).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex1.fulfill() : XCTFail()
        }.cancel()

        let ex2 = expectation(description: "")
        when(resolved: [cancellable(Guarantee()), cancellable(Guarantee())]).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex2.fulfill() : XCTFail()
        }.cancel()

        wait(for: [ex1, ex2], timeout: 10)
    }
}
