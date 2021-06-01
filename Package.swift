// swift-tools-version:5.3

import PackageDescription

let pkg = Package(name: "PromiseKit")
pkg.platforms = [
    .macOS(.v10_12), //FIXME strictly 10.10 (only tests need 10.12)
    .iOS(.v10),      //FIXME strictly 8.0
    .tvOS(.v10),     //FIXME strictly 9.0
    .watchOS(.v3)
]
pkg.swiftLanguageVersions = [.v5]

#if !os(Linux)
pkg.dependencies = [
    .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0")
]
#endif

func dependencies(for name: String) -> [Target.Dependency] {
    switch name {
    case "PromiseKit":
        return []
    default:
        return [.target(name: "PromiseKit")]
    }
}

func has(tests name: String) -> Target? {
    switch name {
    case "PMKFoundation":
        var deps = [Target.Dependency.target(name: "PMKFoundation")]
      #if !os(Linux)
        deps.append(.product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"))
      #endif
        return .testTarget(name: "\(name)Tests", dependencies: deps, path: "Tests/\(name)")
    case "PMKHomeKit", "PMKMapKit", "PMKCoreLocation":
        return .testTarget(name: "\(name)Tests", dependencies: [.target(name: name)], path: "Tests/\(name)")
    default:
        return nil
    }
}

for name in ["PMKCloudKit", "PMKCoreLocation", "PMKFoundation", "PMKHealthKit", "PMKHomeKit", "PMKMapKit", "PMKPhotos", "PMKStoreKit", "PromiseKit"] {

  #if os(Linux)
    guard name == "PromiseKit" || name == "PMKFoundation" else { continue }
  #endif

    pkg.targets.append(.target(name: name, dependencies: dependencies(for: name)))
    pkg.products.append(.library(name: name, targets: [name]))

    if let testTarget = has(tests: name) {
        pkg.targets.append(testTarget)
    }
}

pkg.targets += [
    .testTarget(name: "Core", dependencies: ["PromiseKit"]),
    .testTarget(name: "Cancel", dependencies: ["PromiseKit"]),
    .testTarget(name: "APlusSwiftTests", dependencies: ["PromiseKit"], path: "Tests/A+/Swift"),
    .testTarget(name: "APlusJSTests", dependencies: ["PromiseKit"], path: "Tests/A+/JavaScript", exclude: [
        "index.js", "package-lock.json", "package.json", "README.md", "webpack.config.js"
    ]),
]
