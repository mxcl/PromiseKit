import PromiseKit
import XCTest

enum Error: ErrorProtocol {
    case dummy  // we reject with this when we don't intend to test against it
    case sentinel(UInt32)
}

private let timeout: TimeInterval = 1

extension XCTestCase {
    func describe(_ description: String, file: StaticString = #file, line: UInt = #line, body: @noescape () throws -> Void) {
        do {
            try body()
        } catch {
            XCTFail(description, file: file, line: line)
        }
    }

    func specify(_ description: String, file: StaticString = #file, line: UInt = #line, body: @noescape (Promise<Void>.PendingTuple, XCTestExpectation) throws -> Void) {
        let expectation = self.expectation(description: description)
        let pending = Promise<Void>.pending()

        do {
            try body(pending, expectation)
            waitForExpectations(timeout: timeout) { err in
                if let _ = err {
                    XCTFail("wait failed: \(description)", file: file, line: line)
                }
            }
        } catch {
            XCTFail(description, file: file, line: line)
        }
    }

    func testFulfilled(file: StaticString = #file, line: UInt = #line, body: (Promise<UInt32>, XCTestExpectation, UInt32) -> Void) {
        testFulfilled(withExpectationCount: 1, file: file, line: line) {
            body($0, $1.first!, $2)
        }
    }

    func testRejected(file: StaticString = #file, line: UInt = #line, body: (Promise<UInt32>, XCTestExpectation, UInt32) -> Void) {
        testRejected(withExpectationCount: 1, file: file, line: line) {
            body($0, $1.first!, $2)
        }
    }

    func testFulfilled(withExpectationCount: Int, file: StaticString = #file, line: UInt = #line, body: (Promise<UInt32>, [XCTestExpectation], UInt32) -> Void) {

        let specify = mkspecify(withExpectationCount, file: file, line: line, body: body)

        specify("already-fulfilled") { value in
            return (Promise.resolved(value: value), {})
        }
        specify("immediately-fulfilled") { value in
            let (promise, fulfill, _) = Promise<UInt32>.pending()
            return (promise, {
                fulfill(value)
            })
        }
        specify("eventually-fulfilled") { value in
            let (promise, fulfill, _) = Promise<UInt32>.pending()
            return (promise, {
                after(ticks: 5) {
                    fulfill(value)
                }
            })
        }
    }

    func testRejected(withExpectationCount: Int, file: StaticString = #file, line: UInt = #line, body: (Promise<UInt32>, [XCTestExpectation], UInt32) -> Void) {

        let specify = mkspecify(withExpectationCount, file: file, line: line, body: body)

        specify("already-rejected") { sentinel in
            return (Promise.resolved(error: Error.sentinel(sentinel)), {})
        }
        specify("immediately-rejected") { sentinel in
            let (promise, _, reject) = Promise<UInt32>.pending()
            return (promise, {
                reject(Error.sentinel(sentinel))
            })
        }
        specify("eventually-rejected") { sentinel in
            let (promise, _, reject) = Promise<UInt32>.pending()
            return (promise, {
                after(ticks: 50) {
                    reject(Error.sentinel(sentinel))
                }
            })
        }
    }


/////////////////////////////////////////////////////////////////////////

    private func mkspecify(_ numberOfExpectations: Int, file: StaticString, line: UInt, body: (Promise<UInt32>, [XCTestExpectation], UInt32) -> Void) -> (String, feed: (UInt32) -> (Promise<UInt32>, () -> Void)) -> Void {
        return { desc, feed in
            let value = arc4random()
            let (promise, executeAfter) = feed(value)
            let expectations = (1...numberOfExpectations).map {
                self.expectation(description: "\(desc) (\($0))")
            }
            body(promise, expectations, value)
            
            executeAfter()
            
            self.waitForExpectations(timeout: timeout) { err in
                if let _ = err {
                    XCTFail("timed out: \(desc)", file: file, line: line)
                }
            }
        }
    }

    func mkex() -> XCTestExpectation {
        return expectation(description: "")
    }
}

func after(ticks: Int, execute body: () -> Void) {
    precondition(ticks > 0)

    var ticks = ticks
    func f() {
        DispatchQueue.main.async {
            ticks -= 1
            if ticks == 0 {
                body()
            } else {
                f()
            }
        }
    }
    f()
}

extension Promise {
    func test(onFulfilled: () -> Void, onRejected: () -> Void) {
        tap { result in
            switch result {
            case .fulfilled:
                onFulfilled()
            case .rejected:
                onRejected()
            }
        }
    }
}

prefix func ++(a: inout Int) -> Int {
    a += 1
    return a
}
