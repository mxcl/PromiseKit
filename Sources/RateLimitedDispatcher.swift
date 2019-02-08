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

a sliding window, so executions occur as rapidly as
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

public class StrictRateLimitedDispatcher: Dispatcher {
    
    let maxDispatches: Int
    let interval: TimeInterval
    let queue: Dispatcher
    
    private let serializer = DispatchQueue(label: "SRLD serializer")
    
    private var nScheduled = 0
    private var unscheduled = Queue<() -> Void>()
    internal var startTimeHistory: Queue<DispatchTime>
    private var latestDeadline = DispatchTime(uptimeNanoseconds: 0)
    
    private var cleanupNonce: Int64 = 0
    private var cleanupWorkItem: DispatchWorkItem? { willSet { cleanupWorkItem?.cancel() }}
    
    /// A `PromiseKit` Dispatcher that executes no more than X executions every Y
    /// seconds. This is a sliding window, so executions occur as rapidly as
    /// possible without exceeding X in any Y-second period.
    ///
    /// For a "pretty good" approach to rate limiting that does not consume
    /// additional storage, see `RateLimitedDispatcher`.
    ///
    /// - Parameter maxDispatches: The number of executions that may be dispatched within a given interval.
    /// - Parameter perInterval: The length of the reference interval, in seconds.
    /// - Parameter queue: The DispatchQueue or Dispatcher on which to perform executions. May be serial or concurrent.
    
    public init(maxDispatches: Int, perInterval interval: TimeInterval, queue: Dispatcher = DispatchQueue.global()) {
        self.maxDispatches = maxDispatches
        self.interval = interval
        self.queue = queue
        startTimeHistory = Queue<DispatchTime>(maxDepth: maxDispatches)
    }
    
    public func dispatch(_ body: @escaping () -> Void) {
        serializer.async {
            self.unscheduled.enqueue(body)
            self.scheduleNext()
        }
    }
    
    private func scheduleNext() {
        
        cleanupNonce += 1
        
        guard nScheduled < maxDispatches else { return }
        guard !unscheduled.isEmpty else { return }
        
        var deadline = DispatchTime.now()
        if !startTimeHistory.isEmpty {
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
        
        let body = unscheduled.dequeue()
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
        nScheduled += 1
        
    }
    
    private func recordActualStartTime(_ time: DispatchTime) {
        nScheduled -= 1
        startTimeHistory.enqueue(time)
        scheduleNext()
        if nScheduled == 0 && unscheduled.isEmpty {
            scheduleCleanup()
        }
    }
    
    private func scheduleCleanup() {
        cleanupWorkItem = DispatchWorkItem { [ weak self, nonce = self.cleanupNonce ] in
            self?.cleanup(nonce)
        }
        serializer.asyncAfter(deadline: DispatchTime.now() + interval, execute: cleanupWorkItem!)
    }
    
    private func cleanup(_ nonce: Int64) {
        // Calls to cleanup() have to go through the serializer queue, so by by the time
        // we get here, more activity may have occurred. Ergo, verify nonce.
        guard nonce == cleanupNonce else { return }
        startTimeHistory.purge() // We're at least an interval past last start
        unscheduled.compactStorage()
        cleanupWorkItem = nil
    }
    
}
