import Accounts
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `ACAccountStore` category:

    use_frameworks!
    pod "PromiseKit/ACAccountStore"

 And then in your sources:

    import PromiseKit
*/
extension ACAccountStore {
    public func renewCredentialsForAccount(account: ACAccount) -> Promise<ACAccountCredentialRenewResult> {
        return Promise { renewCredentialsForAccount(account, completion: $0) }
    }

    public func requestAccessToAccountsWithType(type: ACAccountType, options: [String: AnyObject]? = nil) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            requestAccessToAccountsWithType(type, options: options, completion: { granted, error in
                if granted {
                    fulfill()
                } else if error != nil {
                    reject(error)
                } else {
                    reject(Error.AccessDenied)
                }
            })
        }
    }

    public func saveAccount(account: ACAccount) -> Promise<Void> {
        return Promise<Bool> { saveAccount(account, withCompletionHandler: $0) }.asVoid()
    }

    public func removeAccount(account: ACAccount) -> Promise<Void> {
        return Promise<Bool> { removeAccount(account, withCompletionHandler: $0) }.asVoid()
    }

    public enum Error: ErrorType {
        case AccessDenied

        public var localizedDescription: String {
            switch self {
            case .AccessDenied:
                return "Access to the requested social service has been denied. Please enable access in your device settings."
            }
        }
    }
}
