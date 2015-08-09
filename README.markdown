![PromiseKit](http://methylblue.com/junk/PMKBanner.png)

Modern development is highly asynchronous: isn’t it about time we had tools that made programming asynchronously powerful, easy and delightful?

```swift
UIApplication.sharedApplication().networkActivityIndicatorVisible = true

when(fetchImage(), getLocation()).then { image, location in
    self.imageView.image = image;
    self.label.text = "Buy your cat a house in \(location)"
}.finally {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
}.catch { error in
    UIAlertView(…).show()
}
```

PromiseKit is a thoughtful and complete implementation of promises for iOS and OS X with first-class support for **both** Objective-C *and* Swift.

[![Join the chat at https://gitter.im/mxcl/PromiseKit](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/mxcl/PromiseKit?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) ![](https://img.shields.io/cocoapods/v/PromiseKit.svg?label=Current%20Release)  [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)


# Swift 2

The `swift-2.0-beta` branch has a working Swift 2 implementation. Please be aware that both `catch` and `defer` are Swift 2 keywords so we have had to rename these functions and our new choices are not yet final.


# PromiseKit 2

PromiseKit 2 contains many interesting and important additions. Check out our our [release announcement](http://promisekit.org/PromiseKit-2.0-Released/) for full details.


# How To Get Started

* Check out the complete, comprehensive [PromiseKit documentation](http://promisekit.org).
* Read the [API documentation](http://cocoadocs.org/docsets/PromiseKit/), (note the documentation is not 100% currently as CocoaDocs is not good with Swift, you may have better luck reading the comments in the sources).
* [Integrate](http://promisekit.org/getting-started) promises into your existing projects.

## Quick Start Guide

### CocoaPods

```ruby
use_frameworks!

pod "PromiseKit", "~> 2.0"
```

### Carthage
```ruby
github "mxcl/PromiseKit" ~> 2.0
```

### Standalone Distributions

* [iOS 8 & OS X 10.9  Frameworks](https://github.com/mxcl/PromiseKit/releases/download/2.2.1/PromiseKit-2.2.1.zip) (Binaries)

*Please note*, the preferred way to integrate PromiseKit is CocoaPods or Carthage.

###  iOS 7 And Below

Neither CocoaPods or Carthage will install PromiseKit 2 for an iOS 7 target. Your options are:

 1. `pod "PromiseKit", "~> 1.5"` †‡
 2. Use our [iOS 7 EZ-Bake](https://github.com/PromiseKit/EZiOS7)
 3. Download our pre-built static framework (coming soon!)

† There is no Swift support with PromiseKit 1.x installed via CocoaPods.<br>‡ PromiseKit 1.x will work as far back as iOS 5 if required.


# Donations

PromiseKit is hundreds of hours of work almost completely by just me: [Max Howell](https://twitter.com/mxcl). I thoroughly enjoyed making PromiseKit, but nevertheless if you have found it useful then your bitcoin will give me a warm fuzzy feeling from my head right down to my toes: 1JDbV5zuym3jFw4kBCc5Z758maUD8e4dKR.


# License

Copyright 2015, Max Howell; <mxcl@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
