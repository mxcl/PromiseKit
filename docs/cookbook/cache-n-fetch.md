---
layout: docs
redirect_from: "/cache-n-fetch/"
---

# Cache ’n’ Fetch

In the case where you have the persisted, cached value for some asynchronous object and you want to show the user that, but also fetch the fresh data and then show the user that:

```swift
func fetch() -> Promise<Data, Promise<Data>> {
    return Promise { fulfill, reject in
        let fresh = URLSession.GET(url)
        let cache = Data(contentsOfFile: cachePath)
        fulfill((cache, fetch))
    }
}

fetch().then { cachedData, freshData -> Promise<Data> in
    if let data = cachedData {
        update(data: data)
    }
    return freshData
}.then(execute: update)
```

The chain does not wait on any promises returned in tuples (or in Objective-C a `PMKManifold`).
