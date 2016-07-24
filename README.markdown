![PromiseKit](http://promisekit.org/public/img/logo-tight.png)

![badge-pod] ![badge-languages] ![badge-pms] ![badge-platforms] ![badge-mit]

Modern development is highly asynchronous: isn’t it about time we had tools that
made programming asynchronously powerful, easy and delightful?

```swift
UIApplication.shared.networkActivityIndicatorVisible = true

firstly {
    when(URLSession.dataTask(with: url).asImage(), CLLocationManager.promise())
}.then { image, location -> Void in
    self.imageView.image = image;
    self.label.text = "\(location)"
}.always {
    UIApplication.shared.networkActivityIndicatorVisible = false
}.catch { error in
    UIAlertView(/*…*/).show()
}
```

PromiseKit is a thoughtful and complete implementation of promises for any
platform with a `swiftc`, it has *excellent* Objective-C bridging and
*delightful* specializations for iOS, macOS, tvOS and watchOS.

# Quick Start

```ruby
# CocoaPods
pod "PromiseKit", :git => 'https://github.com/mxcl/PromiseKit.git', :branch => 'swift-3.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end

# Carthage
github "mxcl/PromiseKit" ~> 4.0

# SwiftPM
let package = Package(
    dependencies: [
        .Package(url: "https://github.com/mxcl/PromiseKit", majorVersion: 4)
    ]
)
```

Alternatively, drop `PromiseKit.xcodeproj` into your project and add
`PromiseKit.framework` to your app’s embedded frameworks.

# Documentation

We have thorough and complete documentation at [promisekit.org].

## Overview

Promises are defined by the function `then`:

```swift
login().then { json in
    //…
}
```

They are chainable:

```swift
login().then { json -> Promise<UIImage> in
    return fetchAvatar(json["username"])
}.then { avatarImage in
    self.imageView.image = avatarImage
}
```

Errors cascade through chains:

```swift
login().then {
    return fetchAvatar()
}.then { avatarImage in
    //…
}.catch { error in
    UIAlertView(/*…*/).show()
}
```

They are composable:

```swift
let username = login().then{ $0["username"] }

when(username, CLLocationManager.promise()).then { user, location in
    return fetchAvatar(user, location: location)
}.then { image in
    //…
}
```

They are trivial to refactor:

```swift
func avatar() -> Promise<UIImage> {
    let username = login().then{ $0["username"] }

    return when(username, CLLocationManager.promise()).then { user, location in
        return fetchAvatar(user, location: location)
    }
}
```

## Continue Learning…

Complete and progressive learning guide at [promisekit.org].

## PromiseKit vs. Xcode

PromiseKit contains Swift, so we engage in an unending battle with Xcode:

| Xcode | Swift | PromiseKit |   CI Status  |   Release Notes   |
| ----- | ----- | ---------- | ------------ | ----------------- |
|   8   |  3.0  |      4     | ![ci-swift3] | [Pending][news-4] |
|   8   |  2.3  |      3     | ![ci-master] | [2015/10][news-3] |
|   7   |  2.2  |      3     | ![ci-master] | [2015/10][news-3] |
|   6   |  1.2  |      2     |  –           | [2015/05][news-2] |
|   *   | *N/A* |      1†    | ![ci-legacy] |                   |

† PromiseKit 1 is pure Objective-C and thus can be used with any Xcode, it is
also your only choice if you need to support iOS 7 or below.

---

We also maintain some branches to aid migrating between Swift versions:

| Xcode | Swift | PromiseKit | Branch                      | CI Status |
| ----- | ----- | -----------| --------------------------- | --------- |
|  8.0  |  2.3  | 2          | [swift-2.3-minimal-changes] | ![ci-23]  |
|  7.3  |  2.2  | 2          | [swift-2.2-minimal-changes] | ![ci-22]  |
|  7.2  |  2.2  | 2          | [swift-2.2-minimal-changes] | ![ci-22]  |
|  7.1  |  2.1  | 2          | [swift-2.0-minimal-changes] | ![ci-20]  |
|  7.0  |  2.0  | 2          | [swift-2.0-minimal-changes] | ![ci-20]  |

We do **not** usually backport fixes to these branches, but pull-requests are welcome.

# Extensions

Promises are only as useful as the asynchronous tasks they represent, thus we 
have converted (almost) all of Apple’s APIs to Promises. The default CocoaPod
comes with promises UIKit and Foundation, the rest are accessed by specifying
additional subspecs in your `Podfile`, eg:

```ruby
pod "PromiseKit/MapKit"        # MKDirections().promise().then { /*…*/ }
pod "PromiseKit/CoreLocation"  # CLLocationManager.promise().then { /*…*/ }
```

All our extensions are separate repositories at the [PromiseKit org ](https://github.com/PromiseKit).

For Carthage specify the additional repositories in your `Cartfile`:

```ruby
github "PromiseKit/MapKit" ~> 1.0
```

## Choose Your Networking Library

`NSURLSession` is typically inadequate; choose from [Alamofire] or [OMGHTTPURLRQ]:

```swift
// pod 'PromiseKit/Alamofire'  
Alamofire.request("http://example.com", withMethod: .GET).responseJSON().then { json in
    //…
}.catch { error in
    //…
}

// pod 'PromiseKit/OMGHTTPURLRQ'
URLSession.GET("http://example.com").asDictionary().then { json in
    
}.catch { error in
    //…
}
```

For [AFNetworking] we recommend [csotiriou/AFNetworking].

# Support

Ask your question on [Gitter chat](https://gitter.im/mxcl/PromiseKit) or
[our bug tracker](https://github.com/mxcl/PromiseKit/issues/new).


[travis]: https://travis-ci.org/mxcl/PromiseKit
[ci-master]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=master
[ci-legacy]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=legacy-1.x
[ci-swift3]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-3.0
[ci-23]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.3-minimal-changes
[ci-22]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.2-minimal-changes
[ci-20]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.0-minimal-changes
[news-2]: http://promisekit.org/news/2015/05/PromiseKit-2.0-Released/
[news-3]: https://github.com/mxcl/PromiseKit/blob/master/CHANGELOG.markdown#300-oct-1st-2015
[news-4]: http://promisekit.org/news/
[swift-2.3-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.3-minimal-changes
[swift-2.2-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.2-minimal-changes
[swift-2.0-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.0-minimal-changes
[promisekit.org]: http://promisekit.org/docs/
[badge-pod]: https://img.shields.io/cocoapods/v/PromiseKit.svg?label=version
[badge-platforms]: https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg
[badge-languages]: https://img.shields.io/badge/languages-Swift%20%7C%20ObjC-orange.svg
[badge-mit]: https://img.shields.io/badge/license-MIT-blue.svg
[badge-pms]: https://img.shields.io/badge/supports-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM-green.svg
[OMGHTTPURLRQ]: https://github.com/mxcl/OMGHTTPURLRQ
[Alamofire]: http://alamofire.org
[AFNetworking]: https://github.com/AFNetworking/AFNetworking
[csotiriou/AFNetworking]: https://github.com/csotiriou/AFNetworking-PromiseKit
