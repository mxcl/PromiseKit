//
//  EKEventStore+Promise.swift
//  PromiseKit
//
//  Created by Lammert Westerhoff on 16/02/16.
//  Copyright © 2016 Max Howell. All rights reserved.
//

import CoreFoundation
import Foundation.NSError
import EventKit

#if !COCOAPODS
    import PromiseKit
#endif

public enum EventKitError: ErrorType {
    case Restricted
    case Denied

    public var localizedDescription: String {
        switch self {
        case .Restricted:
            return "A head of family must grant calendar access."
        case .Denied:
            return "Calendar access has been denied."
        }
    }
}

/**
 Requests access to the event store.

 To import `EKEventStore`:

 use_frameworks!
 pod "PromiseKit/EventKit"

 And then in your sources:

 import PromiseKit

 @return A promise that fulfills with the EKEventStore.
 */
public func EKEventStoreRequestAccess() -> Promise<(EKEventStore)> {
    let eventStore = EKEventStore()
    return Promise { fulfill, reject in

        let authorization = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        switch authorization {
        case .Authorized:
            fulfill(eventStore)
        case .Denied:
            reject(EventKitError.Denied)
        case .Restricted:
            reject(EventKitError.Restricted)
        case .NotDetermined:
            eventStore.requestAccessToEntityType(EKEntityType.Event) { granted, error in
                if granted {
                    fulfill(eventStore)
                } else {
                    reject(EventKitError.Denied)
                }
            }
        }
    }
}
