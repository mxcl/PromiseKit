var promise = Promise(value: 1)
promise.value!

let disaster = NSError(domain: "MyErrorDomain", code: 0, userInfo: nil)
promise = Promise<Int>(error: disaster)
promise.error!.localizedDescription
