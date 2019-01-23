import PromiseKit
import Dispatch
import XCTest

enum Error: Swift.Error {
    case dummy  // we reject with this when we don't intend to test against it
    case sentinel(UInt32)
}

private let timeout: TimeInterval = 10

extension XCTestCase {
    func describe(_ description: String, file: StaticString = #file, line: UInt = #line, body: () throws -> Void) {

        PromiseKit.conf.Q.map = .main

        do {
            try body()
        } catch {
            XCTFail(description, file: file, line: line)
        }
    }

    func specify(_ description: String, file: StaticString = #file, line: UInt = #line, body: ((promise: Promise<Void>, fulfill: () -> Void, reject: (Error) -> Void), XCTestExpectation) throws -> Void) {
        let expectation = self.expectation(description: description)
        let (pending, seal) = Promise<Void>.pending()

        do {
            try body((pending, seal.fulfill_, seal.reject), expectation)
            waitForExpectations(timeout: timeout) { err in
                if let _ = err {
                    XCTFail("wait failed: \(description)", file: file, line: line)
                }
            }
        } catch {
            XCTFail(description, file: file, line: line)
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
            return (.value(value), {})
        }
        specify("immediately-fulfilled") { value in
            let (promise, seal) = Promise<UInt32>.pending()
            return (promise, {
                seal.fulfill(value)
            })
        }
        specify("eventually-fulfilled") { value in
            let (promise, seal) = Promise<UInt32>.pending()
            return (promise, {
                after(ticks: 5) {
                    seal.fulfill(value)
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
            let (promise, seal) = Promise<UInt32>.pending()
            return (promise, {
                seal.reject(Error.sentinel(sentinel))
            })
        }
        specify("eventually-rejected") { sentinel in
            let (promise, seal) = Promise<UInt32>.pending()
            return (promise, {
                after(ticks: 50) {
                    seal.reject(Error.sentinel(sentinel))
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
        tap { result in
            switch result {
            case .fulfilled:
                onFulfilled()
            case .rejected:
                onRejected()
            }
        }.silenceWarning()
    }
}

prefix func ++(a: inout Int) -> Int {
    a += 1
    return a
}

extension Promise {
    func silenceWarning() {}
}

#if os(Linux)
import func Glibc.random

func arc4random() -> UInt32 {
    return UInt32(random())
}

extension XCTestExpectation {
    func fulfill() {
        fulfill(#file, line: #line)
    }
}

extension XCTestCase {
    func wait(for: [XCTestExpectation], timeout: TimeInterval, file: StaticString = #file, line: UInt = #line) {
    #if !(swift(>=4.0) && !swift(>=4.1))
        let line = Int(line)
    #endif
        waitForExpectations(timeout: timeout, file: file, line: line)
    }
}
#endif
