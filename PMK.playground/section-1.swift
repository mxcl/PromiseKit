import PlaygroundSupport
import PromiseKit

PlaygroundPage.current.needsIndefiniteExecution

// we use this later
enum Error: ErrorProtocol { case four }


firstly {
    return after(interval: 0.1)
}.then { zero in
    return 1
}.then { one in
    return 2
}.then { two in
    return after(interval: 0.1).then{ 3 }
}.then { three -> Void in
    throw Error.four
}.catch { error in
    print(error)

    PlaygroundPage.current.finishExecution()
}
