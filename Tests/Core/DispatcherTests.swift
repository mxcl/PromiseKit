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
    var dispatcherB = RecordingDispatcher()

    override func setUp() {
        dispatcher = RecordingDispatcher()
        dispatcherB = RecordingDispatcher()
    }
    
    func testConfD() {
        let ex = expectation(description: "conf.D")
        let oldConf = PromiseKit.conf.D
        PromiseKit.conf.D.map = dispatcher
        PromiseKit.conf.D.return = dispatcherB
        XCTAssertNil(PromiseKit.conf.Q.map, "conf.Q.map not nil")    // Not representable as DispatchQueues
        XCTAssertNil(PromiseKit.conf.Q.return, "conf.Q.return not nil")
        Promise { seal in
            seal.fulfill(42)
        }.map {
            $0 + 10
        }.done() {
            XCTAssertEqual($0, 52, "summation result != 52")
            XCTAssertEqual(self.dispatcher.dispatchCount, 1, "map dispatcher count != 1")
            XCTAssertEqual(self.dispatcherB.dispatchCount, 1, "return dispatcher count != 1")
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
        let testQueue = DispatchQueue(label: "test queue")
        PromiseKit.conf.D.map = testQueue  // Assign DispatchQueue to Dispatcher variable
        PromiseKit.conf.Q.return = testQueue   // Assign DispatchQueue to DispatchQueue variable
        XCTAssert(PromiseKit.conf.Q.map === testQueue, "did not get main DispatchQueue back from map")
        XCTAssert((PromiseKit.conf.D.return as? DispatchQueue)! === testQueue, "did not get main DispatchQueue back from return")
        PromiseKit.conf.D = oldConf
    }
    
    func testPMKDefaultIdentity() {
        // If this identity does not hold, the DispatchQueue wrapper API will not behave correctly
        XCTAssert(DispatchQueue.pmkDefault === DispatchQueue.pmkDefault, "DispatchQueues are not object-identity-preserving on this platform")
    }
    
    func testDispatcherWithThrow() {
        let ex = expectation(description: "Dispatcher with throw")
        Promise { seal in
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
        
        Promise.value(42).map(on: .global(qos: .background), flags: .barrier) { (x: Int) -> Int in
            let queueID = DispatchQueue.getSpecific(key: queueIDKey)
            XCTAssertNotNil(queueID)
            XCTAssertEqual(queueID!, 100)
            return x + 10
        }.get(on: .global(qos: .background), flags: .barrier) { _ in
        }.tap(on: .global(qos: .background), flags: .barrier) { _ in
        }.then(on: .main, flags: []) { (x: Int) -> Promise<Int> in
            XCTAssertEqual(x, 52)
            let queueID = DispatchQueue.getSpecific(key: queueIDKey)
            XCTAssertNotNil(queueID)
            XCTAssertEqual(queueID!, 102)
            return Promise.value(50)
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
        Promise.value([42, 52]).mapValues(on: .global(qos: .background), flags: .barrier) {
            $0 + 10
        }.compactMap(on: .global(qos: .background), flags: .barrier) {
            $0
        }.flatMapValues(on: .global(qos: .background), flags: .barrier) {
            [$0 + 10]
        }.compactMapValues(on: .global(qos: .background), flags: .barrier) {
            $0 + 10
        }.thenMap(on: .global(qos: .background), flags: .barrier) {
            Promise.value($0 + 10)
        }.thenFlatMap(on: .global(qos: .background), flags: .barrier) {
            Promise.value([$0 + 10])
        }.filterValues(on: .global(qos: .background), flags: .barrier) { _ in
            true
        }.sortedValues(on: .global(qos: .background), flags: .barrier).firstValue(on: .global(qos: .background), flags: .barrier) { _ in
            true
        }.done(on: .global(qos: .background), flags: .barrier) {
            XCTAssertEqual($0, 92)
            ex1.fulfill()
        }.catch(on: .global(qos: .background), flags: .barrier) { _ in
            XCTFail()
        }
        
        let ex2 = expectation(description: "DispatchQueue firstValue property")
        Promise.value([42, 52]).firstValue.done(on: .global(qos: .background), flags: .barrier) {
            XCTAssertEqual($0, 42)
            ex2.fulfill()
        }.catch(on: .global(qos: .background), flags: .barrier, policy: .allErrors) { _ in
            XCTFail()
        }
        
        let ex3 = expectation(description: "DispatchQueue lastValue property")
        Promise.value([42, 52]).lastValue.done(on: .global(qos: .background), flags: .barrier) {
            XCTAssertEqual($0, 52)
            ex3.fulfill()
        }.catch(on: .global(qos: .background), flags: .barrier, policy: .allErrors) { _ in
            XCTFail()
        }
        
        waitForExpectations(timeout: 5)
    }

    func testRecover() {
        let ex1 = expectation(description: "DispatchQueue CatchMixin compatibility")
        Promise.value(42).recover(on: .global(qos: .background), flags: .barrier) { _ in
            return Promise.value(42)
        }.ensure(on: .global(qos: .background), flags: .barrier) {
        }.ensureThen(on: .global(qos: .background), flags: .barrier) {
            return after(seconds: 0.0)
        }.recover(on: .global(qos: .background), flags: .barrier) { _ in
            return Promise.value(42)
        }.done(on: .global(qos: .background), flags: .barrier) {
            XCTAssertEqual($0, 42)
            ex1.fulfill()
        }.catch(on: .global(qos: .background), flags: .barrier) { _ in
            XCTFail()
        }
        
        let ex2 = expectation(description: "DispatchQueue CatchMixin Void recover")
        firstly {
            Promise.value(42).asVoid()
        }.recover(on: .global(qos: .background), flags: .barrier) { _ in
            throw PMKError.emptySequence
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
        let object: Any = dispatcher.dispatch() { () -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 1
        }
        XCTAssert(object is Guarantee<Int>, "Guarantee not returned from Dispatcher.dispatch { () -> Int }")
        (object as? Guarantee<Int>)?.done { one in
            XCTAssertEqual(one, 1)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatcherExtensionCanThrowInBody() {
        let ex = expectation(description: "Dispatcher.promise")
        let object: Any = dispatcher.dispatch() { () -> Int in
            throw PMKError.badInput
        }
        XCTAssert(object is Promise<Int>, "Promise not returned from Dispatcher.dispatch { () throws -> Int }")
        (object as? Promise<Int>)?.done { _ in
            XCTFail()
        }.catch { _ in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

}
