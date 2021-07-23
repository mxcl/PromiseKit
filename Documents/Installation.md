# Installing PromiseKit

We support [SwiftPM]:

```swift
package.dependencies.append(
    .package(url: "https://github.com/mxcl/PromiseKit", from: "7.0.0-rc1")
)

package.targets.append(
    .target(name: "…", dependencies: [
        .product(name: "PromiseKit", package: "PromiseKit"),
        .product(name: "PMKFoundation", package: "PromiseKit"),
        .product(name: "PMKMapKit", package: "PromiseKit"),
    ])
)
```

And CocoaPods:

> Please note, we have not released this CocoaPod yet. You *can* still use it
> but you will need to specify the podspec URL manually, see the Cocoapods docs.

```ruby
pod "PromiseKit", "~> 7.0.0-rc1"
pod "PromiseKit/Foundation", "~> 7.0.0-rc1"
pod "PromiseKit/MapKit", "~> 7.0.0-rc1"
```

Considering 7.0 is still a release candidate, you may prefer to use [v6](https://github.com/mxcl/PromiseKit/blob/v6/README.md).

## Carthage

We will support [Carthage] if you can PR an automated solution for generating
the `.xcodeproj` on release. It will need to support all our extensions.


[SwiftPM]: https://swift.org/package-manager
[CocoaPods]: https://cocoapods.org
[Carthage]: https://github.com/Carthage/Carthage
