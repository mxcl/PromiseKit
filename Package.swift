// swift-tools-version:5.3

import PackageDescription

let pkg = Package(name: "PromiseKit")
pkg.platforms = [
    .macOS(.v10_12), //FIXME strictly 10.10 (only tests need 10.12)
    .iOS(.v10),      //FIXME strictly 8.0
    .tvOS(.v10),     //FIXME strictly 9.0
    .watchOS(.v2)
]
pkg.products = [
    .library(name: "PromiseKit", targets: ["PromiseKit"]),
]
pkg.swiftLanguageVersions = [
    .v5  // grab PromiseKit-6.x if you want Swift 3.1‒5.2
]
pkg.targets = [
    .target(name: "PromiseKit", path: "Sources"),
    .testTarget(name: "Core", dependencies: ["PromiseKit"], path: "Tests/Core"),
    .testTarget(name: "Cancel", dependencies: ["PromiseKit"], path: "Tests/Cancel"),
    .testTarget(name: "APlusSwift", dependencies: ["PromiseKit"], path: "Tests/A+/Swift"),
    .testTarget(name: "APlusJS", dependencies: ["PromiseKit"], path: "Tests/A+/JavaScript", exclude: [
        "index.js", "package-lock.json", "package.json", "README.md", "webpack.config.js"
    ]),
]
