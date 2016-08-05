import Foundation
import PromiseKit
import XCPlayground


Promise(1).then { _ -> Promise<Int> in
    print("1")
    return Promise(2).always {
        print("2")
    }.then { _ -> Int in
        print("3")
        return 1
    }
}.then { _ -> Void in
    print("4")
}.error() { error in

}


XCPSetExecutionShouldContinueIndefinitely()


