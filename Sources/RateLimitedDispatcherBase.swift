import Foundation

public class RateLimitedDispatcherBase: Dispatcher {
    
    let maxDispatches: Int
    let interval: TimeInterval
    let queue: Dispatcher
    
    let serializer = DispatchQueue(label: "RLD serializer")
    
    var nDispatched = 0
    var undispatched = Queue<() -> Void>()
    
    var cleanupNonce: Int64 = 0
    var cleanupWorkItem: DispatchWorkItem? { willSet { cleanupWorkItem?.cancel() }}
    
    public init(maxDispatches: Int, perInterval interval: TimeInterval, queue: Dispatcher = DispatchQueue.global()) {
        self.maxDispatches = maxDispatches
        self.interval = interval
        self.queue = queue
    }
    
    public func dispatch(_ body: @escaping () -> Void) {
        serializer.async {
            self.undispatched.enqueue(body)
            self.dispatchFromQueue()
        }
    }
    
    func dispatchFromQueue() {
        fatalError("Subclass responsibility")
    }
    
    func recordActualStart() {
        nDispatched -= 1
        dispatchFromQueue()
        if nDispatched == 0 && undispatched.isEmpty {
            scheduleCleanup()
        }
    }
    
    func scheduleCleanup() {
        cleanupWorkItem = DispatchWorkItem { [ weak self, nonce = self.cleanupNonce ] in
            self?.cleanup(nonce)
        }
        serializer.asyncAfter(deadline: DispatchTime.now() + interval, execute: cleanupWorkItem!)
    }
    
    func cleanup(_ nonce: Int64) {
        // Calls to cleanup() have to go through the serializer queue, so by by the time
        // we get here, more activity may have occurred. Ergo, verify nonce.
        guard nonce == cleanupNonce else { return }
        undispatched.compactStorage()
        cleanupWorkItem = nil
    }
    
}
