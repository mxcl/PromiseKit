---
layout: docs
title: Cocoa+Promise
redirect_from:
 - "/api/"
 - "/pods/"
---

# Cocoa+Promise

We provide wrappers for almost all the asynchronous functionality provided by Apple. For example:

```swift
CLLocationManager.promise().then { location in
    // pod "PromiseKit/CoreLocation"
}

MKDirections(/*…*/).calculate().then { directionsResponse in
    // pod "PromiseKit/MapKit"
}

URLSession.shared.POST(url, formData: params).asDictionary().then { json in
    // pod "PromiseKit/OMGHTTPURLRQ"
}

Alamofire.request(url, withMethod: .GET).responseJSON().then { json in
    // pod "PromiseKit/Alamofire"
}

CKContainer.publicCloudDatabase.fetchUserRecord().then { user in
    // pod "PromiseKit/CloudKit"
}

promiseViewController(UIImagePickerController()).then { image in
    // pod "PromiseKit/UIKit"
    // --> included in the default "PromiseKit" pod
}

NSNotificationCenter.default.observe(once: notificationName).then { obj in
    // pod "PromiseKit/Foundation"
    // --> included in the default "PromiseKit" pod
}
```

Above is just a small sampling; [view our full extensions listing on GitHub](https://github.com/PromiseKit).

---

For convenience, we also provide:

* [A promise that resolves when there is a valid Internet connection](https://github.com/PromiseKit/SystemConfiguration/blob/master/Sources/SCNetworkReachability%2BAnyPromise.h).
* [A promise that resolves when an object deallocates](https://github.com/PromiseKit/Foundation/blob/master/Sources/afterlife.swift).

In addition, PromiseKit is designed so that promises can be provided by other third-party libraries: [CocoaPods that use PromiseKit](https://cocoapods.org/?q=uses%3Apromisekit*).
