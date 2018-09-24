import Foundation
import PromiseKit
import XCTest

class BridgingTests: XCTestCase {

    func testCanBridgeAnyObject() {
        let sentinel = NSURLRequest()
        let p = Promise.value(sentinel)
        let ap = AnyPromise(p)

        XCTAssertEqual(ap.value(forKey: "value") as? NSURLRequest, sentinel)
    }

    func testCanBridgeOptional() {
        let sentinel: NSURLRequest? = NSURLRequest()
        let p = Promise.value(sentinel)
        let ap = AnyPromise(p)

        XCTAssertEqual(ap.value(forKey: "value") as? NSURLRequest, sentinel)
    }

    func testCanBridgeSwiftArray() {
        let sentinel = [NSString(), NSString(), NSString()]
        let p = Promise.value(sentinel)
        let ap = AnyPromise(p)

        guard let foo = ap.value(forKey: "value") as? [NSString] else { return XCTFail() }
        XCTAssertEqual(foo, sentinel)
    }

    func testCanBridgeSwiftDictionary() {
        let sentinel = [NSString(): NSString()]
        let p = Promise.value(sentinel)
        let ap = AnyPromise(p)

        guard let foo = ap.value(forKey: "value") as? [NSString: NSString] else { return XCTFail() }
        XCTAssertEqual(foo, sentinel)
    }

    func testCanBridgeInt() {
        let sentinel = 3
        let p = Promise.value(sentinel)
        let ap = AnyPromise(p)
        XCTAssertEqual(ap.value(forKey: "value") as? Int, sentinel)
    }

    func testCanBridgeString() {
        let sentinel = "a"
        let p = Promise.value(sentinel)
        let ap = AnyPromise(p)
        XCTAssertEqual(ap.value(forKey: "value") as? String, sentinel)
    }

    func testCanBridgeBool() {
        let sentinel = true
        let p = Promise.value(sentinel)
        let ap = AnyPromise(p)
        XCTAssertEqual(ap.value(forKey: "value") as? Bool, sentinel)
    }

    func testCanChainOffAnyPromiseFromObjC() {
        let ex = expectation(description: "")

        firstly {
            .value(1)
        }.then { _ -> AnyPromise in
            return PromiseBridgeHelper().value(forKey: "bridge2") as! AnyPromise
        }.done { value in
            XCTAssertEqual(123, value as? Int)
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations(timeout: 1)
    }

    func testCanThenOffAnyPromise() {
        let ex = expectation(description: "")

        PMKDummyAnyPromise_YES().then { obj -> Promise<Void> in
            if let value = obj as? NSNumber {
                XCTAssertEqual(value, NSNumber(value: true))
                ex.fulfill()
            }
            return Promise()
        }.silenceWarning()

        waitForExpectations(timeout: 1)
    }

    func testCanThenOffManifoldAnyPromise() {
        let ex = expectation(description: "")

        PMKDummyAnyPromise_Manifold().then { obj -> Promise<Void> in
            defer { ex.fulfill() }
            XCTAssertEqual(obj as? NSNumber, NSNumber(value: true), "\(obj ?? "nil") is not @YES")
            return Promise()
        }.silenceWarning()

        waitForExpectations(timeout: 1)
    }

    func testCanAlwaysOffAnyPromise() {
        let ex = expectation(description: "")

        PMKDummyAnyPromise_YES().then { obj -> Promise<Void>  in
            ex.fulfill()
            return Promise()
        }.silenceWarning()

        waitForExpectations(timeout: 1)
    }

    func testCanCatchOffAnyPromise() {
        let ex = expectation(description: "")
        PMKDummyAnyPromise_Error().catch { err in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testAsPromise() {
    #if swift(>=3.1)
        XCTAssertTrue(Promise(PMKDummyAnyPromise_Error()).isRejected)
        XCTAssertEqual(Promise(PMKDummyAnyPromise_YES()).value as? NSNumber, NSNumber(value: true))
    #else
        XCTAssertTrue(PMKDummyAnyPromise_Error().asPromise().isRejected)
        XCTAssertEqual(PMKDummyAnyPromise_YES().asPromise().value as? NSNumber, NSNumber(value: true))
    #endif
    }

    func testFirstlyReturningAnyPromiseSuccess() {
        let ex = expectation(description: "")
        firstly {
            PMKDummyAnyPromise_Error()
        }.catch { error in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testFirstlyReturningAnyPromiseError() {
        let ex = expectation(description: "")
        firstly {
            PMKDummyAnyPromise_YES()
        }.done { _ in
            ex.fulfill()
        }.silenceWarning()
        waitForExpectations(timeout: 1)
    }

    func test1() {
        let ex = expectation(description: "")

        // AnyPromise.then { return x }

        let input = after(seconds: 0).map{ 1 }

        AnyPromise(input).then { obj -> Promise<Int> in
            XCTAssertEqual(obj as? Int, 1)
            return .value(2)
        }.done { value in
            XCTAssertEqual(value, 2)
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations(timeout: 1)
    }

    func test2() {
        let ex = expectation(description: "")

        // AnyPromise.then { return AnyPromise }

        let input = after(seconds: 0).map{ 1 }

        AnyPromise(input).then { obj -> AnyPromise in
            XCTAssertEqual(obj as? Int, 1)
            return AnyPromise(after(seconds: 0).map{ 2 })
        }.done { obj in
            XCTAssertEqual(obj as? Int, 2)
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations(timeout: 1)
    }

    func test3() {
        let ex = expectation(description: "")

        // AnyPromise.then { return Promise<Int> }

        let input = after(seconds: 0).map{ 1 }

        AnyPromise(input).then { obj -> Promise<Int> in
            XCTAssertEqual(obj as? Int, 1)
            return after(seconds: 0).map{ 2 }
        }.done { value in
            XCTAssertEqual(value, 2)
            ex.fulfill()
        }.silenceWarning()

        waitForExpectations(timeout: 1, handler: nil)
    }


    // can return AnyPromise (that fulfills) in then handler
    func test4() {
        let ex = expectation(description: "")
        Promise.value(1).then { _ -> AnyPromise in
            return AnyPromise(after(seconds: 0).map{ 1 })
        }.done { x in
            XCTAssertEqual(x as? Int, 1)
            ex.fulfill()
        }.silenceWarning()
        waitForExpectations(timeout: 1, handler: nil)
    }

    // can return AnyPromise (that rejects) in then handler
    func test5() {
        let ex = expectation(description: "")

        Promise.value(1).then { _ -> AnyPromise in
            let promise = after(.milliseconds(100)).done{ throw Error.dummy }
            return AnyPromise(promise)
        }.catch { err in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testStandardSwiftBridgeIsUnambiguous() {
        let p = Promise.value(1)
        let q = Promise(p)

        XCTAssertEqual(p.value, q.value)
    }

    /// testing NSError to Error for cancelledError types
    func testErrorCancellationBridging() {
        let ex = expectation(description: "")

        let p = Promise().done {
            throw LocalError.cancel as NSError
        }
        p.catch { _ in
            XCTFail()
        }
        p.catch(policy: .allErrors) {
            XCTAssertTrue($0.isCancelled)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)

        // here we verify that Swift’s NSError bridging works as advertised

        XCTAssertTrue(LocalError.cancel.isCancelled)
        XCTAssertTrue((LocalError.cancel as NSError).isCancelled)
    }
}

private enum Error: Swift.Error {
    case dummy
}

extension Promise {
    func silenceWarning() {}
}

private enum LocalError: CancellableError {
    case notCancel
    case cancel

    var isCancelled: Bool {
        switch self {
        case .notCancel: return false
        case .cancel: return true
        }
    }
}
