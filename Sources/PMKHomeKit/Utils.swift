import Foundation
#if !PMKCocoaPods
import PromiseKit
#endif

/**
    Commonly used functionality when promisifying a delegate pattern
*/
internal class PromiseProxy<T>: NSObject {
    internal let (promise, seal) = Promise<T>.pending();
    
    private var retainCycle: PromiseProxy?

    override init() {
        super.init()
        // Create a retain cycle
        self.retainCycle = self
        // And ensure we break it when the promise is resolved
        _ = promise.ensure { self.retainCycle = nil }
    }
    
    /// These functions ensure we only resolve the promise once
    internal func fulfill(_ value: T) {
        guard self.promise.isResolved == false else { return }
        seal.fulfill(value)
    }
    internal func reject(_ error: Error) {
        guard self.promise.isResolved == false else { return }
        seal.reject(error)
    }
    
    /// Cancel helper
    internal func cancel() {
        self.reject(PMKError.cancelled)
    }
}

/**
    Different ways to scan.
*/
public enum ScanInterval {
    // Return after our first item with an optional time limit
    case returnFirst(timeout: TimeInterval?)
    // Scan for this duration before returning all
    case returnAll(interval: TimeInterval)
}
