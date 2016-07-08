import PromiseKit

// for BridgingTests.m
@objc(PMKPromiseBridgeHelper) class PromiseBridgeHelper: NSObject {
    @objc func bridge1() -> AnyPromise {
        let p = after(interval: 0.01)
        return AnyPromise(p)
    }
}
