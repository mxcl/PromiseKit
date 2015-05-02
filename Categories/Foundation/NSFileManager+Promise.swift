import Foundation.NSFileManager
import PromiseKit

/**
 To import the `NSFileManager` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `NSFileManager` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    import PromiseKit
*/
extension NSFileManager {
    func removeItemAtPath(path: String) -> Promise<String> {
        return dispatch_promise() {
            var error: NSError?
            self.removeItemAtPath(path, error:&error)
            return (path, error)
        }
    }

    func copyItem(# from: String, to: String) -> Promise<String> {
        return dispatch_promise() {
            var error: NSError?
            self.copyItemAtPath(from, toPath:to, error:&error)
            return (to, error)
        }
    }

    func moveItem(# from: String, to: String) -> Promise<String> {
        return dispatch_promise() {
            var error: NSError?
            self.moveItemAtPath(from, toPath: to, error: &error)
            return (to, error)
        }
    }

    func createDirectoryAtPath(path: String, withIntermediateDirectories with: Bool = true, attributes: [NSObject : AnyObject]? = nil) -> Promise<String> {
        return dispatch_promise() {
            var error: NSError?
            self.createDirectoryAtPath(path, withIntermediateDirectories: with, attributes: attributes, error: &error)
            return (path, error)
        }
    }
}
