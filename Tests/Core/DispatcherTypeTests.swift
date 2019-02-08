import Dispatch
@testable import PromiseKit
import XCTest

class DispatcherTypeTests: XCTestCase {
    
    func testStrictRateLimitedDispatcher() {
        
        let most = 10
        let interval = 0.05
        let n = most * 20
        
        let avgSlice = UInt32(interval * 1_000_000 * 0.9 / Double(most))
        let delayRange = 0...(2 * avgSlice)
        
        let dispatcher = StrictRateLimitedDispatcher(maxDispatches: most, perInterval: interval)
        let delays = (1...n).map { _ in delayRange.randomElement()! }
        let mostConcurrent = rateLimitTest(dispatcher, delays: delays, interval: interval)
        
        // Significantly less than the goal rate is also a potential concern
        XCTAssertGreaterThan(mostConcurrent, (most * 3) / 4)
        XCTAssertLessThanOrEqual(mostConcurrent, most)
        
        usleep(UInt32(interval * 1_000_000) + 100_000)
        XCTAssert(dispatcher.startTimeHistory.count == 0, "Dispatcher did not clean up properly")
        
    }

    func rateLimitTest(_ dispatcher: Dispatcher, delays: [UInt32], interval: TimeInterval) -> Int {
        
        var startTimes: [DispatchTime] = []
        let lock = NSLock()
        let ex = expectation(description: "Rate limit")

        for delay in delays {
            usleep(delay)
            Guarantee.value(42).done(on: dispatcher) { _ in
                lock.lock()
                startTimes.append(DispatchTime.now())
                if startTimes.count == delays.count {
                    ex.fulfill()
                }
                lock.unlock()
            }
        }
        
        let totalDelay = Double(delays.reduce(0, +)) / 1_000_000
        let expectedDuration = interval * Double(delays.count)
        let adequateTime = max(expectedDuration, totalDelay) * 1.5
        waitForExpectations(timeout: adequateTime)
        
        return mostAtOnce(startTimes, interval: interval)
        
    }

    func mostAtOnce(_ times: [DispatchTime], interval: TimeInterval) -> Int {
        var most = 0
        for start in times {
            let timeRange = start...(start + interval)
            let pruned = times.filter { timeRange.contains($0) }
            most = max(most, pruned.count)
        }
        return most
    }
    
}
