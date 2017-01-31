import PromiseKit
import XCTest

enum Error: Swift.Error {
    case dummy  // we reject with this when we don't intend to test against it
    case sentinel(UInt32)
}

var indent = ""

func indent(print message: String, file: StaticString = #file, line: UInt = #line, execute body: () throws -> Void) {
    print(indent + message)
    let oldIndent = indent
    indent += "  "
    do {
        try body()
    } catch {
        XCTFail("\(indent)Failed: \(error)", file: file, line: line)
    }
    indent = oldIndent
}

extension XCTestCase {
    func describe(_ description: String, file: StaticString = #file, line: UInt = #line, body: () throws -> Void) {
        indent(print: description, execute: body)
    }

    func specify(_ description: String, file: StaticString = #file, line: UInt = #line, body: ((promise: Promise<Void>, fulfill: () -> Void, reject: (Error) -> Void), XCTestExpectation) throws -> Void) {
        indent(print: description) {
            let ex = expectation(description: description)
            let pending = Promise<Void>.pending()
            try body((pending.promise, pending.seal.fulfill, pending.seal.reject), ex)

            waitForExpectations(timeout: XCTestCase.defaultTimeout) { err in
                if let _ = err {
                    XCTFail("wait failed: \(description)", file: file, line: line)
                }
            }
        }
    }

    func testFulfilled(file: StaticString = #file, line: UInt = #line, body: @escaping (Promise<UInt32>, XCTestExpectation, UInt32) -> Void) {
        testFulfilled(withExpectationCount: 1, file: file, line: line) {
            body($0, $1.first!, $2)
        }
    }

    func testRejected(file: StaticString = #file, line: UInt = #line, body: @escaping (Promise<UInt32>, XCTestExpectation, UInt32) -> Void) {
        testRejected(withExpectationCount: 1, file: file, line: line) {
            body($0, $1.first!, $2)
        }
    }

    func testFulfilled(withExpectationCount: Int, file: StaticString = #file, line: UInt = #line, body: @escaping (Promise<UInt32>, [XCTestExpectation], UInt32) -> Void) {

        let specify = mkspecify(withExpectationCount, file: file, line: line, body: body)

        specify("already-fulfilled") { value in
            return (Promise(value), {})
        }
        specify("immediately-fulfilled") { value in
            let (promise, pipe) = Promise<UInt32>.pending()
            return (promise, {
                pipe.fulfill(value)
            })
        }
        specify("eventually-fulfilled") { value in
            let (promise, pipe) = Promise<UInt32>.pending()
            return (promise, {
                after(ticks: 5) {
                    pipe.fulfill(value)
                }
            })
        }
    }

    func testRejected(withExpectationCount: Int, file: StaticString = #file, line: UInt = #line, body: @escaping (Promise<UInt32>, [XCTestExpectation], UInt32) -> Void) {

        let specify = mkspecify(withExpectationCount, file: file, line: line, body: body)

        specify("already-rejected") { sentinel in
            return (Promise(error: Error.sentinel(sentinel)), {})
        }
        specify("immediately-rejected") { sentinel in
            let (promise, pipe) = Promise<UInt32>.pending()
            return (promise, {
                pipe.reject(Error.sentinel(sentinel))
            })
        }
        specify("eventually-rejected") { sentinel in
            let (promise, pipe) = Promise<UInt32>.pending()
            return (promise, {
                after(ticks: 50) {
                    pipe.reject(Error.sentinel(sentinel))
                }
            })
        }
    }


/////////////////////////////////////////////////////////////////////////

    private func mkspecify(_ numberOfExpectations: Int, file: StaticString, line: UInt, body: @escaping (Promise<UInt32>, [XCTestExpectation], UInt32) -> Void) -> (String, _ feed: (UInt32) -> (Promise<UInt32>, () -> Void)) -> Void {
        return { desc, feed in
            let value = arc4random()
            let (promise, executeAfter) = feed(value)
            let expectations = (1...numberOfExpectations).map {
                self.expectation(description: "\(desc) (\($0))")
            }

            indent(print: desc) {
                body(promise, expectations, value)
                executeAfter()

                self.waitForExpectations(timeout: XCTestCase.defaultTimeout) { err in
                    if let _ = err {
                        XCTFail("timed out: \(desc)", file: file, line: line)
                    }
                }
            }
        }
    }

    func mkex() -> XCTestExpectation {
        return expectation(description: "")
    }
}

func after(ticks: Int, execute body: @escaping () -> Void) {
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
    func test(onFulfilled: @escaping () -> Void, onRejected: @escaping () -> Void) {
        _=tap { result in
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
