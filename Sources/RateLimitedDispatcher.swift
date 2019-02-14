import Foundation

/// A `PromiseKit` `Dispatcher` that executes, on average, no more than X
/// executions every Y seconds.
///
/// This implementation uses a token bucket, so the transient burst rate may be
/// up to 2X in a Y-second period. If you need an ironclad guarantee of
/// conformance to the rate limit, you can specify an X that's half the true
/// value; however, this will halve the average throughput as well.
///
/// For a completely accurate rate limiter that dispatches as rapidly as
/// possible, see `StrictRateLimitedDispatcher`. But note that this variant
/// incurs a 
///
/// a sliding window, so executions occur as rapidly as
/// possible without exceeding X in any Y-second period.
///
/// This version implements perfectly accurate timing, so it must keep
/// track of up to X previous execution times. Records are freed when they expire,
/// so an idle scheduler does not incur this storage cost.
///
/// For a "pretty good" approach to rate limiting that does not consume
/// additional storage, see RateLimitedDispatcher.
///
/// Executions are limited by start time, not completion, so it's possible to
/// end up with more than X closures running concurrently in some circumstances.
///
/// There is no guarantee that you will reach the given dispatch rate. There are not
/// an infinite number of threads available, and GCD scheduling has limited accuracy.
/// The only guarantee is that dispatching will never exceed the requested rate.
///
/// 100% thread safe.

public class RateLimitedDispatcher: RateLimitedDispatcherBase {
    
    private var tokensInBucket: Double = 0
    private var lastAccrual: DispatchTime = DispatchTime.now()
    private var retryWorkItem: DispatchWorkItem? { willSet { retryWorkItem?.cancel() }}
    
    override init(maxDispatches: Int, perInterval interval: TimeInterval, queue: Dispatcher = DispatchQueue.global()) {
        lastAccrual = DispatchTime.now()
        super.init(maxDispatches: maxDispatches, perInterval: interval, queue: queue)
        tokensInBucket = Double(maxDispatches)
    }
    
    override func dispatchFromQueue() {
    
        let now = DispatchTime.now()
        let tokensPerSecond = Double(maxDispatches) / interval
        let tokensToAdd = (now - lastAccrual) * tokensPerSecond
        tokensInBucket = min(Double(maxDispatches), tokensInBucket + tokensToAdd)
        lastAccrual = now
        
        var didDispatch = false
        while tokensInBucket >= 1.0 && !undispatched.isEmpty && nScheduled < maxDispatches {
            didDispatch = true
            tokensInBucket -= 1.0
            nScheduled += 1
            let body = unscheduled.dequeue()
            queue.dispatch {
                self.serializer.async {
                    self.recordActualStart()
                }
                body()
            }
        }

        if didDispatch {
            cleanupNonce += 1
        } else {
            scheduleRetry()
        }

    }
    
    private func scheduleRetry() {
        guard nScheduled == 0 && retryWorkItem == nil else { return }
        let tokensPerSecond = Double(maxDispatches) / interval
        let tokenDeficit = 1.0 - tokensInBucket
        let secondsToGo = tokenDeficit / tokensPerSecond
        let deadline = lastAccrual + secondsToGo + 1.0E-6
        let retryWorkItem = DispatchWorkItem {
            self?.retryWorkItem = nil
            self?.dispatchFromQueue()
        }
        serializer.asyncAfter(deadline: deadline, execute: retryWorkItem!)
    }

}
