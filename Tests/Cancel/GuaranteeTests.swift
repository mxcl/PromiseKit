import PromiseKit
import XCTest

class GuaranteeTests: XCTestCase {
    func testInit() {
        let ex = expectation(description: "")
        Guarantee { seal in
            seal(1)
        }.cancellize().done {
            XCTFail()
            XCTAssertEqual(1, $0)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        wait(for: [ex], timeout: 1)
    }

    func testWait() {
        let ex = expectation(description: "")
        do {
            let p = after(.milliseconds(100)).cancellize().map(on: nil) { 1 }
            p.cancel()
            let value = try p.wait()
            XCTAssertEqual(value, 1)
        } catch {
            error.isCancelled ? ex.fulfill() : XCTFail()
        }
        wait(for: [ex], timeout: 1)
    }
    
    func testThenMap() {
        let ex = expectation(description: "")

        Guarantee.value([1, 2, 3]).cancellize().thenMap { Guarantee.value($0 * 2).cancellize() }
        .done { values in
            XCTAssertEqual([], values)
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        wait(for: [ex], timeout: 1)
    }
    
    func testCancellable() {
#if swift(>=4.0)
        var resolver: ((()) -> Void)!
#else
        var resolver: ((Void) -> Void)!
#endif

        let task = DispatchWorkItem {
#if swift(>=4.0)
            resolver(())
#else
            resolver()
#endif
        }
        
        q.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: task)

        let g = Guarantee<Void>(cancellable: task) { seal in
            resolver = seal
        }

        let ex = expectation(description: "")
        firstly {
            CancellablePromise(g)
        }.done {
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail("\($0)")
        } .cancel()

        wait(for: [ex], timeout: 1)
    }

    func testSetCancellable() {
#if swift(>=4.0)
        var resolver: ((()) -> Void)!
#else
        var resolver: ((Void) -> Void)!
#endif

        let task = DispatchWorkItem {
#if swift(>=4.0)
            resolver(())
#else
            resolver()
#endif
        }
        
        q.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: task)

        let g = Guarantee<Void> { seal in
            resolver = seal
        }
        g.setCancellable(task)
        
        let ex = expectation(description: "")
        firstly {
            g
        }.cancellize().done {
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail("\($0)")
        } .cancel()

        wait(for: [ex], timeout: 1)
    }
}

private var q: DispatchQueue {
    if #available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *) {
        return DispatchQueue.global(qos: .default)
    } else {
        return DispatchQueue.global(priority: .default)
    }
}
