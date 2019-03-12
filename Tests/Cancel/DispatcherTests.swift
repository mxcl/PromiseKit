import Dispatch
import PromiseKit
import XCTest

fileprivate let queueIDKey = DispatchSpecificKey<Int>()

class RecordingDispatcher: Dispatcher {
    
    static var queueIndex = 1
    
    var dispatchCount = 0
    let queue: DispatchQueue
    
    init() {
        queue = DispatchQueue(label: "org.promisekit.testqueue \(RecordingDispatcher.queueIndex)")
        RecordingDispatcher.queueIndex += 1
    }
    
    func dispatch(_ body: @escaping () -> Void) {
        dispatchCount += 1
        queue.async(execute: body)
    }
    
}

class DispatcherTests: XCTestCase {
    
    var dispatcher = RecordingDispatcher()

    override func setUp() {
        dispatcher = RecordingDispatcher()
    }
    
    func testDispatcherWithThrow() {
        let ex = expectation(description: "Dispatcher with throw")
        CancellablePromise { seal in
            seal.fulfill(42)
        }.map(on: dispatcher) { _ in
            throw PMKError.badInput
        }.catch(on: dispatcher) { _ in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
        XCTAssertEqual(self.dispatcher.dispatchCount, 2)
    }
    
    func testDispatchQueueSelection() {
        
        let ex = expectation(description: "DispatchQueue compatibility")
        
        let oldConf = PromiseKit.conf.D
        PromiseKit.conf.D = (map: dispatcher, return: dispatcher)
        
        let background = DispatchQueue.global(qos: .background)
        background.setSpecific(key: queueIDKey, value: 100)
        DispatchQueue.main.setSpecific(key: queueIDKey, value: 102)
        dispatcher.queue.setSpecific(key: queueIDKey, value: 103)

        cancellize(Promise.value(42)).map(on: .global(qos: .background), flags: .barrier) { (x: Int) -> Int in
            let queueID = DispatchQueue.getSpecific(key: queueIDKey)
            XCTAssertNotNil(queueID)
            XCTAssertEqual(queueID!, 100)
            return x + 10
        }.get(on: .global(qos: .background), flags: .barrier) { _ in
        }.tap(on: .global(qos: .background), flags: .barrier) { _ in
        }.then(on: .main, flags: []) { (x: Int) -> CancellablePromise<Int> in
            XCTAssertEqual(x, 52)
            let queueID = DispatchQueue.getSpecific(key: queueIDKey)
            XCTAssertNotNil(queueID)
            XCTAssertEqual(queueID!, 102)
            return cancellize(Promise.value(50))
        }.map(on: nil) { (x: Int) -> Int in
            let queueID = DispatchQueue.getSpecific(key: queueIDKey)
            XCTAssertNotNil(queueID)
            XCTAssertEqual(queueID!, 102)
            return x + 10
        }.map { (x: Int) -> Int in
            XCTAssertEqual(x, 60)
            let queueID = DispatchQueue.getSpecific(key: queueIDKey)
            XCTAssertNotNil(queueID)
            XCTAssertEqual(queueID!, 103)
            return x + 10
        }.done(on: background) {
            XCTAssertEqual($0, 70)
            let queueID = DispatchQueue.getSpecific(key: queueIDKey)
            XCTAssertNotNil(queueID)
            XCTAssertEqual(queueID!, 100)
            ex.fulfill()
        }.cauterize()
        
        waitForExpectations(timeout: 1)
        PromiseKit.conf.D = oldConf
        
    }
    
    func testMapValues() {
        let ex1 = expectation(description: "DispatchQueue MapValues compatibility")
        cancellize(Promise.value([42, 52])).cancellableThen(on: .global(qos: .background), flags: .barrier) {
            Promise.value($0)
        }.compactMap(on: .global(qos: .background), flags: .barrier) {
            $0
        }.mapValues(on: .global(qos: .background), flags: .barrier) {
            $0 + 10
        }.flatMapValues(on: .global(qos: .background), flags: .barrier) {
            [$0 + 10]
        }.compactMapValues(on: .global(qos: .background), flags: .barrier) {
            $0 + 10
        }.thenMap(on: .global(qos: .background), flags: .barrier) {
            cancellize(Promise.value($0 + 10))
        }.cancellableThenMap(on: .global(qos: .background), flags: .barrier) {
            Promise.value($0 + 10)
        }.thenFlatMap(on: .global(qos: .background), flags: .barrier) {
            cancellize(Promise.value([$0 + 10]))
        }.cancellableThenFlatMap(on: .global(qos: .background), flags: .barrier) {
            Promise.value([$0 + 10])
        }.filterValues(on: .global(qos: .background), flags: .barrier) { _ in
            true
        }.sortedValues(on: .global(qos: .background), flags: .barrier).firstValue(on: .global(qos: .background), flags: .barrier) { _ in
            true
        }.done(on: .global(qos: .background), flags: .barrier) {
            XCTAssertEqual($0, 112)
            ex1.fulfill()
        }.catch(on: .global(qos: .background), flags: .barrier) { _ in
            XCTFail()
        }
        
        let ex2 = expectation(description: "DispatchQueue firstValue property")
        cancellize(Promise.value([42, 52])).firstValue.done(on: .global(qos: .background), flags: .barrier) {
            XCTAssertEqual($0, 42)
            ex2.fulfill()
        }.catch(on: .global(qos: .background), flags: .barrier, policy: .allErrors) { _ in
            XCTFail()
        }
        
         let ex3 = expectation(description: "DispatchQueue lastValue property")
        cancellize(Promise.value([42, 52])).lastValue.done(on: .global(qos: .background), flags: .barrier) {
            XCTAssertEqual($0, 52)
            ex3.fulfill()
        }.catch(on: .global(qos: .background), flags: .barrier, policy: .allErrors) { _ in
            XCTFail()
        }
        
       waitForExpectations(timeout: 1)
    }
    
    func testRecover() {
        let ex1 = expectation(description: "DispatchQueue CatchMixin compatibility")
        cancellize(Promise.value(42)).recover(on: .global(qos: .background), flags: .barrier) { _ in
            return cancellize(Promise.value(42))
        }.ensure(on: .global(qos: .background), flags: .barrier) {
        }.ensureThen(on: .global(qos: .background), flags: .barrier) {
            return cancellize(Promise.value(42).asVoid())
        }.recover(on: .global(qos: .background), flags: .barrier) { _ in
            return cancellize(Promise.value(42))
        }.cancellableRecover(on: .global(qos: .background), flags: .barrier) { _ in
            return Promise.value(42)
        }.done(on: .global(qos: .background), flags: .barrier) {
            XCTAssertEqual($0, 42)
            ex1.fulfill()
        }.catch(on: .global(qos: .background), flags: .barrier) { _ in
            XCTFail()
        }

        let ex2 = expectation(description: "DispatchQueue CatchMixin Void recover")
        firstly {
            cancellize(Promise.value(42).asVoid())
        }.recover(on: .global(qos: .background), flags: .barrier) { _ in
        }.done {
            ex2.fulfill()
        }.catch(on: .global(qos: .background), flags: .barrier) { _ in
            XCTFail()
        }
        
        waitForExpectations(timeout: 1)
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatcherExtensionReturnsGuarantee() {
        let ex = expectation(description: "Dispatcher.promise")
        cancellize(dispatcher.dispatch() { () -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 1
        }).done { one in
            XCTAssertEqual(one, 1)
            ex.fulfill()
        }.catch { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 1)
    }
    
    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatcherExtensionCanThrowInBody() {
        let ex = expectation(description: "Dispatcher.promise")
        cancellize(dispatcher.dispatch() { () -> Int in
            throw PMKError.badInput
        }).done { _ in
            XCTFail()
        }.catch { _ in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

}
