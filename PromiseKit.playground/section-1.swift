import PlaygroundSupport
import PromiseKit

firstly {
    Promise(value: 1)
}.then { _ in
    2
}.then { _ in
    3
}.catch { error in
    // never happens!
}

PlaygroundPage.current.needsIndefiniteExecution = true
