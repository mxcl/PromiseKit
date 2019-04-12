import Dispatch
import PromiseKit
import XCTest

// Exercise the whole API through DispatchQueue wrappers. The test here is really
// that everything compiles smoothly, not anything that happens at test time.

class DispatchWrapperTests: XCTestCase {
    
    enum TestError: Error, Equatable {
        case errorOne
        case errorTwo
        case errorThree
        case errorFour
        case errorFive
        case errorSix
        case errorSeven
        case errorEight
    }
    
    enum OtherError: Error, Equatable {
        case errorOne
    }
    
    func testWrappedCancellablePromiseThenableAPI() {
        let ex = expectation(description: "DispatchQueue Promise API")
        Promise.value(42).cancellize().then(on: .global()) { v -> Promise<Int> in
            Promise.value(v + 10)
        }.then(on: .global()) { v -> CancellablePromise<Int> in
            Promise.value(v + 10).cancellize()
        }.map(on: .global()) { v -> Int in
            v + 10
        }.get(on: .global()) {
            XCTAssert($0 == 72)
        }.tap(on: .global()) { result in
            if case let .success(x) = result {
                XCTAssert(x == 72)
            } else {
                XCTFail()
            }
        }.compactMap(on: .global()) { v -> Int in
            v + 10
        }.done(on: .global()) {
            XCTAssert($0 == 82)
            ex.fulfill()
        }.catch(on: .global()) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testWrappedCancellablePromiseRecoverAPI() {
        
        let ex = expectation(description: "DispatchQueue Promise recover API")
        var value = 0
        Promise.value(42).cancellize().then { _ -> Promise<Int> in
            throw TestError.errorOne
        // Specific error
        }.recover(only: TestError.errorOne, on: .global()) { _ -> Promise<Int> in
            value += 1
            throw TestError.errorTwo
        // Error type
        }.recover(only: TestError.self, on: .global()) { error -> Promise<Int> in
            XCTAssert(error == .errorTwo)
            value += 10
            throw TestError.errorThree
        // Any error
        }.recover(on: .global()) { error -> Promise<Int> in
            if let error = error as? TestError {
                XCTAssert(error == TestError.errorThree)
            } else {
                XCTFail()
            }
            value += 100
            throw TestError.errorFour
        // Specific error, cancellable
        }.recover(only: TestError.errorFour, on: .global()) { _ -> CancellablePromise<Int> in
            value += 1_000
            throw TestError.errorTwo
        // Error type, cancellable
        }.recover(only: TestError.self, on: .global()) { error -> CancellablePromise<Int> in
            XCTAssert(error == .errorTwo)
            value += 10_000
            throw TestError.errorThree
        // Any error, cancellable
        }.recover(on: .global()) { error -> CancellablePromise<Int> in
            if let error = error as? TestError {
                XCTAssert(error == TestError.errorThree)
            } else {
                XCTFail()
            }
            value += 100_000
            throw TestError.errorFour
        }.map(on: .global()) { _ -> Void in
            // NOP
        // Non-matching specific error
        }.recover(only: TestError.errorThree, on: .global()) { _ in
            XCTFail()
        // Specific error, void return
        }.recover(only: TestError.errorFour, on: .global()) { _ -> Void in
            value += 1_000_000
            throw OtherError.errorOne
        // Non-matching error class, void return
        }.recover(only: TestError.self, on: .global()) { error -> Void in
            XCTFail()
        }.recover(only: OtherError.self, on: .global()) { error in
            value += 10_000_000
            throw TestError.errorFive
        }.ensure(on: .global()) {
            value += 100_000_000
        }.catch { error in
            if let error = error as? TestError {
                XCTAssert(error == TestError.errorFive)
            } else {
                XCTFail()
            }
            value += 1_000_000_000
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
        XCTAssert(value == 1_111_111_111)
        
        let g: Any = Promise.value(42).cancellize().recover(on: .global()) { error in
            Guarantee.value(52)
        }
        XCTAssert(g is CancellablePromise<Int>)
        
        let g2: Any = Promise<Void>().cancellize().recover(on: .global()) { error -> Void in }
        XCTAssert(g2 is CancellablePromise<Void>)
    }
    
    func testWrappedCancellablePromiseCatchAPI() {
        let ex = expectation(description: "DispatchQueue Promise catch API")
        Promise.value(42).cancellize().then(on: .global()) { _ -> Promise<Int> in
            throw TestError.errorOne
        }.catch(only: OtherError.self, on: .global()) { error in
            XCTFail()
        }.catch(only: TestError.errorTwo, on: .global()) { _ in
            XCTFail()
        }.catch(only: TestError.self, on: .global()) { error in
            XCTAssert(error == .errorOne)
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
    }
    
    func testWrappedCancellablePromiseEnsureAPI() {
        let ex = expectation(description: "DispatchQueue Promise ensure API")
        var value = 0
        Promise.value(42).cancellize().ensure(on: .global()) {
            value += 1
        }.ensureThen(on: .global()) { () -> CancellablePromise<Void> in
            value += 10
            return Promise<Void>().cancellize()
        }.done(on: .global()) { _ in
            value += 100
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
        XCTAssert(value == 111)
    }
    
    func testWrappedCancellablePromiseSequenceAPI() {
        let ex = expectation(description: "DispatchQueue Promise sequence API")
        Promise.value([42, 52]).cancellize().mapValues(on: .global()) {
            $0 + 10
        }.flatMapValues(on: .global()) {
            [$0]
        }.compactMapValues(on: .global()) {
            $0
        }.thenMap(on: .global()) { v -> Promise<Int> in
            Promise.value(v)
        }.thenFlatMap(on: .global()) { v -> Promise<[Int]> in
            Promise.value([v])
        }.filterValues(on: .global()) { v -> Bool in
            v > 10
        }.firstValue(on: .global()) { v -> Bool in
            v > 60
        }.map(on: .global()) { v -> [Int] in
            XCTAssert(v == 62)
            return [82, 72]
        }.sortedValues(on: .global()).done { v in
            XCTAssert(v == [72, 82])
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
    }
}
