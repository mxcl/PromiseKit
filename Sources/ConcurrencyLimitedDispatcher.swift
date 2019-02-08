import Foundation

// A PromiseKit Dispatcher that runs no more than X simultaneous
// executions at once.

class ConcurrencyLimitedDispatcher: Dispatcher {
    
    let queue: Dispatcher
    let serialEntryQueue: DispatchQueue
    
    private let semaphore: DispatchSemaphore
    
    // A PromiseKit Dispatcher that runs no more than X simultaneous
    // executions at once.
    //
    // - Parameter limit: The number of executions that may run at once.
    // - Parameter queue: The DispatchQueue or Dispatcher on which to perform executions.
    //     Should be some form of concurrent queue.

    public init(limit: Int, queue: Dispatcher = DispatchQueue.global(qos: .background)) {
        self.queue = queue
        serialEntryQueue = DispatchQueue(label: "CLD entryway")
        semaphore = DispatchSemaphore(value: limit)
    }

    public func dispatch(_ body: @escaping () -> Void) {
        serialEntryQueue.async {
            self.semaphore.wait()
            self.queue.dispatch {
                body()
                self.semaphore.signal()
            }
        }
    }
    
}

