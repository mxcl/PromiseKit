# Xcode 8 / Swift 3

We recommend CocoaPods.

## CocoaPods

```ruby
use_frameworks!
swift_version = "3.0"
pod "PromiseKit", "~> 4.0"
```

Since CocoaPods 1.0 you will probably need to add the `pod` line to a `target`,
eg:

```ruby
use_frameworks!
swift_version = "3.0"

target "MyTarget" do
  pod "PromiseKit", "~> 4.0"
end
```

## Carthage

```ruby
github "mxcl/PromiseKit" ~> 4.0
```

## SwiftPM

```ruby
package.dependencies.append(
    .Package(url: "https://github.com/mxcl/PromiseKit", majorVersion: 4)
)
```

## Manually

You can just drop `PromiseKit.xcodeproj` into your project and then add
`PromiseKit.framework` to your app’s embedded frameworks.


# PromiseKit vs. Xcode

PromiseKit contains Swift, so there have been rev-lock issues with Xcode:

| PromiseKit | Swift    | Xcode    |   CI Status  |   Release Notes   |
| ---------- | -------- | -------- | ------------ | ----------------- |
|      5     | 3.x, 4.0 | 8.x, 9.0 | ![ci-master] |      In beta      |
|      4     | 3.x, 4.0 | 8.x, 9.0 | ![ci-master] | [2016/09][news-4] |
|      3     | 2.x      | 7.x, 8.0 | ![ci-swift2] | [2015/10][news-3] |
|      2     | 1.x      | 7.x      | Unsupported  | [2015/10][news-3] |
|      1†    | *N/A*    | *        | ![ci-legacy] |         –         |
                                     

† PromiseKit 1 is pure Objective-C and thus can be used with any Xcode, it is
also your only choice if you need to support iOS 7 or below.

---

We also maintain a series of branches to aid migration for PromiseKit 2:

| Xcode | Swift | PromiseKit | Branch                      | CI Status |
| ----- | ----- | -----------| --------------------------- | --------- |
|  8.0  |  2.3  | 2          | [swift-2.3-minimal-changes] | ![ci-23]  |
|  7.3  |  2.2  | 2          | [swift-2.2-minimal-changes] | ![ci-22]  |
|  7.2  |  2.2  | 2          | [swift-2.2-minimal-changes] | ![ci-22]  |
|  7.1  |  2.1  | 2          | [swift-2.0-minimal-changes] | ![ci-20]  |
|  7.0  |  2.0  | 2          | [swift-2.0-minimal-changes] | ![ci-20]  |

We do **not** usually backport fixes to these branches, but pull-requests are welcome.


## Xcode 9 / Swift 4

```ruby
# CocoaPods
swift_version = "4.0"
pod "PromiseKit", branch: "swift4-beta1"

# Carthage
github "mxcl/PromiseKit" "swift4-beta1"

# SwiftPM
package.dependencies.append(
    .package(url: "https://github.com/mxcl/PromiseKit", .branch("swift4-beta1"))
)
```

### Please Note

We have not ported the extensions yet. This is your opportunity to contribute.

1. Clone:

       cd your-project/..
       git clone https://github.com/mxcl/PromiseKit PMK-swift4-beta1 --recursive -b swift4-beta1

2. Amend your `Podfile`:

       pod "PromiseKit", path: "../PMK-swift4-beta1"

3. Make your fixes for the PromiseKit extensions you use.
4. Fork, push & pull-request.

## Xcode 8 / Swift 3 *and* Xcode 9 / Swift 3.2

```ruby
# CocoaPods
swift_version = "3.0"
pod "PromiseKit", "~> 4.0"

# Carthage
github "mxcl/PromiseKit" ~> 4.0

# SwiftPM
let package = Package(
    dependencies: [
        .Package(url: "https://github.com/mxcl/PromiseKit", majorVersion: 4)
    ]
)
```

## Xcode 8 / Swift 2.3 or Xcode 7

```ruby
# CocoaPods
swift_version = "2.3"
pod "PromiseKit", "~> 3.5"

# Carthage
github "mxcl/PromiseKit" ~> 3.5
```


# PromiseKit 5

[PromiseKit 5 is experimental and under active development](https://github.com/mxcl/PromiseKit/tree/experimental-5.x).


[travis]: https://travis-ci.org/mxcl/PromiseKit
[ci-master]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=master
[ci-legacy]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=legacy-1.x
[ci-swift2]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.x
[ci-23]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.3-minimal-changes
[ci-22]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.2-minimal-changes
[ci-20]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.0-minimal-changes
[news-2]: http://promisekit.org/news/2015/05/PromiseKit-2.0-Released/
[news-3]: https://github.com/mxcl/PromiseKit/blob/master/CHANGELOG.markdown#300-oct-1st-2015
[news-4]: http://promisekit.org/news/2016/09/PromiseKit-4.0-Released/
[swift-2.3-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.3-minimal-changes
[swift-2.2-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.2-minimal-changes
[swift-2.0-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.0-minimal-changes


# Using Git Submodules for PromiseKit’s Extensions

> Please note, this is a more advanced technique

If you use CocoaPods and a few PromiseKit extensions then importing PromiseKit
causes that module to import all the extension frameworks. Thus if you have an
app and a few app-extensions (eg. iOS app, iOS watch extension, iOS Today
extension) then all your final products that use PromiseKit will have forced
dependencies on all the Apple frameworks that PromiseKit provides extensions
for.

This isn’t that bad, but every framework that loads is overhead and startup
time.

It’s better and worse with Carthage since we build individual micro-frameworks
for each PromiseKit-extension, so at least all your final products only link
against the Apple frameworks that they actually need. However, Apple have
advised that apps only link against “about 12” frameworks for performance
reasons, so for Carthage, we are worse off for this metric.

The solution is to instead only import CorePromise:

```ruby
# CocoaPods
pod "PromiseKit/CorePromise"

# Carthage
github "mxcl/PromiseKit"
# ^^ for Carthage *only* have this
```

And to use the extensions you need via `git submodules`:

```
git submodule init
git submodule add https://github.com/PromiseKit/UIKit Submodules/PMKUIKit
```

Then in Xcode you can add these sources to your targets on a per-target basis.

Then when you `pod update`, ensure you also update your submodules:

    pod update && git submodule update --recursive --remote



# Release History

## [4.0](https://github.com/mxcl/PromiseKit/releases/tag/4.0.0)

* [PromiseKit 4 announcement post](http://promisekit.org/news/2016/09/PromiseKit-4.0-Released/).

## [3.0](https://github.com/mxcl/PromiseKit/releases/tag/3.0.0) Oct 1st, 2015

In Swift 2.0 `catch` and `defer` became reserved keywords mandating we rename
our functions with these names. This forced a major semantic version change on
PromiseKit and thus we took the opportunity to make other minor (source
compatibility breaking) improvements.

Thus if you cannot afford to adapt to PromiseKit 3 but still want to use
Xcode-7.0/Swift-2.0 we provide a [minimal changes branch] where `catch` and
`defer` are renamed `catch_` and `defer_` and all other changes are the bare
minimum to make PromiseKit 2 compile against Swift 2.

If you still are using Xcode 6 and Swift 1.2 then use PromiseKit 2.

[minimal changes branch]: https://github.com/mxcl/PromiseKit/tree/swift-2.0-minimal-changes

## [2.0](https://github.com/mxcl/PromiseKit/releases/tag/2.0.0) May 14th, 2015

[PromiseKit 2 announcement post](http://promisekit.org/news/2015/05/PromiseKit-2.0-Released/).

## [1.5](https://github.com/mxcl/PromiseKit/releases/tag/1.5.0)

Swift 1.2 support. Xcode 6.3 required.
