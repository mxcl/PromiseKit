import AddressBook
import CoreFoundation
import Foundation.NSError
#if !COCOAPODS
import PromiseKit
#endif

public enum AddressBookError: ErrorType {
    case NotDetermined
    case Restricted
    case Denied

    public var localizedDescription: String {
        switch self {
        case .NotDetermined:
            return "Access to the address book could not be determined."
        case .Restricted:
            return "A head of family must grant address book access."
        case .Denied:
            return "Address book access has been denied."
        }
    }
}

/**
 Requests access to the address book.

 To import `ABAddressBookRequestAccess`:

    use_frameworks!
    pod "PromiseKit/AddressBook"

 And then in your sources:

    import PromiseKit

 @return A promise that fulfills with the ABAuthorizationStatus.
*/
public func ABAddressBookRequestAccess() -> Promise<ABAuthorizationStatus> {
    return ABAddressBookRequestAccess().then(on: zalgo) { (_, _) -> ABAuthorizationStatus in
        return ABAddressBookGetAuthorizationStatus()
    }
}

/**
 Requests access to the address book.

 To import `ABAddressBookRequestAccess`:

    pod "PromiseKit/AddressBook"

 And then in your sources:

    import PromiseKit

 @return A promise that fulfills with the ABAddressBook instance if access was granted.
*/
public func ABAddressBookRequestAccess() -> Promise<ABAddressBook> {
    return ABAddressBookRequestAccess().then(on: zalgo) { (granted, book) -> Promise<ABAddressBook> in
        guard granted else {
            switch ABAddressBookGetAuthorizationStatus() {
            case .NotDetermined:
                throw AddressBookError.NotDetermined
            case .Restricted:
                throw AddressBookError.Restricted
            case .Denied:
                throw AddressBookError.Denied
            case .Authorized:
                fatalError("This should not happen")
            }
        }

        return Promise(book)
    }
}

extension NSError {
    private convenience init(CFError error: CoreFoundation.CFError) {
        let domain = CFErrorGetDomain(error) as String
        let code = CFErrorGetCode(error)
        let info = CFErrorCopyUserInfo(error) as [NSObject: AnyObject]
        self.init(domain: domain, code: code, userInfo: info)
    }
}

private func ABAddressBookRequestAccess() -> Promise<(Bool, ABAddressBook)> {
    var error: Unmanaged<CFError>? = nil
    guard let ubook = ABAddressBookCreateWithOptions(nil, &error) else {
        return Promise(error: NSError(CFError: error!.takeRetainedValue()))
    }

    let book: ABAddressBook = ubook.takeRetainedValue()
    return Promise { fulfill, reject in
        ABAddressBookRequestAccessWithCompletion(book) { granted, error in
            if error == nil {
                fulfill(granted, book)
            } else {
                reject(NSError(CFError: error))
            }
        }
    }
}
