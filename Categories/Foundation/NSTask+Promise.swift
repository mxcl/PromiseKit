import Foundation
#if !COCOAPODS
import PromiseKit
#endif

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
    public enum Error: ErrorType {
        case Encoding(stdout: NSData, stderr: NSData)
        case Execution(task: NSTask, stdout: NSData, stderr: NSData)

        public var localizedDescription: String {
            switch self {
            case .Encoding:
                return "Could not decode command output into string."
            case .Execution(let task, _, _):
                let cmd = ([task.launchPath ?? ""] + (task.arguments ?? [])).joinWithSeparator(" ")
                return "Failed executing: `\(cmd)`."
            }
        }
    }

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
        return promise().then(on: waldo) { (stdout: NSData, stderr: NSData, terminationStatus: Int) -> (String, String, Int) in
            guard let out = NSString(data: stdout, encoding: encoding), err = NSString(data: stderr, encoding: encoding) else {
                throw Error.Encoding(stdout: stdout, stderr: stderr)
            }

            return (out as String, err as String, terminationStatus)
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

        launch()

        return dispatch_promise {
            self.waitUntilExit()

            let stdout = self.standardOutput!.fileHandleForReading.readDataToEndOfFile()
            let stderr = self.standardError!.fileHandleForReading.readDataToEndOfFile()

            guard self.terminationReason == .Exit && self.terminationStatus == 0 else {
                throw Error.Execution(task: self, stdout: stdout, stderr: stderr)
            }

            return (stdout, stderr, Int(self.terminationStatus))
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
