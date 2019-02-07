import XCTest
import PromiseKit

class WhenConcurrentTestCase_Swift: XCTestCase {

    func testWhenSucceed() {
        let e = expectation(description: "")

        var numbers = (0..<42).makeIterator()
        let squareNumbers = numbers.map { $0 * $0 }

        let generator = AnyIterator<CancellablePromise<Int>> {
            guard let number = numbers.next() else {
                return nil
            }

            return cancellable(after(.milliseconds(10))).map {
                return number * number
            }
        }

        cancellableWhen(fulfilled: generator, concurrently: 5).done { numbers in
            if numbers == squareNumbers {
                e.fulfill()
            }
        }.silenceWarning()

        waitForExpectations(timeout: 3, handler: nil)
    }

     func testWhenCancel() {
        let e = expectation(description: "")

        var numbers = (0..<42).makeIterator()
        let squareNumbers = numbers.map { $0 * $0 }

        let generator = AnyIterator<CancellablePromise<Int>> {
            guard let number = numbers.next() else {
                return nil
            }

            return cancellable(after(.milliseconds(10))).map {
                XCTFail()
                return number * number
            }
        }

        cancellableWhen(fulfilled: generator, concurrently: 5).done { numbers in
            XCTFail()
            if numbers == squareNumbers {
                e.fulfill()
            }
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 3, handler: nil)
    }

   func testWhenEmptyGeneratorSucceed() {
        let e = expectation(description: "")

        let generator = AnyIterator<CancellablePromise<Int>> {
            return nil
        }

        cancellableWhen(fulfilled: generator, concurrently: 5).done { numbers in
            if numbers.count == 0 {
                e.fulfill()
            }
        }.silenceWarning()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testWhenEmptyGeneratorCancel() {
        let e = expectation(description: "")
        
        let generator = AnyIterator<CancellablePromise<Int>> {
            return nil
        }
        
        cancellableWhen(fulfilled: generator, concurrently: 5).done { numbers in
            if numbers.count == 0 {
                e.fulfill()
            }
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e.fulfill() : XCTFail()
        }.cancel()
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testWhenGeneratorErrorSucceed() {
        enum LocalError: Error {
            case Unknown
            case DivisionByZero
        }

        let expectedErrorIndex = 42
        let expectedError = LocalError.DivisionByZero

        let e = expectation(description: "")

        var numbers = (-expectedErrorIndex..<expectedErrorIndex).makeIterator()

        let generator = AnyIterator<CancellablePromise<Int>> {
            guard let number = numbers.next() else {
                return nil
            }

            return cancellable(after(.milliseconds(10))).then { _ -> CancellablePromise<Int> in
                if number != 0 {
                    return CancellablePromise(error: expectedError)
                } else {
                    return cancellable(Promise.value(100500 / number))
                }
            }
        }

        cancellableWhen(fulfilled: generator, concurrently: 3).catch { error in
            guard let error = error as? LocalError else {
                return
            }
            guard case .DivisionByZero = error else {
                return
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testWhenGeneratorErrorCancel() {
        enum LocalError: Error {
            case Unknown
            case DivisionByZero
        }

        let expectedErrorIndex = 42
        let expectedError = LocalError.DivisionByZero

        let e = expectation(description: "")

        var numbers = (-expectedErrorIndex..<expectedErrorIndex).makeIterator()

        let generator = AnyIterator<CancellablePromise<Int>> {
            guard let number = numbers.next() else {
                return nil
            }

            return cancellable(after(.milliseconds(10))).then { _ -> CancellablePromise<Int> in
                if number != 0 {
                    return CancellablePromise(error: expectedError)
                } else {
                    return cancellable(Promise.value(100500 / number))
                }
            }
        }

        cancellableWhen(fulfilled: generator, concurrently: 3).catch(policy: .allErrors) { error in
            error.isCancelled ? e.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testWhenConcurrencySucceed() {
        let expectedConcurrently = 4
        var currentConcurrently = 0
        var maxConcurrently = 0

        let e = expectation(description: "")

        var numbers = (0..<42).makeIterator()

        let generator = AnyIterator<CancellablePromise<Int>> {
            currentConcurrently += 1
            maxConcurrently = max(maxConcurrently, currentConcurrently)

            guard let number = numbers.next() else {
                return nil
            }

            return cancellable(after(.milliseconds(10))).then(on: .main) { _ -> CancellablePromise<Int> in
                currentConcurrently -= 1
                return cancellable(Promise.value(number * number))
            }
        }

        cancellableWhen(fulfilled: generator, concurrently: expectedConcurrently).done { _ in
            XCTAssertEqual(expectedConcurrently, maxConcurrently)
            e.fulfill()
        }.silenceWarning()

        waitForExpectations(timeout: 3)
    }

     func testWhenConcurrencyCancel() {
        let expectedConcurrently = 4
        var currentConcurrently = 0
        var maxConcurrently = 0

        let e = expectation(description: "")

        var numbers = (0..<42).makeIterator()

        let generator = AnyIterator<CancellablePromise<Int>> {
            currentConcurrently += 1
            maxConcurrently = max(maxConcurrently, currentConcurrently)

            guard let number = numbers.next() else {
                return nil
            }

            return cancellable(after(.milliseconds(10))).then(on: .main) { _ -> CancellablePromise<Int> in
                currentConcurrently -= 1
                return cancellable(Promise.value(number * number))
            }
        }

        cancellableWhen(fulfilled: generator, concurrently: expectedConcurrently).done { _ in
            XCTFail()
            XCTAssertEqual(expectedConcurrently, maxConcurrently)
            e.fulfill()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? e.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 3)
    }

   func testWhenConcurrencyLessThanZero() {
        let generator = AnyIterator<CancellablePromise<Int>> { XCTFail(); return nil }

        let p1 = cancellableWhen(fulfilled: generator, concurrently: 0)
        let p2 = cancellableWhen(fulfilled: generator, concurrently: -1)
        p1.cancel()
        p2.cancel()

        guard let e1 = p1.error else { return XCTFail() }
        guard let e2 = p2.error else { return XCTFail() }
        guard case PMKError.badInput = e1 else { return XCTFail() }
        guard case PMKError.badInput = e2 else { return XCTFail() }
    }

    func testStopsDequeueingOnceRejected() {
        let ex = expectation(description: "")
        enum Error: Swift.Error { case dummy }

        var x: UInt = 0
        let generator = AnyIterator<CancellablePromise<Void>> {
            x += 1
            switch x {
            case 0:
                fatalError()
            case 1:
                return CancellablePromise()
            case 2:
                return CancellablePromise(error: Error.dummy)
            case _:
                XCTFail()
                return nil
            }
        }

        cancellableWhen(fulfilled: generator, concurrently: 1).done {
            XCTFail("\($0)")
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()

        waitForExpectations(timeout: 3)
    }
}
