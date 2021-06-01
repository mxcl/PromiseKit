#if canImport(HomeKit) && !os(tvOS) && !os(watchOS)
#if !PMKCocoaPods
import PromiseKit
#endif
import HomeKit

@available(iOS 9.0, *)
extension HMEventTrigger {

    @available(iOS 11.0, *)
    public func updateExecuteOnce(_ executeOnce: Bool) -> Promise<Void> {
        return Promise { seal in
            self.updateExecuteOnce(executeOnce, completionHandler: seal.resolve)
        }
    }

}

#endif
