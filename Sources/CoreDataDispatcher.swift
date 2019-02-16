#if !os(Linux)

import Foundation
import CoreData

public extension NSManagedObjectContext {
    var dispatcher: CoreDataDispatcher {
        return CoreDataDispatcher(self)
    }
}

/// A `Dispatcher` that dispatches onto the threads associated with
/// `NSManagedObjectContext`s, allowing Core Data operations to be
/// handled using promises.

public struct CoreDataDispatcher: Dispatcher {
    
    let context: NSManagedObjectContext
    
    public init(_ context: NSManagedObjectContext) {
        self.context = context
    }
    
    public func dispatch(_ body: @escaping () -> Void) {
        context.perform(body)
    }
    
}

#endif

