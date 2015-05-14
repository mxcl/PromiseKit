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

[![Join the chat at https://gitter.im/mxcl/PromiseKit](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/mxcl/PromiseKit?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


# How To Get Started

* Check out the [complete, comprehensive PromiseKit documentation](http://promisekit.org).
* Read the [API documentation](http://cocoadocs.org/docsets/PromiseKit/).
* [Integrate](http://promisekit.org/getting-setup) promises into your existing projects.

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

### Standalone Downloads

*Coming soon!*

*Please Note* If you want a standalone download because you don’t want to learn CocoaPods or Carthage then may we ask you to reconsider? If you choose to use third-party libraries you should also choose to install bug fix releases, some of the fixes can be very important! Using a dependency manager takes the headache out of staying up-to-date.

###  iOS 7 And Below

Neither CocoaPods or Carthage will install iOS frameworks for deployment targets below iOS 8. PromiseKit 2 is a iOS framework. Thus if you need to support iOS 7 (or below, we support back to iOS 5):

 1. `pod "PromiseKit", "~> 1.5"`
 2. Manually compile all the PromiseKit sources into your app target.
 3. Download our pre-built static framework (coming soon!)

Note option 1 gives you no Swift support. Swift can only be compiled directly into the main application target or compiled into iOS 8 dynamic frameworks. Thus if you need Swift and you need iOS 7 you must compile the sources by hand (and if you’re doing that, pick PromiseKit 2, it’s better).


# Donations

PromiseKit is hundreds of hours of work almost completely by just me: [Max Howell](https://twitter.com/mxcl). I thoroughly enjoyed making PromiseKit, but nevertheless if you have found it useful then your bitcoin will give me a warm fuzzy feeling from my head right down to my toes: 1JDbV5zuym3jFw4kBCc5Z758maUD8e4dKR.


# License

Copyright 2015 Max Howell <mxcl@me.com>

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
