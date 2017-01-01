import PlaygroundSupport
import PromiseKit

PlaygroundPage.current.needsIndefiniteExecution = true

after(interval: 0.1).then{ true }
after(interval: 0.1).then{ }

after(interval: 0.1).then{ 1 }.then {
    print($0)
    print("foo")
    print("bar")
}

//after(interval: 0.1).then {
//    print("foo")
//    print("bar")
//    return 1  // bah! error FIXME
//}

//
//extension Promise where Value: Data {
//
//}

extension Promise where Value: Data {

}
