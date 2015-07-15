import Foundation.NSFileManager
#if !COCOAPODS
import PromiseKit
#endif

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
    func removeItem(path path: String) -> Promise<String> {
        return dispatch_promise() {
            try self.removeItemAtPath(path)
            return path
        }
    }

    func copyItem(from from: String, to: String) -> Promise<String> {
        return dispatch_promise() {
            try self.copyItemAtPath(from, toPath:to)
            return to
        }
    }

    func moveItem(from from: String, to: String) -> Promise<String> {
        return dispatch_promise() {
            try self.moveItemAtPath(from, toPath: to)
            return to
        }
    }

    func createDirectory(path path: String, withIntermediateDirectories with: Bool = true, attributes: [String : AnyObject]? = nil) -> Promise<String> {
        return dispatch_promise() {
            try self.createDirectoryAtPath(path, withIntermediateDirectories: with, attributes: attributes)
            return path
        }
    }
}
