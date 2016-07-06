import XCTest
import PromiseKit

class WhenTestCase_Swift: XCTestCase {

    func testEmpty() {
        let e = expectation(withDescription: "")
        let promises: [Promise<Void>] = []
        when(fulfilled: promises).then { _ in
            e.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testInt() {
        let e1 = expectation(withDescription: "")
        let p1 = Promise.resolved(value: 1)
        let p2 = Promise.resolved(value: 2)
        let p3 = Promise.resolved(value: 3)
        let p4 = Promise.resolved(value: 4)

        when(p1, p2, p3, p4).then { (x: [Int])->() in
            XCTAssertEqual(x[0], 1)
            XCTAssertEqual(x[1], 2)
            XCTAssertEqual(x[2], 3)
            XCTAssertEqual(x[3], 4)
            XCTAssertEqual(x.count, 4)
            e1.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testTuple() {
        let e1 = expectation(withDescription: "")
        let p1 = Promise.resolved(value: 1)
        let p2 = Promise.resolved(value: "abc")
        when(p1, p2).then{ (x: Int, y: String) -> Void in
            XCTAssertEqual(x, 1)
            XCTAssertEqual(y, "abc")
            e1.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testVoid() {
        let e1 = expectation(withDescription: "")
        let p1 = Promise.resolved(value: 1).then { x -> Void in }
        let p2 = Promise.resolved(value: 2).then { x -> Void in }
        let p3 = Promise.resolved(value: 3).then { x -> Void in }
        let p4 = Promise.resolved(value: 4).then { x -> Void in }

        when(p1, p2, p3, p4).then(execute: e1.fulfill)

        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testRejected() {
        enum Error: ErrorProtocol { case dummy }

        let e1 = expectation(withDescription: "")
        let p1 = after(interval: 0.1).then{ true }
        let p2 = after(interval: 0.2).then{ throw Error.dummy }
        let p3 = Promise.resolved(value: false)
            
        when(p1, p2, p3).catch { _ in
            e1.fulfill()
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testProgress() {
        let ex = expectation(withDescription: "")

        XCTAssertNil(Progress.current())

        let p1 = after(interval: 0.01)
        let p2 = after(interval: 0.02)
        let p3 = after(interval: 0.03)
        let p4 = after(interval: 0.04)

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        when(p1, p2, p3, p4).then { _ -> Void in
            XCTAssertEqual(progress.completedUnitCount, 1)
            ex.fulfill()
        }

        progress.resignCurrent()

        var cum = Double(0)
        for promise in [p1, p2, p3, p4] {
            promise.then(on: zalgo) { _ -> Void in
                cum += 0.25
                XCTAssertEqual(cum, progress.fractionCompleted)
            }
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testProgressDoesNotExceed100Percent() {
        let ex1 = expectation(withDescription: "")
        let ex2 = expectation(withDescription: "")

        XCTAssertNil(Progress.current())

        let p1 = after(interval: 0.01)
        let p2: Promise<Void> = after(interval: 0.02).then { throw NSError(domain: "a", code: 1, userInfo: nil) }
        let p3 = after(interval: 0.03)
        let p4 = after(interval: 0.04)

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        let promise: Promise<Void> = when(p1, p2, p3, p4)

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
        p1.always(on: q, execute: finally)
        p2.always(on: q, execute: finally)
        p3.always(on: q, execute: finally)
        p4.always(on: q, execute: finally)

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testUnhandledErrorHandlerDoesNotFire() {
        enum Error: ErrorProtocol {
            case test
        }

        PMKUnhandledErrorHandler = { error in
            XCTFail()
        }

        let ex = expectation(withDescription: "")
        let p1 = Promise<Void>.resolved(error: Error.test)
        let p2 = after(interval: 0.1)
        when(p1, p2).then{ XCTFail() }.catch { error in
            if case PromiseKit.Error.when(let index, let underlyingError) = error {
                XCTAssertEqual(index, 0)
                XCTAssertEqual(underlyingError as? Error, Error.test)
                ex.fulfill()
            }
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testUnhandledErrorHandlerDoesNotFireForStragglers() {
        enum Error: ErrorProtocol {
            case test
            case straggler
        }

        PMKUnhandledErrorHandler = { error in
            XCTFail()
        }

        let ex1 = expectation(withDescription: "")
        let ex2 = expectation(withDescription: "")
        let ex3 = expectation(withDescription: "")

        let p1 = Promise<Void>.resolved(error: Error.test)
        let p2 = after(interval: 0.1).then { throw Error.straggler }
        let p3 = after(interval: 0.2).then { throw Error.straggler }

        when(p1, p2, p3).catch { error -> Void in
            if case PromiseKit.Error.when(let index, let underlyingError) = error {
                XCTAssertEqual(index, 0)
                XCTAssertEqual(underlyingError as? Error, Error.test)
                ex1.fulfill()
            }
        }

        p2.always { after(interval: 0.1).then(execute: ex2.fulfill) }
        p3.always { after(interval: 0.1).then(execute: ex3.fulfill) }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testAllSealedRejectedFirstOneRejects() {
        enum Error: ErrorProtocol {
            case test1
            case test2
            case test3
        }

        let ex = expectation(withDescription: "")
        let p1 = Promise<Void>.resolved(error: Error.test1)
        let p2 = Promise<Void>.resolved(error: Error.test2)
        let p3 = Promise<Void>.resolved(error: Error.test3)

        when(p1, p2, p3).catch { error in
            if case PromiseKit.Error.when(0, Error.test1) = error {
                ex.fulfill()
            } else {
                XCTFail()
            }
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    var oldHandler: (ErrorProtocol -> Void)!

    override func setUp() {
        oldHandler = PMKUnhandledErrorHandler
    }

    override func tearDown() {
        PMKUnhandledErrorHandler = oldHandler
    }
}
