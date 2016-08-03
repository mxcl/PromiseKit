import PackageDescription

let package = Package(
    name: "PromiseKit",
    exclude: [
        "Sources/AnyPromise.swift",
        "Sources/Promise+AnyPromise.swift",
        "Sources/AnyPromise.m",
        "Sources/dispatch_promise.m",
        "Sources/GlobalState.m",
        "Sources/hang.m",
        "Sources/NSMethodSignatureForBlock.m",
        "Sources/join.m",
        "Sources/PMKCallVariadicBlock.m",
        "Sources/when.m",
        "Sources/after.m",
        "Sources/AnyPromise+Private.h",
        "Sources/AnyPromise.h",
        "Sources/PromiseKit.h",
        "Tests"
    ]
)
