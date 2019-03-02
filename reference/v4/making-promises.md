---
layout: docs
title: Sealing Your Own Promises
redirect_from: "/sealing-your-own-promises/"
---

# Making Promises

`Promise<T>` provides a single initializer that makes it easy to wrap other asynchronous systems in a promise, let’s wrap this [Alamofire](https://github.com/Alamofire/Alamofire) request:

```swift
func login(completionHandler: (NSDictionary?, ErrorProtocol?) -> Void {
    Alamofire.request(.GET, url, parameters: ["foo": "bar"])
        .validate()
        .responseJSON { response in
            switch response.result {
            case .Success(let dict):
                completionHandler(dict, nil)
            case .Failure(let error):
                completionHandler(nil, error)
            }
        }
}
```

in a promise:

```swift
func login() -> Promise<NSDictionary> {
    return Promise { fulfill, reject in
        Alamofire.request(.GET, url, parameters: ["foo": "bar"])
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success(let dict):
                    fulfill(dict)
                case .Failure(let error):
                    reject(error)
                }
            }
    }
}
```

Now we can use it:

```swift
login().then { result in
    print(result)
}
```

Now we can chain it:

```swift
firstly {
    login()
}.then { dict in
    UIView.animate {
        self.label.text = dict
    }
}.then {
    promiseViewController(vc)
}.always {
    saveState()
}
```