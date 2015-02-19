import Foundation

extension NSNotificationCenter {
    public func once(name: String) -> Promise<NSDictionary> {
        return once(name).then { (note:NSNotification) -> NSDictionary in
            return note.userInfo ?? [:]
        }
    }

    public func once(name: String) -> Promise<NSNotification> {
        return Promise { d in
            var id: AnyObject?
            id = NSNotificationCenter.defaultCenter().addObserverForName(name, object: nil, queue: Q){ note in
                d.fulfill(note)
                NSNotificationCenter.defaultCenter().removeObserver(id!)
            }
        }
    }
}
