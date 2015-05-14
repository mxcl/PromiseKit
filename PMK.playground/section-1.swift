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
    println(x)
    return AnyPromise(bound: Promise(1))
}.then(println)


firstly {
    return Promise(1)
}.then { _ in
    return 2
}.then {
    return Promise(3)
}


XCPSetExecutionShouldContinueIndefinitely()
