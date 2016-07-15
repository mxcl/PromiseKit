---
layout: default
---

# Retry

We do not have a baked in `retry` function, however it is easy enough to emulate:

```swift
func attempt<T>(_ body: () -> Promise<T>) -> Promise<T>
    var attempts = 0
    func attempt() -> Promise<T> {
        attempts += 1
        return body().recover { error -> Promise in
            guard attempts < 3 else { throw error }
            return after(interval: 2).then(execute: attempt)
        }
    }
    return attempt()
}

attempt{ flakeyTask() }.then {
    //…
}
```
