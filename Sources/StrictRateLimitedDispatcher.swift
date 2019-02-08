import Foundation

// A PromiseKit Dispatcher that initiates no more than X executions every Y
// seconds. This version is accurate; see RateLimitedDispatcher for a more
// efficient approximation.

public class StrictRateLimitedDispatcher: Dispatcher {
    
    let maxEvents: Int
    let interval: TimeInterval
    let queue: Dispatcher

    private let serializer = DispatchQueue(label: "SRLD serializer")

    private var pastDispatchTimes: [DispatchTime] = []
    private var nextPDT = 0
    
    private var latestCleanupTime: DispatchTime = DispatchTime.distantFuture
    private var cleanupTimer: Timer? { willSet { cleanupTimer?.invalidate() }}
    
    // A PromiseKit Dispatcher that initiates no more than X executions every Y
    // seconds. This is a sliding window, so executions occur as rapidly as
    // possible without exceeding X in any Y-second period.
    //
    // This version implements perfectly accurate timing, so it must keep
    // track of up to X previous execution times at a cost of 8X bytes. Records are
    // freed when they expire, so an idle scheduler incurs only trivial storage cost.
    //
    // For a "pretty good" approach to rate limiting that does not consume
    // additional storage, see RateLimitedDispatcher.
    //
    // Executions are limited by start time, not completion, so it's possible to
    // end up with more than X closures running concurrently in odd circumstances.
    //
    // 100% thread safe.
    //
    // - Parameter maxEvents: The number of executions that may be dispatched within any given period.
    // - Parameter perInterval: The length of the reference interval, in seconds.
    // - Parameter queue: The DispatchQueue or Dispatcher on which to perform executions. May be serial or concurrent.

    init(maxEvents: Int, perInterval interval: TimeInterval, queue: Dispatcher = DispatchQueue.main) {
        self.maxEvents = maxEvents
        self.interval = interval
        self.queue = queue
    }

    func dispatch(_ body: @escaping () -> Void) {
        serializer.async {
            self.enqueue(body)
        }
    }
    
    private func enqueue(_ body: @escaping () -> Void) {
        let deadline = nextDeadline()
        serializer.asyncAfter(deadline: deadline) {
            self.queue.dispatch(body)
        }
        latestCleanupTime = deadline + interval  // Must have a complete interval with no activity
        let timeBeforeCleanup = max(latestCleanupTime - DispatchTime.now(), 0)
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: timeBeforeCleanup, repeats: false) {
            serializer.async(execute: self.cleanup)
        }
    }
    
    private func cleanup() {
        // Calls to cleanup() have to go through the serializer queue, so by by the time
        // we get here, more blocks may have been enqueued. So double-check that our
        // original deadline hasn't been superseded.
        guard DispatchTime.now() >= latestCleanupTime else { return }
        pastDispatchTimes.removeAll(keepingCapacity: false)
        nextPDT = 0
    }

    private func nextDeadline() -> DispatchTime {
        let now = DispatchTime.now()
        if pastDispatchTimes.count < maxEvents {
            pastDispatchTimes.append(now)
            return now
        } else {
            let deadline = max(pastDispatchTimes[nextPDT] + interval, now)
            pastDispatchTimes[nextPDT] = deadline
            nextPDT += 1
            if nextPDT >= maxEvents {
                nextPDT = 0
            }
            return deadline
        }
    }

}
