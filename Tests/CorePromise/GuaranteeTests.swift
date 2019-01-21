import PromiseKit
import XCTest

class GuaranteeTests: XCTestCase {
    func testInit() {
        let ex = expectation(description: "")
        Guarantee { seal in
            seal(1)
        }.done {
            XCTAssertEqual(1, $0)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testWait() {
        XCTAssertEqual(after(.milliseconds(100)).map(on: nil){ 1 }.wait(), 1)
    }

    func testThenMap() {

        let ex = expectation(description: "")

        Guarantee.value([1, 2, 3])
            .thenMap { Guarantee.value($0 * 2) }
            .done { values in
                XCTAssertEqual([2, 4, 6], values)
                ex.fulfill()
        }

        wait(for: [ex], timeout: 10)
    }

    // MARK: - Dispatching to queues

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatchQueueAsyncExtensionReturnsGuarantee() {
        let ex = expectation(description: "")

        DispatchQueue.global().async { () -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 1
            }.done { one in
                XCTAssertEqual(one, 1)
                ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatchQueueAsyncExtensionWithResolverReturnsGuarantee() {
        let ex = expectation(description: "")

        DispatchQueue.global().async { (seal: (Int) -> Void) in
            XCTAssertFalse(Thread.isMainThread)
            seal(1)
            }.done { one in
                XCTAssertEqual(one, 1)
                ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testAppleAsyncFunctionsStillWork() {
        let exp = self.expectation(description: "Check apple")
        DispatchQueue.global().async {
            exp.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }
}
