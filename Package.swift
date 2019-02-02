// swift-tools-version:5.0

import PackageDescription

let pkg = Package(name: "PromiseKit")
pkg.platforms = [
    .macOS(.v10_12), .iOS(.v8), .tvOS(.v9), .watchOS(.v2)
    //FIXME ^^^^^^ strictly only our tests require 10.12, PMK itself will work with 10.10
]
pkg.products = [
    .library(name: "PromiseKit", targets: ["PromiseKit"]),
]
pkg.swiftLanguageVersions = [
    .v5  // grab PromiseKit-6.x if you want Swift 3.1‒4.2
]
pkg.targets = [
    .target(name: "PromiseKit", path: "Sources"),
    .testTarget(name: "A+.swift", dependencies: ["PromiseKit"], path: "Tests/A+/Swift"),
    .testTarget(name: "A+.js", dependencies: ["PromiseKit"], path: "Tests/A+/JavaScript"),
    .testTarget(name: "Core", dependencies: ["PromiseKit"], path: "Tests/Core"),
]
