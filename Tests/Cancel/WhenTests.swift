import Dispatch
import PromiseKit
import XCTest

class WhenTests: XCTestCase {

    func testEmpty() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let promises: [CancellablePromise<Void>] = []

        when(fulfilled: promises).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: promises).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations()
    }

    func testInt() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value(2).cancellize()
        let p3 = Promise.value(3).cancellize()
        let p4 = Promise.value(4).cancellize()

        when(fulfilled: [p1, p2, p3, p4]).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: [p1, p2, p3, p4]).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations()
    }

    func testBinaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()

        when(fulfilled: p1, p2).done{ v1, v2 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            ex.fulfill()
        }.silenceWarning()

        when(resolved: p1, p2).done{ r1, r2 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations()
    }

    func testBinaryTupleCancel() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()

        when(fulfilled: p1, p2).done{ _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: p1, p2).done{ _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations()
    }
    
    func testTernaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()

        when(fulfilled: p1, p2, p3).done{ v1, v2, v3 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            ex.fulfill()
        }.silenceWarning()

        when(resolved: p1, p2, p3).done { r1, r2, r3 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations()
    }

    func testTernaryTupleCancel() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()

        when(fulfilled: p1, p2, p3).done { _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: p1, p2, p3).done { _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations()
    }

    func testQuaternaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()

        when(fulfilled: p1, p2, p3, p4).done{ v1, v2, v3, v4 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            ex.fulfill()
        }.silenceWarning()

        when(resolved: p1, p2, p3, p4).done { r1, r2, r3, r4 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations()
    }

    func testQuaternaryTupleCancel() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()

        when(fulfilled: p1, p2, p3, p4).done { _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: p1, p2, p3, p4).done { _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations()
    }

    func testQuinaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()
        let p5 = Promise.value("a" as Character).cancellize()

        when(fulfilled: p1, p2, p3, p4, p5).done{ v1, v2, v3, v4, v5 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            XCTAssertEqual(v5, "a" as Character)
            ex.fulfill()
        }.silenceWarning()

        when(resolved: p1, p2, p3, p4, p5).done { r1, r2, r3, r4, r5 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            XCTAssertEqual(try r5.get(), "a" as Character)
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations()
    }

    func testQuinaryTupleCancel() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()
        let p5 = Promise.value("a" as Character).cancellize()

        when(fulfilled: p1, p2, p3, p4, p5).done { _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: p1, p2, p3, p4, p5).done { _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations()
    }

    func testSenaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()
        let p5 = Promise.value("a" as Character).cancellize()
        let p6 = Promise.value(CGFloat(6)).cancellize()
        
        when(fulfilled: p1, p2, p3, p4, p5, p6).done { v1, v2, v3, v4, v5, v6 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            XCTAssertEqual(v5, "a" as Character)
            XCTAssertEqual(v6, CGFloat(6))
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3, p4, p5, p6).done { r1, r2, r3, r4, r5, r6 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            XCTAssertEqual(try r5.get(), "a" as Character)
            XCTAssertEqual(try r6.get(), CGFloat(6))
            ex.fulfill()
        }.silenceWarning()
        
        waitForExpectations()
    }

    func testSenaryTupleCancel() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()
        let p5 = Promise.value("a" as Character).cancellize()
        let p6 = Promise.value(CGFloat(6)).cancellize()
        
        when(fulfilled: p1, p2, p3, p4, p5, p6).done { _, _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: p1, p2, p3, p4, p5, p6).done { _, _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations()
    }

    func testSeptenaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()
        let p5 = Promise.value("a" as Character).cancellize()
        let p6 = Promise.value(CGFloat(6)).cancellize()
        let p7 = Promise.value(1 as Int?).cancellize()
        
        when(fulfilled: p1, p2, p3, p4, p5, p6, p7).done { v1, v2, v3, v4, v5, v6, v7 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            XCTAssertEqual(v5, "a" as Character)
            XCTAssertEqual(v6, CGFloat(6))
            XCTAssertEqual(v7, 1 as Int?)
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3, p4, p5, p6, p7).done { r1, r2, r3, r4, r5, r6, r7 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            XCTAssertEqual(try r5.get(), "a" as Character)
            XCTAssertEqual(try r6.get(), CGFloat(6))
            XCTAssertEqual(try r7.get(), 1 as Int?)
            ex.fulfill()
        }.silenceWarning()
        
        waitForExpectations()
    }

    func testSeptenaryTupleCancel() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()
        let p5 = Promise.value("a" as Character).cancellize()
        let p6 = Promise.value(CGFloat(6)).cancellize()
        let p7 = Promise.value(1 as Int?).cancellize()
        
        when(fulfilled: p1, p2, p3, p4, p5, p6, p7).done { _, _, _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: p1, p2, p3, p4, p5, p6, p7).done { _, _, _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations()
    }

    func testOctonaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()
        let p5 = Promise.value("a" as Character).cancellize()
        let p6 = Promise.value(CGFloat(6)).cancellize()
        let p7 = Promise.value(1 as Int?).cancellize()
        let p8 = Promise.value("abc" as String?).cancellize()
        
        when(fulfilled: p1, p2, p3, p4, p5, p6, p7, p8).done { v1, v2, v3, v4, v5, v6, v7, v8 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            XCTAssertEqual(v5, "a" as Character)
            XCTAssertEqual(v6, CGFloat(6))
            XCTAssertEqual(v7, 1 as Int?)
            XCTAssertEqual(v8, "abc" as String?)
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3, p4, p5, p6, p7, p8).done { r1, r2, r3, r4, r5, r6, r7, r8 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            XCTAssertEqual(try r5.get(), "a" as Character)
            XCTAssertEqual(try r6.get(), CGFloat(6))
            XCTAssertEqual(try r7.get(), 1 as Int?)
            XCTAssertEqual(try r8.get(), "abc" as String?)
            ex.fulfill()
        }.silenceWarning()
        
        waitForExpectations()
    }

    func testOctonaryTupleCancel() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()
        let p5 = Promise.value("a" as Character).cancellize()
        let p6 = Promise.value(CGFloat(6)).cancellize()
        let p7 = Promise.value(1 as Int?).cancellize()
        let p8 = Promise.value("abc" as String?).cancellize()
        
        when(fulfilled: p1, p2, p3, p4, p5, p6, p7, p8).done { _, _, _, _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: p1, p2, p3, p4, p5, p6, p7, p8).done { _, _, _, _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations()
    }

    func testNovenaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()
        let p5 = Promise.value("a" as Character).cancellize()
        let p6 = Promise.value(CGFloat(6)).cancellize()
        let p7 = Promise.value(1 as Int?).cancellize()
        let p8 = Promise.value("abc" as String?).cancellize()
        let p9 = Promise.value(nil as Double?).cancellize()
        
        when(fulfilled: p1, p2, p3, p4, p5, p6, p7, p8, p9).done { v1, v2, v3, v4, v5, v6, v7, v8, v9 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            XCTAssertEqual(v5, "a" as Character)
            XCTAssertEqual(v6, CGFloat(6))
            XCTAssertEqual(v7, 1 as Int?)
            XCTAssertEqual(v8, "abc" as String?)
            XCTAssertEqual(v9, nil)
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3, p4, p5, p6, p7, p8, p9).done { r1, r2, r3, r4, r5, r6, r7, r8, r9 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            XCTAssertEqual(try r5.get(), "a" as Character)
            XCTAssertEqual(try r6.get(), CGFloat(6))
            XCTAssertEqual(try r7.get(), 1 as Int?)
            XCTAssertEqual(try r8.get(), "abc" as String?)
            XCTAssertEqual(try r9.get(), nil)
            ex.fulfill()
        }.silenceWarning()
        
        waitForExpectations()
    }

    func testNovenaryTupleCancel() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).cancellize()
        let p2 = Promise.value("abc").cancellize()
        let p3 = Promise.value(1.0).cancellize()
        let p4 = Promise.value(true).cancellize()
        let p5 = Promise.value("a" as Character).cancellize()
        let p6 = Promise.value(CGFloat(6)).cancellize()
        let p7 = Promise.value(1 as Int?).cancellize()
        let p8 = Promise.value("abc" as String?).cancellize()
        let p9 = Promise.value(nil as Double?).cancellize()
        
        when(fulfilled: p1, p2, p3, p4, p5, p6, p7, p8, p9).done { _, _, _, _, _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: p1, p2, p3, p4, p5, p6, p7, p8, p9).done { _, _, _, _, _, _, _, _, _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations()
    }

    func testVoidCancel() {
        let ex = expectation(description: "")
        let p1 = Promise.value(1).cancellize().done { _ in }
        let p2 = Promise.value(2).cancellize().done { _ in }
        let p3 = Promise.value(3).cancellize().done { _ in }
        let p4 = Promise.value(4).cancellize().done { _ in }

        when(fulfilled: [p1, p2, p3, p4]).done {
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations()
    }
    
    func testRejected() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = after(.milliseconds(100)).cancellize().map{ true }
        let p2: CancellablePromise<Bool> = after(.milliseconds(200)).cancellize().map{ throw TestError.dummy }
        let p3 = Promise.value(false).cancellize()
            
        when(fulfilled: p1, p2, p3).catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        when(resolved: p1, p2, p3).catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations()
    }

    func testProgress() {
        let ex = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after(.milliseconds(10)).cancellize()
        let p2 = after(.milliseconds(20)).cancellize()
        let p3 = after(.milliseconds(30)).cancellize()
        let p4 = after(.milliseconds(40)).cancellize()

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        when(fulfilled: p1, p2, p3, p4).done { _ in
            XCTAssertEqual(progress.completedUnitCount, 1)
            ex.fulfill()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        progress.resignCurrent()
        
        waitForExpectations()
    }

    func testProgressDoesNotExceed100PercentSucceed() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after(.milliseconds(10)).cancellize()
        let p2 = after(.milliseconds(20)).cancellize().done { throw NSError(domain: "a", code: 1, userInfo: nil) }
        let p3 = after(.milliseconds(30)).cancellize()
        let p4 = after(.milliseconds(40)).cancellize()

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

        waitForExpectations()
    }

    func testProgressDoesNotExceed100PercentCancel() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
        let ex3 = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after(.milliseconds(10)).cancellize()
        let p2 = after(.milliseconds(20)).cancellize().done { throw NSError(domain: "a", code: 1, userInfo: nil) }
        let p3 = after(.milliseconds(30)).cancellize()
        let p4 = after(.milliseconds(40)).cancellize()

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

        waitForExpectations()
    }

    func testUnhandledErrorHandlerDoesNotFire() {
        let ex = expectation(description: "")
        let p1 = CancellablePromise<Int>(error: TestError.dummy)
        let p2 = after(.milliseconds(100)).cancellize()
        when(fulfilled: p1, p2).done{ _ in XCTFail() }.catch(policy: .allErrors) {
            $0.isCancelled ? XCTFail() : ex.fulfill()
        }.cancel()

        waitForExpectations()
    }

    func testUnhandledErrorHandlerDoesNotFireForStragglers() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 3
        let p1 = CancellablePromise<Void>(error: TestError.dummy)
        let p2 = after(.milliseconds(100)).cancellize().done { throw TestError.straggler }
        let p3 = after(.milliseconds(200)).cancellize().done { throw TestError.straggler }

        when(fulfilled: p1, p2, p3).catch(policy: .allErrors) {
            $0.isCancelled ? XCTFail() : ex.fulfill()
        }.cancel()

        p2.ensure { after(.milliseconds(100)).done(ex.fulfill) }.silenceWarning()
        p3.ensure { after(.milliseconds(100)).done(ex.fulfill) }.silenceWarning()

        waitForExpectations()
    }

    func testAllSealedRejectedFirstOneRejects() {
        let ex = expectation(description: "")
        let p1 = CancellablePromise<Void>(error: TestError.dummy)
        let p2 = CancellablePromise<Void>(error: TestError.straggler)
        let p3 = CancellablePromise<Void>(error: TestError.stub)

        when(fulfilled: p1, p2, p3).catch(policy: .allErrors) {
            $0.isCancelled ? XCTFail() : ex.fulfill()
        }.cancel()

        waitForExpectations()
    }

    func testGuaranteeWhen() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2

        when(resolved: Guarantee().cancellize(), Guarantee().cancellize()).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        when(resolved: [Guarantee().cancellize(), Guarantee().cancellize()]).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations()
    }

    func testMixedThenables() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(true).cancellize()
        let p2 = Promise.value(2).cancellize()
        let g1 = Guarantee.value("abc").cancellize()
        
        when(fulfilled: p1, p2, g1).done { v1, v2, v3 in
            XCTAssertEqual(v1, true)
            XCTAssertEqual(v2, 2)
            XCTAssertEqual(v3, "abc")
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, g1).done { r1, r2, r3 in
            XCTAssertEqual(try r1.get(), true)
            XCTAssertEqual(try r2.get(), 2)
            XCTAssertEqual(try r3.get(), "abc")
            ex.fulfill()
        }.silenceWarning()
        
        waitForExpectations()
    }

    func testMixedThenablesCancel() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(true).cancellize()
        let p2 = Promise.value(2).cancellize()
        let g1 = Guarantee.value("abc").cancellize()
        
        when(fulfilled: p1, p2, g1).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        when(resolved: p1, p2, g1).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations()
    }
}

private enum TestError: Error {
    case dummy
    case straggler
    case stub
}

private extension XCTestCase {
    
    func waitForExpectations() {
        waitForExpectations(timeout: 5)
    }
}
