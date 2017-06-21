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

PromiseKit contains Swift, so there have been rev-lock issues Xcode:

| Swift | Xcode | PromiseKit |   CI Status  |   Release Notes   |
| ----- | ----- | ---------- | ------------ | ----------------- |
|   4   |   9   |      4     | Coming Soon  | Coming Soon       |
|   3   |   8   |      4     | ![ci-master] | [2016/09][news-4] |
|   2   |  7/8  |      3     | ![ci-swift2] | [2015/10][news-3] |
|   1   |   7   |      3     |       –      | [2015/10][news-3] |
| *N/A* |   *   |      1†    | ![ci-legacy] |         –         |

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


# Differences Between PromiseKit Versions

TODO


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



