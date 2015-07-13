import Foundation.NSNotification

/**
 To import the `NSNotificationCenter` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `NSNotificationCenter` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    import PromiseKit
*/
extension NSNotificationCenter {
    class func once(name: String) -> Promise<[NSObject: AnyObject]> {
        return once(name).then(on: zalgo) { (note: NSNotification) -> [NSObject: AnyObject] in
            return note.userInfo ?? [:]
        }
    }

    class func once(name: String) -> Promise<NSNotification> {
        return Promise { fulfill, _ in
            var id: AnyObject?
            id = NSNotificationCenter.defaultCenter().addObserverForName(name, object: nil, queue: PMKOperationQueue){ note in
                fulfill(note)
                NSNotificationCenter.defaultCenter().removeObserver(id!)
            }
        }
    }
}
