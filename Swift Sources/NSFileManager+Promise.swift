import Foundation.NSFileManager


extension NSFileManager {
    func removeItemAtPath(path: String) -> Promise<String> {
        return dispatch_promise() {
            var error: NSError?
            self.removeItemAtPath(path, error:&error)
            return error ?? path
        }
    }

    func copyItem(# from: String, to: String) -> Promise<String> {
        return dispatch_promise() {
            var error: NSError?
            self.copyItemAtPath(from, toPath:to, error:&error)
            return error ?? to
        }
    }

    func moveItem(# from: String, to: String) -> Promise<String> {
        return dispatch_promise() {
            var error: NSError?
            self.moveItemAtPath(from, toPath: to, error: &error)
            return error ?? to
        }
    }

    func createDirectoryAtPath(path: String, withIntermediateDirectories with: Bool = true, attributes: NSDictionary? = nil) -> Promise<String> {
        return dispatch_promise() {
            var error: NSError?
            self.createDirectoryAtPath(path, withIntermediateDirectories: with, attributes: attributes, error: &error)
            return error ?? path
        }
    }
}