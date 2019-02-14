import Dispatch
@testable import PromiseKit
import XCTest

class DispatcherTypeTests: XCTestCase {
    
    func testStrictRateLimiter() {
        
        var rng = Xoroshiro(0xBAD_DEFACED_FACADE, 0xDEAD_BEEF_CAFE_BABE)
        
        // Hiatus = longer pause in inflow (on the order of the interval)
        for hiatusLikelihoodPerInterval in [ 0.0, 0.3, 0.7 ] {
            for noDelayLikelihood in [ 0.0, 0.2, 0.75 ] {
                for interval in [ 0.025, 0.1 ] {
                    for most in [ 10, 30 ] {

        let n = most * 10
        let avgSlice = UInt32(interval * 1_000_000 * 0.9 / Double(most))
        let normalDelayRange = 0...avgSlice
        let hiatusRange = UInt32(interval * 0.5 * 1_000_000)...UInt32(interval * 2 * 1_000_000)
        let hiatusLikelihoodPerDispatch = 1 - pow(1 - hiatusLikelihoodPerInterval, 1 / Double(most))
        
        var delays: [UInt32] = []
        for _ in 1...n {
            let rand = Double.random(in: 0...1, using: &rng)
            if rand < hiatusLikelihoodPerDispatch {
                delays.append(hiatusRange.randomElement(using: &rng)!)
            } else if rand > (1 - noDelayLikelihood) {
                delays.append(0)
            } else {
                delays.append(normalDelayRange.randomElement(using: &rng)!)
            }
        }
        
        let nHiatuses = delays.count { $0 > avgSlice }
        print("\nNew run: n = \(n), most = \(most), interval = \(interval), pHiatus = \(hiatusLikelihoodPerInterval), nHiatuses = \(nHiatuses)\n")
        
        let dispatcher = StrictRateLimitedDispatcher(maxDispatches: most, perInterval: interval)
        let mostConcurrent = rateLimitTest(dispatcher, delays: delays, interval: interval)
        
        // Significantly less than the goal rate is also a potential concern
        XCTAssertGreaterThan(mostConcurrent, (most * 3) / 4)
        XCTAssertLessThanOrEqual(mostConcurrent, most)
        
        print("tail wait start", DispatchTime.now().rawValue)
        usleep(UInt32(interval * 1_000_000 * 1.25)) // FIXME
        print("tail wait end", DispatchTime.now().rawValue)
        XCTAssert(dispatcher.startTimeHistory.count == 0, "Dispatcher did not clean up properly")

                    }
                }
            }
        }
    }
    
    func rateLimitTest(_ dispatcher: Dispatcher, delays: [UInt32], interval: TimeInterval) -> Int {
        
        var startTimes: [DispatchTime] = []
        let lock = NSLock()
        let ex = expectation(description: "Rate limit")

        for delay in delays {
            usleep(delay)
            Guarantee.value(42).done(on: dispatcher) { _ in
                lock.lock()
                let now = DispatchTime.now()
                startTimes.append(now)
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

// Reproducible, seedable RNG

struct Xoroshiro: RandomNumberGenerator {
    
    typealias State = (UInt64, UInt64)
    
    var state: State
    
    init(_ a: UInt64, _ b: UInt64) {
        state = (a, b)
    }
    
    mutating func next() -> UInt64 {
        let (l, k0, k1, k2): (UInt64, UInt64, UInt64, UInt64) = (64, 55, 14, 36)
        let result = state.0 &+ state.1
        let x = state.0 ^ state.1
        state.0 = ((state.0 << k0) | (state.0 >> (l - k0))) ^ x ^ (x << k1)
        state.1 = (x << k2) | (x >> (l - k2))
        return result
    }
    
}
