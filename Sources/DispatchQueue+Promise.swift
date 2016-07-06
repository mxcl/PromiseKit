import Dispatch

/**
 ```
 DispatchQueue.global().async {
     try md5(input)
 }.then { md5 in
     //…
 }
 ```

 - Parameter body: The closure that resolves this promise.
 - Returns: A new promise resolved by the provided closure.
*/
extension DispatchQueue {
    public func async<T>(execute body: () throws -> T) -> Promise<T> {
        return Promise(sealant: { resolve in
            contain_zalgo(self, rejecter: resolve) {
                resolve(.fulfilled(try body()))
            }
        })
    }
}
