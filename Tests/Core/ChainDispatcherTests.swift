import XCTest
@testable import PromiseKit

class ChainDispatcherTests: XCTestCase {

    var defaultBodyDispatcher = RecordingDispatcher()
    var defaultTailDispatcher = RecordingDispatcher()

    override func setUp() {
        conf.testMode = true  // Allow free resetting of defaults without warnings
        defaultBodyDispatcher.dispatchCount = 0
        defaultTailDispatcher.dispatchCount = 0
        conf.setDefaultDispatchers(body: defaultBodyDispatcher, tail: defaultTailDispatcher)
    }

    override func tearDown() {
        conf.setDefaultDispatchers(body: .default, tail: .default)
    }
    
    func captureLog(_ body: () -> Void) -> String? {
        
        var logOutput: String? = nil
        
        func captureLogger(_ event: LogEvent) {
            logOutput = "\(event)"
        }
        
        let oldLogger = conf.logHandler
        conf.logHandler = captureLogger
        body()
        conf.logHandler = oldLogger
        return logOutput
    }
    
    func testSimpleChain() {
        let ex = expectation(description: "Simple chain")
        Promise.value(42).then {
            Promise.value($0 + 10)
        }.map {
            $0 + 20
        }.get { _ in
            // NOP - should be body dispatcher
        }.done {
            ex.fulfill()
            XCTAssert($0 == 72)
        }.cauterize()
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 3)
        XCTAssert(defaultTailDispatcher.dispatchCount == 1)
    }

    func testPermanentTail() {
        let ex = expectation(description: "Permanent tail")
        Promise.value(42).then {
            Promise.value($0 + 10)
        }.map {
            $0 + 20
        }.get { _ in
            // NOP - should be body dispatcher
        }.done {
            XCTAssert($0 == 72)
        }.get { _ in
            // NOP - should be tail dispatcher
        }.map {
            123  // Tail
        }.catch { error in
            // NOP - not dispatched
        }.finally {
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 3)
        XCTAssert(defaultTailDispatcher.dispatchCount == 4)
    }
    
    func testSimpleChainDispatcher() {
        let ex = expectation(description: "Simple chain dispatcher")
        let dispatcher = RecordingDispatcher()
        let log = captureLog {
            Promise.value(42).then {
                Promise.value($0 + 10)
            }.map {
                $0 + 20
            }.dispatch(on: dispatcher).get { _ in
                // NOP - should be body dispatcher
            }.done {
                XCTAssert($0 == 72)
            }.get { _ in
                // NOP - should be tail dispatcher
            }.map {
                123  // Tail
            }.catch { error in
                // NOP - not dispatched
            }.finally {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 2)
        XCTAssert(defaultTailDispatcher.dispatchCount == 0)
        XCTAssert(dispatcher.dispatchCount == 5)
        XCTAssert(log == "failedToConfirmChainDispatcher")
    }

    func testRConfirmedChainDispatcher() {
        let ex = expectation(description: "Simple chain dispatcher")
        let dispatcher = RecordingDispatcher()
        let log = captureLog {
            Promise.value(42).then {
                Promise.value($0 + 10)
            }.map {
                $0 + 20
            }.dispatch(on: dispatcher).get { _ in
                // NOP - should be body dispatcher
            }.done(on: .chain) {
                XCTAssert($0 == 72)
            }.get { _ in
                // NOP - should be tail dispatcher
            }.map {
                123  // Tail
            }.catch { error in
                // NOP - not dispatched
            }.finally {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 2)
        XCTAssert(defaultTailDispatcher.dispatchCount == 0)
        XCTAssert(dispatcher.dispatchCount == 5)
        XCTAssert(log == nil)
    }

    func testResetChainDispatcher() {
        let ex = expectation(description: "Simple chain dispatcher")
        let dispatcher = RecordingDispatcher()
        let log = captureLog {
            Promise.value(42).dispatch(on: dispatcher).then {
                Promise.value($0 + 10)
            }.map {
                $0 + 20
            }.dispatch(on: .default).get { _ in
                // NOP - should be body dispatcher
            }.done {
                XCTAssert($0 == 72)
            }.get { _ in
                // NOP - should be tail dispatcher
            }.map {
                123  // Tail
            }.catch { error in
                // NOP - not dispatched
            }.finally {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 1)
        XCTAssert(defaultTailDispatcher.dispatchCount == 4)
        XCTAssert(dispatcher.dispatchCount == 2)
        XCTAssert(log == nil)
    }
    
    func testThresholdChainDispatcher() {
        let ex = expectation(description: "Simple chain dispatcher")
        let dispatcher = RecordingDispatcher()
        let log = captureLog {
            Promise.value(42).then {
                Promise.value($0 + 10)
            }.map {
                $0 + 20
            }.dispatch(on: dispatcher).done {
                XCTAssert($0 == 72)
            }.get { _ in
                // NOP - should be tail dispatcher
            }.map {
                123  // Tail
            }.catch { error in
                // NOP - not dispatched
            }.finally {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 2)
        XCTAssert(defaultTailDispatcher.dispatchCount == 0)
        XCTAssert(dispatcher.dispatchCount == 4)
        XCTAssert(log == nil)
    }

    func testIndefinitelyDelayedConfirmationChainDispatcher() {
        let ex = expectation(description: "Simple chain dispatcher")
        let dispatcher = RecordingDispatcher()
        let log = captureLog {
            Promise.value(42).dispatch(on: dispatcher).then {
                Promise.value($0 + 10)
            }.map {
                $0 + 20
            }.done(on: defaultTailDispatcher) {
                XCTAssert($0 == 72)
            }.map(on: defaultTailDispatcher) {
                123  // Tail
            }.catch(on: defaultTailDispatcher) { error in
                // NOP - not dispatched
            }.finally(on: defaultTailDispatcher) {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 0)
        XCTAssert(defaultTailDispatcher.dispatchCount == 3)
        XCTAssert(dispatcher.dispatchCount == 2)
        XCTAssert(log == nil)
    }
    
    func testDelayedConfirmationChainDispatcher() {
        let ex = expectation(description: "Simple chain dispatcher")
        let dispatcher = RecordingDispatcher()
        let log = captureLog {
            Promise.value(42).dispatch(on: dispatcher).then {
                Promise.value($0 + 10)
            }.map {
                $0 + 20
            }.done(on: defaultTailDispatcher) {
                XCTAssert($0 == 72)
            }.map(on: defaultTailDispatcher) {
                123  // Tail
            }.catch { error in
                // NOP - not dispatched
            }.finally {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 0)
        XCTAssert(defaultTailDispatcher.dispatchCount == 2)
        XCTAssert(dispatcher.dispatchCount == 3)
        XCTAssert(log == "failedToConfirmChainDispatcher")
    }

    func testStickyChainDispatcher() {
        let ex = expectation(description: "Sticky chain dispatcher")
        let dispatcher = RecordingDispatcher()
        let log = captureLog {
            Promise.value(42).dispatch(on: .sticky).then {
                Promise.value($0 + 10)
            }.map {
                $0 + 20
            }.done(on: dispatcher) {
                XCTAssert($0 == 72)
            }.map {
                123  // Tail
            }.catch { error in
                // NOP - not dispatched
            }.finally {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 2)
        XCTAssert(defaultTailDispatcher.dispatchCount == 0)
        XCTAssert(dispatcher.dispatchCount == 3)
        XCTAssert(log == nil)
    }
    
    func testUnconfirmedStickyChainDispatcher() {
        let ex = expectation(description: "Unconfirmed sticky chain dispatcher")
        let dispatcher = RecordingDispatcher()
        let log = captureLog {
            Promise.value(42).dispatch(on: .sticky).then(on: dispatcher) {
                Promise.value($0 + 10)
            }.map {
                $0 + 20
            }.done {
                XCTAssert($0 == 72)
            }.map(on: defaultTailDispatcher) {
                123  // Tail
            }.catch { error in
                // NOP - not dispatched
            }.finally {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 0)
        XCTAssert(defaultTailDispatcher.dispatchCount == 2)
        XCTAssert(dispatcher.dispatchCount == 3)
        XCTAssert(log == "failedToConfirmChainDispatcher")
    }

    func testAdHocStickyDispatchers() {
        let ex = expectation(description: "Ad hoc sticky dispatching")
        let dispatcher = RecordingDispatcher()
        let log = captureLog {
            Promise.value(42).then(on: dispatcher) {
                Promise.value($0 + 10)
            }.map(on: .sticky) {
                $0 + 20
            }.done(on: .sticky) {
                XCTAssert($0 == 72)
            }.map(on: defaultBodyDispatcher) {
                123  // Tail
            }.catch(on: .sticky) { error in
                // NOP - not dispatched
            }.finally {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
        XCTAssert(defaultBodyDispatcher.dispatchCount == 1)
        XCTAssert(defaultTailDispatcher.dispatchCount == 1)
        XCTAssert(dispatcher.dispatchCount == 3)
        XCTAssert(log == nil)
    }
}

