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
extension Task {
    public enum Error: ErrorProtocol {
        case encoding(stdout: Data, stderr: Data)
        case execution(task: Task, stdout: Data, stderr: Data)

        public var localizedDescription: String {
            switch self {
            case .encoding:
                return "Could not decode command output into string."
            case .execution(let task, _, _):
                let cmd = ([task.launchPath ?? ""] + (task.arguments ?? [])).joined(separator: " ")
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
    public func promise(_ encoding: String.Encoding = String.Encoding.utf8) -> Promise<(String, String, Int)> {
        return promise().then(on: waldo) { (stdout: Data, stderr: Data, terminationStatus: Int) -> (String, String, Int) in
            guard let out = String(bytes: stdout, encoding: encoding), let err = String(bytes: stderr, encoding: encoding) else {
                throw Error.encoding(stdout: stdout, stderr: stderr)
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
    public func promise() -> Promise<(Data, Data, Int)> {
        standardOutput = Pipe()
        standardError = Pipe()

        launch()

        return DispatchQueue.global().promise {
            self.waitUntilExit()

            let stdout = self.standardOutput!.fileHandleForReading.readDataToEndOfFile()
            let stderr = self.standardError!.fileHandleForReading.readDataToEndOfFile()

            guard self.terminationReason == .exit && self.terminationStatus == 0 else {
                throw Error.execution(task: self, stdout: stdout, stderr: stderr)
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
