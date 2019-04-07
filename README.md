![PromiseKit](../gh-pages/public/img/logo-tight.png)

[![badge-pod][]][cocoapods] ![badge-languages][] ![badge-pms][] ![badge-platforms][] [![badge-travis][]][travis]

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

We are testing PromiseKit 7 alpha, it is Swift 5 only. It is tagged and thus
importable in all package managers.

# PromiseKit 6

[Release notes and migration guide][PMK6].

# Quick Start

In your [Podfile]:

```ruby
use_frameworks!

target "Change Me!" do
  pod "PromiseKit", "~> 6.8"
end
```

> The above gives an Xcode warning? See our [Installation Guide].

PromiseKit 6, 5 and 4 support Xcode 8.3, 9.x and 10.0; Swift 3.1,
3.2, 3.3, 3.4, 4.0, 4.1, 4.2, 4.3 and 5.0 (development snapshots); iOS, macOS,
tvOS, watchOS, Linux and Android; CocoaPods, Carthage and SwiftPM;
([CI Matrix](https://travis-ci.org/mxcl/PromiseKit)).

For Carthage, SwiftPM, Accio, etc., or for instructions when using older Swifts or Xcodes, see our [Installation Guide]. We recommend
[Carthage](https://github.com/Carthage/Carthage) or
[Accio](https://github.com/JamitLabs/Accio).

# Professionally Supported PromiseKit is Now Available

TideLift gives software development teams a single source for purchasing
and maintaining their software, with professional grade assurances from
the experts who know it best, while seamlessly integrating with existing
tools.

[Get Professional Support for PromiseKit with TideLift](https://tidelift.com/subscription/pkg/cocoapods-promisekit?utm_source=cocoapods-promisekit&utm_medium=referral&utm_campaign=readme).

# PromiseKit is Thousands of Hours of Work

Hey there, I’m Max Howell. I’m a prolific producer of open source software and
probably you already use some of it (I created [`brew`]). I work full-time on
open source and it’s hard; currently *I earn less than minimum wage*. Please
help me continue my work, I appreciate it 🙏🏻

<a href="https://www.patreon.com/mxcl">
	<img src="https://c5.patreon.com/external/logo/become_a_patron_button@2x.png" width="160">
</a>

[Other ways to say thanks](http://mxcl.dev/#donate).

[`brew`]: https://brew.sh

# Documentation

* Handbook
  * [Getting Started](Documentation/GettingStarted.md)
  * [Promises: Common Patterns](Documentation/CommonPatterns.md)
  * [Frequently Asked Questions](Documentation/FAQ.md)
* Manual
  * [Installation Guide](Documentation/Installation.md)
  * [Objective-C Guide](Documentation/ObjectiveC.md)
  * [Troubleshooting](Documentation/Troubleshooting.md) (e.g., solutions to common compile errors)
  * [Appendix](Documentation/Appendix.md)
* [API Reference](https://mxcl.dev/PromiseKit/reference/v6/Classes/Promise.html)

# Extensions

Promises are only as useful as the asynchronous tasks they represent. Thus, we
have converted (almost) all of Apple’s APIs to promises. The default CocoaPod
provides Promises and the extensions for Foundation and UIKit. The other
extensions are available by specifying additional subspecs in your `Podfile`,
e.g.:

```ruby
pod "PromiseKit/MapKit"          # MKDirections().calculate().then { /*…*/ }
pod "PromiseKit/CoreLocation"    # CLLocationManager.requestLocation().then { /*…*/ }
```

All our extensions are separate repositories at the [PromiseKit organization].

## I don't want the extensions!

Then don’t have them:

```ruby
pod "PromiseKit/CorePromise", "~> 6.8"
```

> *Note:* Carthage installations come with no extensions by default.

## Choose Your Networking Library

Promise chains commonly start with a network operation. Thus, we offer
extensions for `URLSession`:

```swift
// pod 'PromiseKit/Foundation'  # https://github.com/PromiseKit/Foundation

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
// pod 'PromiseKit/Alamofire'  # https://github.com/PromiseKit/Alamofire-

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

Please check our [Troubleshooting Guide](Documentation/Troubleshooting.md), and
if after that you still have a question, ask at our [Gitter chat channel] or on [our bug tracker].


[badge-pod]: https://img.shields.io/cocoapods/v/PromiseKit.svg?label=version
[badge-pms]: https://img.shields.io/badge/supports-CocoaPods%20%7C%20Carthage%20%7C%20Accio%20%7C%20SwiftPM-green.svg
[badge-languages]: https://img.shields.io/badge/languages-Swift%20%7C%20ObjC-orange.svg
[badge-platforms]: https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg
[badge-mit]: https://img.shields.io/badge/license-MIT-blue.svg
[OMGHTTPURLRQ]: https://github.com/PromiseKit/OMGHTTPURLRQ
[Alamofire]: http://github.com/PromiseKit/Alamofire-
[PromiseKit organization]: https://github.com/PromiseKit
[Gitter chat channel]: https://gitter.im/mxcl/PromiseKit
[our bug tracker]: https://github.com/mxcl/PromiseKit/issues/new
[Podfile]: https://guides.cocoapods.org/syntax/podfile.html
[PMK6]: http://mxcl.dev/PromiseKit/news/2018/02/PromiseKit-6.0-Released/
[Installation Guide]: Documentation/Installation.md
[badge-travis]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=master
[travis]: https://travis-ci.org/mxcl/PromiseKit
[cocoapods]: https://cocoapods.org/pods/PromiseKit
