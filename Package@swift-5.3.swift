// swift-tools-version:5.3

import PackageDescription

let pkg = Package(name: "PromiseKit")
pkg.platforms = [
   .macOS(.v10_10), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)
]
pkg.products = [
	.library(name: "PromiseKit", targets: ["PromiseKit", "PromiseKitObjC"])
]

let pmk: Target = .target(name: "PromiseKit")
pmk.path = "Sources"
pmk.exclude = [
	"AnyPromise.m",
	"PMKCallVariadicBlock.m",
	"dispatch_promise.m",
	"join.m",
	"when.m",
	"NSMethodSignatureForBlock.m",
	"after.m",
	"hang.m",
	"race.m",
	"Deprecations.swift",
    "Info.plist"
]

let pmkObjc: Target = .target(name: "PromiseKitObjC")
pmkObjc.dependencies = ["PromiseKit"]
pmkObjc.path = "Sources"
pmkObjc.publicHeadersPath = "."
pmkObjc.exclude = [
	"PMKCallVariadicBlock.m",
	"after.swift",
	"AnyPromise.swift",
	"Box.swift",
	"Catchable.swift",
	"Configuration.swift",
	"CustomStringConvertible.swift",
	"Deprecations.swift",
	"Error.swift",
	"firstly.swift",
	"Guarantee.swift",
	"hang.swift",
	"Info.plist",
	"LogEvent.swift",
	"Promise.swift",
	"race.swift",
	"Resolver.swift",
	"Thenable.swift",
	"when.swift"
]

pkg.swiftLanguageVersions = [.v4, .v4_2, .v5]
pkg.targets = [
    pmk,
	pmkObjc,
    .testTarget(name: "APlus", dependencies: ["PromiseKit"], path: "Tests/A+", exclude: ["README.md"]),
    .testTarget(name: "CorePromise", dependencies: ["PromiseKit"], path: "Tests/CorePromise"),
]
