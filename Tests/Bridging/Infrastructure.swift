import PromiseKit

// for BridgingTests.m
@objc(PMKPromiseBridgeHelper) class PromiseBridgeHelper: NSObject {
    @objc func bridge1() -> AnyPromise {
        let p = after(interval: .milliseconds(10))
        return AnyPromise(p)
    }
}

enum MyError: Error {
    case PromiseError()
}

@objc class TestPromise626: NSObject {

    @objc class func promise() -> AnyPromise {
        let promise: Promise<String> = Promise(resolvers: { _, reject in
            reject(MyError.PromiseError())
        })

        return AnyPromise(promise)
    }
}
