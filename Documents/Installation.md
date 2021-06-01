We support SwiftPM:

```swift
package.dependencies.append(
    .package(url: "https://github.com/mxcl/PromiseKit", from: "7.0.0-alpha.1")
)

package.targets.append(
    .target(name: "MyTarget", dependencies: ["PromiseKit", "PMKFoundation"])
)
```

Or CocoaPods:

```ruby
pod "PromiseKit", "~> 6.8"
pod "PromiseKit/Foundation", "~> 6.8"
```

## Carthage

We will support Carthage if you can PR an automated solution for generating the `.xcodeproj` on release.
It will need to support all our extensions.
