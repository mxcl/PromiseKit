import Foundation
import PromiseKit

/**
 To import the `NSTask` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `NSTask` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"
 
 And then in your sources:

    import PromiseKit
*/
extension NSTask {
    /**
     Launches the receiver and resolves when it exits.

     If the task fails the promise is rejected with code `PMKTaskError`, and
     `userInfo` keys `PMKTaskErrorStandardOutputKey`,
     `PMKTaskErrorStandardErrorKey` and `PMKTaskErrorExitStatusKey`.

     @return A promise that fulfills with three parameters:
       1) The stdout interpreted as a UTF8 string.
       2) The stderr interpreted as a UTF8 string.
       3) The exit code.
    */
    public func promise(encoding: NSStringEncoding = NSUTF8StringEncoding) -> Promise<(String, String, Int)> {
        return promise().then(on: waldo) { (stdout: NSData, stderr: NSData, terminationStatus: Int) -> Promise<(String, String, Int)> in
            if let out = NSString(data: stdout, encoding: encoding), err = NSString(data: stderr, encoding: encoding) {
                return Promise(out as String, err as String, terminationStatus)
            } else {
                return Promise(generateError("Could not decode command output into string.", stdout, stderr,
                    self))
            }
        }
    }

    /**
     Launches the receiver and resolves when it exits.

     If the task fails the promise is rejected with code `PMKTaskError`, and
     `userInfo` keys `PMKTaskErrorStandardOutputKey`,
     `PMKTaskErrorStandardErrorKey` and `PMKTaskErrorExitStatusKey`.

     @return A promise that fulfills with three parameters:
       1) The stdout as `NSData`.
       2) The stderr as `NSData`.
       3) The exit code.
    */
    public func promise() -> Promise<(NSData, NSData, Int)> {
        standardOutput = NSPipe()
        standardError = NSPipe()

        return Promise { fulfill, reject in
            launch()

            dispatch_async(dispatch_get_global_queue(0, 0)) {
                self.waitUntilExit()

                let stdout = self.standardOutput.fileHandleForReading.readDataToEndOfFile()
                let stderr = self.standardError.fileHandleForReading.readDataToEndOfFile()

                if self.terminationReason == .Exit && self.terminationStatus == 0 {
                    fulfill(stdout, stderr, Int(self.terminationStatus))
                } else {
                    let cmd = " ".join([self.launchPath] + (self.arguments as! [String]))
                    reject(generateError("Failed executing: `\(cmd)`.", stdout, stderr, self))
                }
            }
        }
    }

    /**
     Launches the receiver and resolves when it exits.

     If the task fails the promise is rejected with code `PMKTaskError`, and
     `userInfo` keys `PMKTaskErrorStandardOutputKey`,
     `PMKTaskErrorStandardErrorKey` and `PMKTaskErrorExitStatusKey`.

     @return A promise that fulfills with the stdout as a UTF8 interpreted String.
    */
    func promise() -> Promise<String> {
        return promise().then(on: zalgo) { (stdout: String, _, _) -> String in
            return stdout
        }
    }
}


//TODO get file system encoding from LANG as it may not be UTF8

private func generateError(description: String, stdout: NSData, stderr: NSData, task: NSTask) -> NSError {
    let info: [NSObject: AnyObject] = [
        NSLocalizedDescriptionKey: description,
        PMKTaskErrorLaunchPathKey: task.launchPath,
        PMKTaskErrorArgumentsKey: task.arguments,
        PMKTaskErrorStandardOutputKey: stdout,
        PMKTaskErrorStandardErrorKey: stderr,
        PMKTaskErrorExitStatusKey: Int(task.terminationStatus),
    ]
    return NSError(domain: PMKErrorDomain, code: PMKTaskError, userInfo: info)
}
