![PromiseKit](../gh-pages/public/img/logo-tight.png)

![badge-languages][] ![badge-platforms][]

---

Promises simplify asynchronous programming, freeing you up to focus on the more
important things. They are easy to learn, easy to master and result in clearer,
more readable code. Your co-workers will thank you.

```swift
UIApplication.shared.isNetworkActivityIndicatorVisible = true

let fetchImage = URLSession.shared.dataTask(.promise, with: url).compactMap{ UIImage(data: $0.data) }
let fetchLocation = CLLocationManager.requestLocation().lastValue

firstly {
    when(fulfilled: fetchImage, fetchLocation)
}.done { image, location in
    self.imageView.image = image
    self.label.text = "\(location)"
}.ensure {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
}.catch { error in
    self.show(UIAlertController(for: error), sender: self)
}
```

PromiseKit is a thoughtful and complete implementation of promises for any
platform that has a `swiftc`. It has *excellent* Objective-C bridging and
*delightful* specializations for iOS, macOS, tvOS and watchOS. It is a top-100
pod used in many of the most popular apps in the world.

[![codecov](https://codecov.io/gh/mxcl/PromiseKit/branch/master/graph/badge.svg)](https://codecov.io/gh/mxcl/PromiseKit)

# PromiseKit 7 Alpha

PromiseKit 7 is prerelease, if you’re using it: beware!

PromiseKit 7 uses Swift 5’s `Result`, PromiseKit <7 use our own `Result` type.

PromiseKit 7 generalizes `DispatchQueue`s to a `Dispatcher` protocol. However,
`DispatchQueue`s are `Dispatcher`-conformant, so existing code should not need
to change. Please report any issues related to this transition.

PromiseKit 7 adds support for cancelling promises and promise chains.

# PromiseKit 6

[Release notes and migration guide][PMK6].

# Quick Start

In your `Package.swift`:

```swift
package.dependencies.append(
    .package(url: "https://github.com/mxcl/PromiseKit", from: Version(7, 0, 0, prereleaseIdentifiers: [“alpha”, “1”]))
)
```

PromiseKit 7 supports Swift >= 5.3; Xcode >= 12; iOS, macOS, tvOS, watchOS, Linux
and Android; SwiftPM.

PromiseKits 6 and 4 support Xcode 8.3, 9.x and 10.0; Swift 3.1, 3.2, 3.3, 3.4,
4.0, 4.1, 4.2 and 5.0; iOS, macOS, tvOS, watchOS, Linux and Android; CocoaPods,
Carthage and SwiftPM; ([CI Matrix](https://travis-ci.org/mxcl/PromiseKit)).

For Carthage, SwiftPM, Accio, etc., or for instructions when using older Swifts
or Xcodes, see our [Installation Guide].

# Professionally Supported PromiseKit is Now Available

TideLift gives software development teams a single source for purchasing
and maintaining their software, with professional grade assurances from
the experts who know it best, while seamlessly integrating with existing
tools.

[Get Professional Support for PromiseKit with TideLift](https://tidelift.com/subscription/pkg/cocoapods-promisekit?utm_source=cocoapods-promisekit&utm_medium=referral&utm_campaign=readme).

## Other Sponsorship

Maintaining this project is work, if your company uses this project please
sponsor it either via Tidelift or GitHub Sponsors.

# Documentation

* Handbook
  * [Getting Started](Documents/GettingStarted.md)
  * [Promises: Common Patterns](Documents/CommonPatterns.md)
  * [Cancelling Promises](Documents/Cancel.md)
  * [Frequently Asked Questions](Documents/FAQ.md)
* Manual
  * [Installation Guide](Documents/Installation.md)
  * [Objective-C Guide](Documents/ObjectiveC.md)
  * [Troubleshooting](Documents/Troubleshooting.md) (e.g., solutions to common compile errors)
  * [Appendix](Documents/Appendix.md)
* [API Reference](https://mxcl.dev/PromiseKit/reference/v7/Classes/Promise.html)

# Extensions

Promises are only as useful as the asynchronous tasks they represent. Thus, we
have converted (almost) all of Apple’s APIs to promises. The default CocoaPod
provides Promises and the extensions for Foundation and UIKit. The other
extensions are available by specifying additional subspecs in your `Podfile`,
e.g.:

```ruby
pod "PMKMapKit"          # MKDirections().calculate().then { /*…*/ }
pod "PMKCoreLocation"    # CLLocationManager.requestLocation().then { /*…*/ }
```

All our extensions are separate repositories at the [PromiseKit organization].

## Choose Your Networking Library

Promise chains commonly start with a network operation. Thus, we offer
extensions for `URLSession`:

```swift
// pod 'PMKFoundation'  # https://github.com/PromiseKit/PMKFoundation

firstly {
    URLSession.shared.dataTask(.promise, with: try makeUrlRequest()).validate()
    // ^^ we provide `.validate()` so that eg. 404s get converted to errors
}.map {
    try JSONDecoder().decode(Foo.self, with: $0.data)
}.done { foo in
    //…
}.catch { error in
    //…
}

func makeUrlRequest() throws -> URLRequest {
    var rq = URLRequest(url: url)
    rq.httpMethod = "POST"
    rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
    rq.addValue("application/json", forHTTPHeaderField: "Accept")
    rq.httpBody = try JSONEncoder().encode(obj)
    return rq
}
```

And [Alamofire]:

```swift
// pod 'PMKAlamofire'  # https://github.com/PromiseKit/PMKAlamofire

firstly {
    Alamofire
        .request("http://example.com", method: .post, parameters: params)
        .responseDecodable(Foo.self)
}.done { foo in
    //…
}.catch { error in
    //…
}
```

Nowadays, considering that:

* We almost always POST JSON
* We now have `JSONDecoder`
* PromiseKit now has `map` and other functional primitives
* PromiseKit (like Alamofire, but not raw-`URLSession`) also defaults to having
    callbacks go to the main thread

We recommend vanilla `URLSession`. It uses fewer black boxes and sticks closer to the metal. Alamofire was essential until the three bullet points above
became true, but nowadays it isn’t really necessary.

# Support

Please check our [Troubleshooting Guide](Documents/Troubleshooting.md), and
if after that you still have a question, ask at our [Gitter chat channel] or on [our bug tracker].

## Security & Vulnerability Reporting or Disclosure

https://tidelift.com/security


[badge-pod]: https://img.shields.io/cocoapods/v/PromiseKit.svg?label=version
[badge-pms]: https://img.shields.io/badge/supports-CocoaPods%20%7C%20Carthage%20%7C%20Accio%20%7C%20SwiftPM-green.svg
[badge-languages]: https://img.shields.io/badge/languages-Swift-orange.svg
[badge-platforms]: https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg
[badge-mit]: https://img.shields.io/badge/license-MIT-blue.svg
[OMGHTTPURLRQ]: https://github.com/PromiseKit/OMGHTTPURLRQ
[Alamofire]: http://github.com/PromiseKit/Alamofire-
[PromiseKit organization]: https://github.com/PromiseKit
[Gitter chat channel]: https://gitter.im/mxcl/PromiseKit
[our bug tracker]: https://github.com/mxcl/PromiseKit/issues/new
[Podfile]: https://guides.cocoapods.org/syntax/podfile.html
[PMK6]: http://mxcl.dev/PromiseKit/news/2018/02/PromiseKit-6.0-Released/
[Installation Guide]: Documents/Installation.md
[badge-travis]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=master
[travis]: https://travis-ci.org/mxcl/PromiseKit
[cocoapods]: https://cocoapods.org/pods/PromiseKit
