import CloudKit


extension CKContainer {
    public func accountStatus() -> Promise<CKAccountStatus> {
        return Promise { (fulfill, reject) in
            self.accountStatusWithCompletionHandler { (status, error) in
                if error == nil { fulfill(status) } else { reject(error) }
            }
        }
    }

    public func requestApplicationPermission(applicationPermissions: CKApplicationPermissions) -> Promise<CKApplicationPermissionStatus> {
        return Promise { (fulfill, reject) in
            self.requestApplicationPermission(applicationPermissions) { (status, error) in
                if error == nil { fulfill(status) } else { reject(error) }
            }
        }
    }

    public func statusForApplicationPermission(applicationPermissions: CKApplicationPermissions) -> Promise<CKApplicationPermissionStatus> {
        return Promise { (fulfill, reject) in
            self.statusForApplicationPermission(applicationPermissions) { (status, error) in
                if error == nil { fulfill(status) } else { reject(error) }
            }
        }
    }

    public func discoverAllContactUserInfos() -> Promise<[CKDiscoveredUserInfo]> {
        return Promise { (fulfill, reject) in
            self.discoverAllContactUserInfosWithCompletionHandler { (userInfos, error) in
                if error == nil { fulfill(userInfos as [CKDiscoveredUserInfo]) } else { reject(error) }
            }
        }
    }

    public func discoverUserInfo(# email: String) -> Promise<CKDiscoveredUserInfo> {
        return Promise { (fulfill, reject) in
            self.discoverUserInfoWithEmailAddress(email) { (info, error) in
                if error == nil { fulfill(info) } else { reject(error) }
            }
        }
    }

    public func discoverUserInfo(# recordID: CKRecordID) -> Promise<CKDiscoveredUserInfo> {
        return Promise { (fulfill, reject) in
            self.discoverUserInfoWithUserRecordID(recordID) { (info, error) in
                if error == nil { fulfill(info) } else { reject(error) }
            }
        }
    }

    public func fetchUserRecordID() -> Promise<CKRecordID> {
        return Promise { (fulfill, reject) in
            self.fetchUserRecordIDWithCompletionHandler { (recordID, error) -> Void in
                if error == nil { fulfill(recordID) } else { reject(error) }
            }
        }
    }
}
