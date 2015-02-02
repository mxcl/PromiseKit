import Accounts

extension ACAccountStore {
    public func renewCredentials(# account: ACAccount) -> Promise<ACAccountCredentialRenewResult> {
        return Promise { (fulfiller, rejecter) in
            self.renewCredentialsForAccount(account) {
                if $1 != nil {
                    rejecter($1)
                } else {
                    fulfiller($0)
                }
            }
        }
    }

    public func requestAccessToAccounts(# type: ACAccountType, options:Dictionary<String, AnyObject>? = nil) -> Promise<Void> {
        return Promise { (fulfill, reject) in
            self.requestAccessToAccountsWithType(type, options:options) {
                if $1 != nil {
                    reject($1)
                } else {
                    fulfill()
                }
            }
        }
    }

    public func save(# account: ACAccount) -> Promise<Void> {
        return Promise { (fulfill, reject) in
            self.saveAccount(account) {
                if $0 {
                    fulfill()
                } else {
                    reject($1)
                }
            }
        }
    }

    public func remove(# account: ACAccount) -> Promise<Void> {
        return Promise { (fulfill, reject) in
            self.removeAccount(account) {
                if $1 != nil {
                    reject($1)
                } else {
                    fulfill()
                }
            }
        }
    }
}
