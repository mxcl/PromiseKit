import Foundation

/// A `PromiseKit` `Dispatcher` that dispatches X closures every Y seconds,
/// on average.
///
/// This implementation is O(1) in both space and time, but it uses approximate
/// time accounting. Over the long term, the rate converges to a rate of X/Y,
/// but the transient burst rate will be up to 2X/Y in some situations.
///
/// For a completely accurate rate limiter that dispatches as rapidly as
/// possible, see `StrictRateLimitedDispatcher`. That implementation requires
/// additional storage.
///
/// Executions are paced by start time, not by completion, so it's possible to
/// end up with more than X closures running concurrently in some circumstances.
///
/// There is no guarantee that you will reach a given dispatch rate. There are not
/// an infinite number of threads available, and GCD scheduling has limited accuracy.
///
/// 100% thread safe.

public class RateLimitedDispatcher: RateLimitedDispatcherBase {
    
    private var tokensInBucket: Double = 0
    private var latestAccrual: DispatchTime = DispatchTime.now()
    private var retryWorkItem: DispatchWorkItem? { willSet { retryWorkItem?.cancel() }}
    
    private var tokensPerSecond: Double { return Double(maxDispatches) / interval }
    
    /// A `PromiseKit` `Dispatcher` that dispatches X executions every Y
    /// seconds, on average.
    ///
    /// This version is O(1) in space and time but uses an approximate algorithm with
    /// burst rates up to 2X per Y seconds. For a more accurate implementation, use
    /// `StrictRateLimitedDispatcher`.
    ///
    /// - Parameter maxDispatches: The number of executions that may be dispatched within a given interval.
    /// - Parameter perInterval: The length of the reference interval, in seconds.
    /// - Parameter queue: The DispatchQueue or Dispatcher on which to perform executions. May be serial or concurrent.

    override init(maxDispatches: Int, perInterval interval: TimeInterval, queue: Dispatcher = DispatchQueue.global()) {
        latestAccrual = DispatchTime.now()
        super.init(maxDispatches: maxDispatches, perInterval: interval, queue: queue)
        tokensInBucket = Double(maxDispatches)
    }
    
    override func dispatchFromQueue() {
    
        guard undispatched.count > 0 else { return }
        cleanupNonce += 1
        
        let now = DispatchTime.now()
        let tokensToAdd = (now - latestAccrual) * tokensPerSecond
        tokensInBucket = min(Double(maxDispatches - nDispatched), tokensInBucket + tokensToAdd)
        latestAccrual = now

        // print("runqueue \(now.rawValue), nDispatched = \(nDispatched), tokens = \(tokensInBucket), undispatched = \(undispatched.count)")

        var didDispatch = false
        while tokensInBucket >= 1.0 && !undispatched.isEmpty && nDispatched < maxDispatches {
            didDispatch = true
            tokensInBucket -= 1.0
            nDispatched += 1
            let body = undispatched.dequeue()
            queue.dispatch {
                self.serializer.async {
                    self.recordActualStart()
                }
                body()
            }
        }

        if !didDispatch {
            scheduleRetry()
        }

    }
    
    private func scheduleRetry() {
        guard retryWorkItem == nil && !undispatched.isEmpty && nDispatched < maxDispatches else { return }
        let tokenDeficit = 1 - tokensInBucket
        let secondsToGo = tokenDeficit / tokensPerSecond
        let deadline = latestAccrual + secondsToGo + 1.0E-6
        retryWorkItem = DispatchWorkItem { [weak self] in
            self?.retryWorkItem = nil
            self?.dispatchFromQueue()
        }
        serializer.asyncAfter(deadline: deadline, execute: retryWorkItem!)
    }
    
    override func cleanup(_ nonce: Int64) {
        super.cleanup(nonce)
        guard nonce == cleanupNonce else { return }
        tokensInBucket = Double(maxDispatches) // Avoid accumulating roundoff errors
    }

}

internal extension DispatchTime {
    static func -(a: DispatchTime, b: DispatchTime) -> TimeInterval {
        let delta = a.uptimeNanoseconds - b.uptimeNanoseconds
        return TimeInterval(delta) / 1_000_000_000
    }
}

