import Foundation

/// A `PromiseKit` `Dispatcher` that dispatches no more than X closures every Y
/// seconds. This is a sliding window, so executions occur as rapidly as
/// possible without exceeding X in any Y-second period.
///
/// This version implements perfectly accurate timing, so it must (temporarily)
/// keep track of up to X previous execution times.
///
/// For a "pretty good" approach to rate limiting that does not consume
/// additional storage, see `RateLimitedDispatcher`.
///
/// Executions are paced by start time, not by completion, so it's possible to
/// end up with more than X closures running concurrently in some circumstances.
///
/// There is no guarantee that you will reach a given dispatch rate. There are not
/// an infinite number of threads available, and GCD scheduling has limited accuracy.
/// The only guarantee is that dispatching will never exceed the requested rate.
///
/// 100% thread safe.

public class StrictRateLimitedDispatcher: RateLimitedDispatcherBase {
    
    internal var startTimeHistory: Queue<DispatchTime>
    private var immediateDispatchesAvailable: Int
    private var latestDeadline = DispatchTime(uptimeNanoseconds: 0)
    
    /// A `PromiseKit` `Dispatcher` that dispatches no more than X executions every Y
    /// seconds. This is a sliding window, so executions occur as rapidly as
    /// possible without exceeding X in any Y-second period.
    ///
    /// For a "pretty good" approach to rate limiting that does not consume
    /// additional storage, see `RateLimitedDispatcher`.
    ///
    /// - Parameter maxDispatches: The number of executions that may be dispatched within a given interval.
    /// - Parameter perInterval: The length of the reference interval, in seconds.
    /// - Parameter queue: The DispatchQueue or Dispatcher on which to perform executions. May be serial or concurrent.
    
    override init(maxDispatches: Int, perInterval interval: TimeInterval, queue: Dispatcher = DispatchQueue.global()) {
        startTimeHistory = Queue<DispatchTime>(maxDepth: maxDispatches)
        immediateDispatchesAvailable = maxDispatches
        super.init(maxDispatches: maxDispatches, perInterval: interval, queue: queue)
    }
    
    override func dispatchFromQueue() {
        
        cleanupNonce += 1
        
        guard nDispatched < maxDispatches else { return }
        guard !undispatched.isEmpty else { return }
        
        let accountedFor = nDispatched + startTimeHistory.count + immediateDispatchesAvailable
        assert(accountedFor == maxDispatches, "Dispatcher bookkeeping problem")

        var deadline = DispatchTime.now()
        if immediateDispatchesAvailable > 0 {
            immediateDispatchesAvailable -= 1
        } else {
            // Use the start time of a previous closure as a time reference. In practice,
            // past start times will normally be reported and recorded in monotonically
            // increasing sequence, which yields optimal scheduling. However, this is all
            // potentially multithreaded, so there are no order guarantees. However, if any
            // start times ARE out of order, the algorithm is still correct: for each
            // dispatched item, another may be scheduled interval seconds later. Like kanban.
            deadline = max(deadline, startTimeHistory.dequeue() + interval)
        }
        // Enforce a monotonically increasing outbound schedule to keep calls in order
        if deadline <= latestDeadline {
            deadline = DispatchTime(uptimeNanoseconds: latestDeadline.uptimeNanoseconds + 1)
        }
        
        let body = undispatched.dequeue()
        // A Dispatcher has no asyncAfter; use the serializer queue for timing
        serializer.asyncAfter(deadline: deadline) {
            self.queue.dispatch {
                let now = DispatchTime.now()
                self.serializer.async {
                    self.recordActualStartTime(now)
                }
                body()
            }
        }
        
        latestDeadline = deadline
        nDispatched += 1
        
    }
    
    private func recordActualStartTime(_ time: DispatchTime) {
        startTimeHistory.enqueue(time)
        super.recordActualStart()
    }
    
    override func cleanup(_ nonce: Int64) {
        super.cleanup(nonce)
        guard nonce == cleanupNonce else { return }
        startTimeHistory.purge() // We're at least an interval past last start
        immediateDispatchesAvailable = maxDispatches
    }
    
}
