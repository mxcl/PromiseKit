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

    #if !COCOAPODS
import PromiseKit
#endif
*/
extension NSFileManager {
    func removeItem(path path: String) -> Promise<String> {
        return dispatch_promise() {
            do {
                try self.removeItemAtPath(path)
                return (path, nil)
            } catch {
                return (nil, error as NSError)
            }
        }
    }

    func copyItem(from from: String, to: String) -> Promise<String> {
        return dispatch_promise() {
            do {
                try self.copyItemAtPath(from, toPath:to)
                return (to, nil)
            } catch {
                return (nil, error as NSError)
            }
        }
    }

    func moveItem(from from: String, to: String) -> Promise<String> {
        return dispatch_promise() {
            do {
                try self.moveItemAtPath(from, toPath: to)
                return (to, nil)
            } catch {
                return (nil, error as NSError)
            }
        }
    }

    func createDirectory(path path: String, withIntermediateDirectories with: Bool = true, attributes: [String : AnyObject]? = nil) -> Promise<String> {
        return dispatch_promise() {
            do {
                try self.createDirectoryAtPath(path, withIntermediateDirectories: with, attributes: attributes)
                return (path, nil)
            } catch {
                return (nil, error as NSError)
            }
        }
    }
}
