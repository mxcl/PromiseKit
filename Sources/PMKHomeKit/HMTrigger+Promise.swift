#if canImport(HomeKit) && !os(tvOS) && !os(watchOS)
#if !PMKCocoaPods
import PromiseKit
#endif
import HomeKit

extension HMTrigger {

    @available(iOS 8.0, *)
    public func updateName(_ name: String) -> Promise<Void> {
        return Promise { seal in
            self.updateName(name, completionHandler: seal.resolve)
        }
    }

    @available(iOS 8.0, *)
    public func enable(_ enabled: Bool) -> Promise<Void> {
        return Promise { seal in
            self.enable(enabled, completionHandler: seal.resolve)
        }
    }

    @available(iOS 8.0, *)
    public func addActionSet(_ actionSet: HMActionSet) -> Promise<Void> {
        return Promise { seal in
            self.addActionSet(actionSet, completionHandler: seal.resolve)
        }
    }

    @available(iOS 8.0, *)
    public func removeActionSet(_ actionSet: HMActionSet) -> Promise<Void> {
        return Promise { seal in
            self.removeActionSet(actionSet, completionHandler: seal.resolve)
        }
    }

}

#endif
