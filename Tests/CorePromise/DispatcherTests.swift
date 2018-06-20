import PromiseKit
import XCTest

class RecordingDispatcher: Dispatcher {
    
    var dispatchCount = 0
    
    func async(_ body: @escaping () -> Void) {
        dispatchCount += 1
        DispatchQueue.global(qos: .background).async(execute: body)
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
        XCTAssertNil(PromiseKit.conf.Q.map)    // Not representable as DispatchQueues
        XCTAssertNil(PromiseKit.conf.Q.return)
        Promise { seal in
            seal.fulfill(42)
        }.map {
            $0 + 10
        }.done() {
            XCTAssertEqual($0, 52)
            XCTAssertEqual(self.dispatcher.dispatchCount, 1)
            XCTAssertEqual(self.dispatcherB.dispatchCount, 1)
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
        PromiseKit.conf.D.map = DispatchQueue.main
        PromiseKit.conf.Q.return = .main
        XCTAssert(PromiseKit.conf.Q.map === DispatchQueue.main)
        XCTAssert((PromiseKit.conf.D.return as? DispatchQueue)! === DispatchQueue.main)
        PromiseKit.conf.D = oldConf
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
    
    func testDispatchQueueBackwardCompatibility() {
        let ex = expectation(description: "DispatchQueue compatibility")
        let oldConf = PromiseKit.conf.D
        PromiseKit.conf.D = (map: dispatcher, return: dispatcher)
        Promise.value(42).map(on: .global(qos: .background), flags: .barrier) { (x: Int) -> Int in
            return x + 10
        }.then(on: .main, flags: []) {
            XCTAssertEqual($0, 52)
            return Promise.value(50)
        }.done(on: .global(qos: .userInitiated)) {
            XCTAssertEqual($0, 50)
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
        XCTAssertEqual(self.dispatcher.dispatchCount, 0)
        PromiseKit.conf.D = oldConf
    }

    func testDispatcherPromiseExtension() {
        let ex = expectation(description: "Dispatcher.promise")
        dispatcher.promise {
            return 42
        }.done(on: dispatcher) {
            XCTAssertEqual($0, 42)
            XCTAssertEqual(self.dispatcher.dispatchCount, 2)
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
    }

    func testDispatcherGuaranteeExtension() {
        let ex = expectation(description: "Dispatcher.guarantee")
        dispatcher.guarantee {
            return 42
        }.done(on: .main) {
            XCTAssertEqual($0, 42)
            XCTAssertEqual(self.dispatcher.dispatchCount, 1)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

}
