import PromiseKit
import XCTest

class GuaranteeTests: XCTestCase {
    func testInit() {
        let ex = expectation(description: "")
        cancellable(Guarantee { seal in
            seal(1)
        }).done {
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
            let p = cancellable(after(.milliseconds(100))).map(on: nil) { 1 }
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

        cancellable(Guarantee.value([1, 2, 3])).thenMap { cancellable(Guarantee.value($0 * 2)) }
        .done { values in
            XCTAssertEqual([], values)
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        wait(for: [ex], timeout: 1)
    }
    
    func testCancellableTask() {
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

        let g = Guarantee<Void>(cancellableTask: task) { seal in
            resolver = seal
        }

        let ex = expectation(description: "")
        firstly {
            cancellable(g)
        }.done {
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
