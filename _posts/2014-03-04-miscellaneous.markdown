---
category: home
layout: default
---

# Miscellaneous

## Guides/Blogs

* [Promises Pay](http://blog.popularpays.com/tech/2014/4/28/popular-promises)
* [PromiseKit + AFNetworking](http://oramind.com/promisekit-afnetworking/)

## Alternatives to PromiseKit

There are other Promise implementations for iOS, but in this author’s opinion, none of them are as pleasant to use as PromiseKit.

* [Bolts](https://github.com/BoltsFramework/Bolts-iOS) was the inspiration for PromiseKit. I thought that—finally—someone had written a decent Promises implementation for iOS. The lack of dedicated `catch` handler, the (objectively) ugly syntax and the overly complex design was a disappointment. To be fair Bolts is not a Promise implementation, it’s…something else. You may like it, and certainly it is backed by big names™. Fundamentally, Promise-type implementations are not hard to write, so really you’re making a decision based on how flexible the API is while simulatenously producing readable, clean code. I have worked hard to make PromiseKit the best choice. Also PromiseKit is ***much* leaner** than Bolts.
* [RXPromise](https://github.com/couchdeveloper/RXPromise) is an excellent Promise implementation that is not quite perfect (IMHO). By default thens are executed in background threads, which usually is inconvenient. `then` always return `id` and always take `id`, which makes code less elegant. There is no explicit `catch`, instead `then` always takes two blocks, the second being the error handler, which is ugly. The interface for `Promise` allows any caller to resolve it breaking encapsulation. Otherwise an excellent implementation.
* [CollapsingFutures](https://github.com/Strilanc/ObjC-CollapsingFutures) looks good, but is not thoroughly documented so a thorough review would require further experimentation.
* [Some others](http://cocoapods.org/?q=promise).

PromiseKit is well tested, and inside apps on the store. It also is fully documented, even within Xcode (⌥ click any method).
