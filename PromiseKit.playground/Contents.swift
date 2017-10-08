import PlaygroundSupport

// Is this erroring? If so open the `.xcodeproj` and build the
// framework for a macOS target (usually labeled: “My Mac”).
// Then select `PromiseKit.playground` from inside Xcode.
import PromiseKit


func promise3() -> Promise<Int> {
    return after(seconds: 1).then {
        return 3
    }
}

firstly {
    Promise(value: 1)
}.then { _ in
    2
}.then { _ in
    promise3()
}.then {
    print($0)  // => 3
}.always {
    // always happens
}.catch { error in
    // only happens for errors
}

PlaygroundPage.current.needsIndefiniteExecution = true
