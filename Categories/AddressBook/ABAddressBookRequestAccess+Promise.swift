import AddressBook
import CoreFoundation
import Foundation.NSError
import PromiseKit

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
        if granted {
            return Promise(book)
        } else {
            switch ABAddressBookGetAuthorizationStatus() {
            case .NotDetermined:
                return Promise(error: "Access to the address book could not be determined.")
            case .Restricted:
                return Promise(error: "A head of family must grant address book access.")
            case .Denied:
                return Promise(error: "Address book access has been denied.")
            case .Authorized:
                return Promise(book)  // shouldn’t be possible
            }
        }
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
    let ubook = ABAddressBookCreateWithOptions(nil, &error)
    if ubook != nil {
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
    } else {
        return Promise(NSError(CFError: error!.takeRetainedValue()))
    }
}
