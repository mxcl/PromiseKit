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
    public func renewCredentialsForAccount(_ account: ACAccount) -> Promise<ACAccountCredentialRenewResult> {
        return Promise { renewCredentials(for: account, completion: $0) }
    }

    public func requestAccessToAccountsWithType(_ type: ACAccountType, options: [String: AnyObject]? = nil) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            requestAccessToAccounts(with: type, options: options, completion: { granted, error in
                if granted {
                    fulfill()
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.accessDenied)
                }
            })
        }
    }

    public func saveAccount(_ account: ACAccount) -> Promise<Void> {
        return Promise<Bool> { saveAccount(account, withCompletionHandler: $0) }.asVoid()
    }

    public func removeAccount(_ account: ACAccount) -> Promise<Void> {
        return Promise<Bool> { removeAccount(account, withCompletionHandler: $0) }.asVoid()
    }

    public enum Error: ErrorProtocol {
        case accessDenied

        public var localizedDescription: String {
            switch self {
            case .accessDenied:
                return "Access to the requested social service has been denied. Please enable access in your device settings."
            }
        }
    }
}
