import Accounts

extension ACAccountStore {
    func renewCredentials(account:ACAccount) -> Promise<ACAccountCredentialRenewResult> {
        return Promise { (fulfiller, rejecter) in
            self.renewCredentialsForAccount(account) {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0)
                }
            }
        }
    }

    func requestAccessToAccounts(type: ACAccountType, options:Dictionary<String, String>? = nil) -> Promise<Bool> {
        return Promise { (fulfiller, rejecter) in
            self.requestAccessToAccountsWithType(type, options:options) {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0)
                }
            }
        }
    }

    func remove(account: ACAccount) -> Promise<Bool> {
        return Promise { (fulfiller, rejecter) in
            self.removeAccount(account) {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0)
                }
            }
        }
    }
}
