import class Foundation.NSError

extension Promise {
    
    /**
     Create a new pending promise.

     This initializer is convenient when wrapping asynchronous systems that
     use common patterns. For example:

         func fetchKitten() -> Promise<UIImage> {
             return Promise.wrap { resolve in
                 KittenFetcher.fetchWithCompletionBlock(resolve)
             }
         }

     - SeeAlso: init(resolvers:)
    */
    public class func wrap(resolver: @noescape ((T?, NSError?) -> Void) throws -> Void) -> Promise {
        return Promise { fulfill, reject in
            try resolver { obj, err in
                if let obj = obj {
                    fulfill(obj)
                } else if let err = err {
                    reject(err)
                } else {
                    reject(Error.invalidCompletionHandlerCallingConvention)
                }
            }
        }
    }

    /**
     Create a new pending promise.

     This initializer is convenient when wrapping asynchronous systems that
     use common patterns. For example:

         func fetchKitten() -> Promise<UIImage> {
             return Promise.wrap { resolve in
                 KittenFetcher.fetchWithCompletionBlock(resolve)
             }
         }

     - SeeAlso: init(resolvers:)
    */
    public class func wrap(resolver: @noescape ((T, NSError?) -> Void) throws -> Void) -> Promise  {
        return Promise { fulfill, reject in
            try resolver { obj, err in
                if let err = err {
                    reject(err)
                } else {
                    fulfill(obj)
                }
            }
        }
    }
}
