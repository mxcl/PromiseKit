# Xcode 8.3, 9.x or 10.x / Swift 3 or 4

We recommend Carthage over CocoaPods, but both installation methods are supported.

## CocoaPods

```ruby
use_frameworks!

target "Change Me!" do
  pod "PromiseKit", "~> 6.8"
end
```

If the generated Xcode project gives you a warning that PromiseKit needs to be upgraded to
Swift 4.0 or Swift 4.2, then add the following:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'PromiseKit'
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.2'
      end
    end
  end
end
```

Adjust the value for `SWIFT_VERSION` as needed.

CocoaPods are aware of this [issue](https://github.com/CocoaPods/CocoaPods/issues/7134).

## Carthage

```ruby
github "mxcl/PromiseKit" ~> 6.8
```

> Please note, since PromiseKit 6.8.1 our Carthage support has transitioned to
Swift 4 and above only. Strictly we *do* still support Swift 3.1 for Carthage,
and if you like you could edit the PromiseKit `project.pbxproj` file during
`carthage bootstrap` to make this possible. This change was involuntary and due
to Xcode 10.2 dropping support for Swift 3.

## Accio

Add the following to your Package.swift:

```swift
.package(url: "https://github.com/mxcl/PromiseKit.git", .upToNextMajor(from: "6.8.4")),
```

Next, add `PromiseKit` to your App targets dependencies like so:

```swift
.target(
    name: "App",
    dependencies: [
        "PromiseKit",
    ]
),
```

Then run `accio update`.

## SwiftPM

```swift
package.dependencies.append(
    .package(url: "https://github.com/mxcl/PromiseKit", from: "6.8.0")
)
```

## Manually

You can just drop `PromiseKit.xcodeproj` into your project and then add
`PromiseKit.framework` to your app’s embedded frameworks.


# PromiseKit vs. Xcode

PromiseKit contains Swift, so there have been rev-lock issues with Xcode:

| PromiseKit | Swift                   | Xcode    |   CI Status  |   Release Notes   |
| ---------- | ----------------------- | -------- | ------------ | ----------------- |
|      6     | 3.1, 3.2, 3.3, 4.x, 5.x | 8.3, 9.x, 10.x | ![ci-master] | [2018/02][news-6] |
|      5     | 3.1, 3.2, 3.3, 4.x      | 8.3, 9.x, 10.1 | *Deprecated* |       *n/a*       |
|      4     | 3.0, 3.1, 3.2, 3.3, 4.x | 8.x, 9.x, 10.1 | ![ci-master] | [2016/09][news-4] |
|      3     | 2.x                     | 7.x, 8.0 | ![ci-swift2] | [2015/10][news-3] |
|      2     | 1.x                     | 7.x      | *Deprecated* | [2015/10][news-3] |
|      1†    | *N/A*                   | *        | ![ci-legacy] |         –         |
                                     
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

We do **not** usually backport fixes to these branches, but pull requests are welcome.


## Xcode 8 / Swift 2.3 or Xcode 7

```ruby
# CocoaPods
swift_version = "2.3"
pod "PromiseKit", "~> 3.5"

# Carthage
github "mxcl/PromiseKit" ~> 3.5
```


[travis]: https://travis-ci.org/mxcl/PromiseKit
[ci-master]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=master
[ci-legacy]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=legacy-1.x
[ci-swift2]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.x
[ci-23]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.3-minimal-changes
[ci-22]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.2-minimal-changes
[ci-20]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.0-minimal-changes
[news-2]: http://mxcl.dev/PromiseKit/news/2015/05/PromiseKit-2.0-Released/
[news-3]: https://github.com/mxcl/PromiseKit/blob/212f31f41864d1e3ec54f5dd529bd8e1e5697024/CHANGELOG.markdown#300-oct-1st-2015
[news-4]: http://mxcl.dev/PromiseKit/news/2016/09/PromiseKit-4.0-Released/
[news-6]: http://mxcl.dev/PromiseKit/news/2018/02/PromiseKit-6.0-Released/
[swift-2.3-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.3-minimal-changes
[swift-2.2-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.2-minimal-changes
[swift-2.0-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.0-minimal-changes


# Using Git Submodules for PromiseKit’s Extensions

> *Note*: This is a more advanced technique.

If you use CocoaPods and a few PromiseKit extensions, then importing PromiseKit
causes that module to import all the extension frameworks. Thus, if you have an
app and a few app extensions (e.g., iOS app, iOS watch extension, iOS Today
extension) then all your final products that use PromiseKit will have forced
dependencies on all the Apple frameworks that PromiseKit provides extensions
for.

This isn’t that bad, but every framework that loads entails overhead and 
lengthens startup time.

It’s both better and worse with Carthage. We build individual micro-frameworks
for each PromiseKit extension, so your final products link
against only the Apple frameworks that they actually need. However, Apple has
advised that apps link only against “about 12” frameworks for performance
reasons. So with Carthage, we are worse off on this metric.

The solution is to instead import only CorePromise:

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

Then when you `pod update`, ensure that you also update your submodules:

    pod update && git submodule update --recursive --remote



# Release History

## [6.0](https://github.com/mxcl/PromiseKit/releases/tag/6.0.0) Feb 13th, 2018

* [PromiseKit 6 announcement post][news-6].

## [4.0](https://github.com/mxcl/PromiseKit/releases/tag/4.0.0)

* [PromiseKit 4 announcement post][news-4].

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

[PromiseKit 2 announcement post](http://mxcl.dev/PromiseKit/news/2015/05/PromiseKit-2.0-Released/).

## [1.5](https://github.com/mxcl/PromiseKit/releases/tag/1.5.0)

Swift 1.2 support. Xcode 6.3 required.
