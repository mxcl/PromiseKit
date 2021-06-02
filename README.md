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
platform that has a `swiftc`. It has
*delightful* specializations for iOS, macOS, tvOS and watchOS. It is a top-100
pod used in many of the most popular apps in the world.

[![codecov](https://codecov.io/gh/mxcl/PromiseKit/branch/master/graph/badge.svg)](https://codecov.io/gh/mxcl/PromiseKit)

# Requirements

Xcode >= 12.0 or Swift >= 5.3.

For earlier Swifts, Xcodes or for Objective-C support, use [PromiseKit 6](https://github.com/mxcl/PromiseKit/blob/v6/README.md).

# Quick Start

In your `Package.swift`:

```swift
package.dependencies.append(
    .package(url: "https://github.com/mxcl/PromiseKit", from: "7.0.0-rc1")
)
```

For more detailed installation instructions or for other package managers see our
[Installation Guide].

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
  * [Troubleshooting](Documents/Troubleshooting.md) (e.g., solutions to common compile errors)
  * [Appendix](Documents/Appendix.md)
* [API Reference](https://mxcl.dev/PromiseKit/reference/v7/Classes/Promise.html)

# Extensions

Promises are only as useful as the asynchronous tasks they represent. Thus, we
have converted (almost) all of Apple’s APIs to promises. You can use the
extensions by adding the appropriate library to your `Package.swift` and then
importing it (eg. `import PMKFoundation`).

See our [Installation Guide](Documents/Installation.md) for usage details.

Browse the `Sources` folder here for a list of available extensions.

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
