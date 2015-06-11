import Foundation
import PromiseKit
import XCPlayground


Promise(1).then { _ in
    return true
}.then {
    return 2
}.then {
    return Promise(3)
}.then { x -> AnyPromise in
    print(x)
    return AnyPromise(bound: Promise(1))
}.then(print)


firstly {
    return Promise(1)
}.then { _ in
    return 2
}.then {
    return Promise(3)
}


XCPSetExecutionShouldContinueIndefinitely()
