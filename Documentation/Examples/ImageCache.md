# Image Cache with Promises

Here is an example of a simple image cache that uses promises to simplify the
state machine:

```swift
import Foundation
import PromiseKit

/**
 * Small (10 images)
 * Thread-safe
 * Consolidates multiple requests to the same URLs
 * Removes stale entries (FIXME well, strictly we may delete while fetching from cache, but this is unlikely and non-fatal)
 * Completely _ignores_ server caching headers!
 */

private let q = DispatchQueue(label: "org.promisekit.cache.image")
private var active: [URL: Promise<Data>] = [:]
private var cleanup = Promise()


public func fetch(image url: URL) -> Promise<Data> {
    var promise: Promise<Data>?
    q.sync {
        promise = active[url]
    }
    if let promise = promise {
        return promise
    }

    q.sync(flags: .barrier) {
        promise = Promise(.start) {

            let dst = try url.cacheDestination()

            guard !FileManager.default.isReadableFile(atPath: dst.path) else {
                return Promise(dst)
            }

            return Promise { seal in
                URLSession.shared.downloadTask(with: url) { tmpurl, _, error in
                    do {
                        guard let tmpurl = tmpurl else { throw error ?? E.unexpectedError }
                        try FileManager.default.moveItem(at: tmpurl, to: dst)
                        seal.fulfill(dst)
                    } catch {
                        seal.reject(error)
                    }
                }.resume()
            }

        }.then(on: .global(QoS: .userInitiated)) {
            try Data(contentsOf: $0)
        }

        active[url] = promise

        if cleanup.isFulfilled {
            cleanup = promise!.asVoid().then(on: .global(QoS: .utility), execute: docleanup)
        }
    }

    return promise!
}

public func cached(image url: URL) -> Data? {
    guard let dst = try? url.cacheDestination() else {
        return nil
    }
    return try? Data(contentsOf: dst)
}


public func cache(destination remoteUrl: URL) throws -> URL {
    return try remoteUrl.cacheDestination()
}

private func cache() throws -> URL {
    guard let dst = FileManager.default.docs?
        .appendingPathComponent("Library")
        .appendingPathComponent("Caches")
        .appendingPathComponent("cache.img")
    else {
        throw E.unexpectedError
    }

    try FileManager.default.createDirectory(at: dst, withIntermediateDirectories: true, attributes: [:])

    return dst
}

private extension URL {
    func cacheDestination() throws -> URL {

        var fn = String(hashValue)
        let ext = pathExtension

        // many of Apple's functions don’t recognize file type
        // unless we preserve the file extension
        if !ext.isEmpty {
            fn += ".\(ext)"
        }

        return try cache().appendingPathComponent(fn)
    }
}

enum E: Error {
    case unexpectedError
    case noCreationTime
}

private func docleanup() throws {
    var contents = try FileManager.default
        .contentsOfDirectory(at: try cache(), includingPropertiesForKeys: [.creationDateKey])
        .map { url -> (Date, URL) in
            guard let date = try url.resourceValues(forKeys: [.creationDateKey]).creationDate else {
                throw E.noCreationTime
            }
            return (date, url)
        }.sorted(by: {
            $0.0 > $1.0
        })

    while contents.count > 10 {
        let rm = contents.popLast()!.1
        try FileManager.default.removeItem(at: rm)
    }
}
````