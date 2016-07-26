import CoreBluetooth
import Foundation
#if !COCOAPODS
import PromiseKit
#endif


private class CentralManager: CBCentralManager, CBCentralManagerDelegate {
  
  let (promise, fulfill, reject) = CentralManagerPromise.deferred()
  
  @objc private func centralManagerDidUpdateState(central: CBCentralManager) {
    if central.state != .Unknown {
      fulfill(central)
    }
  }
}

extension CBCentralManager {
  
  public class func promise() -> CentralManagerPromise {
    let manager = CentralManager(delegate: nil, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    manager.delegate = manager
    manager.promise.always {
      manager.delegate = nil
    }
    return manager.promise
  }
}

public class CentralManagerPromise: Promise<CBCentralManager> {
  
  private let (parentPromise, fulfill, reject) = Promise<CBCentralManager>.pendingPromise()
  
  private class func deferred() -> (CentralManagerPromise, CBCentralManager -> Void, ErrorType -> Void) {
    var fullfill: (CBCentralManager -> Void)!
    var reject: (ErrorType -> Void)!
    let promise = CentralManagerPromise { fullfill = $0; reject = $1 }
    promise.parentPromise.then(on: zalgo) { fullfill($0) }
    promise.parentPromise.error { reject($0) }
    return (promise, promise.fulfill, promise.reject)
  }
  
  private override init(@noescape resolvers: (fulfill: (CBCentralManager) -> Void, reject: (ErrorType) -> Void) throws -> Void) {
    super.init(resolvers: resolvers)
  }
}

