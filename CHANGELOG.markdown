# [4.0.0](https://github.com/mxcl/PromiseKit/releases/tag/4.0.0)

* [PromiseKit 4 announcement post](http://promisekit.org/news/2016/09/PromiseKit-4.0-Released/).

# [3.4.3](https://github.com/mxcl/PromiseKit/releases/tag/3.4.3) Aug 7th, 2016

* Fix regression to UIViewController extension introduced in 3.4.0

# [3.2.1](https://github.com/mxcl/PromiseKit/releases/tag/3.2.1) Jul 10th, 2016

* Critical fix for archiving projects using our NSNotificationCenter Swift extension
* Additional fixes from the community

# [3.2.0](https://github.com/mxcl/PromiseKit/releases/tag/3.2.0) May 20th, 2016

* A new EventKit category
* Ability to change the global queue for promises
* Ability to define a custom queue for `error`
* Documentation and other various fixes

# [3.1.1](https://github.com/mxcl/PromiseKit/releases/tag/3.1.1) Apr 6th, 2016

* Temporary aliases to disambiguate `error` the property and function
* Fix for edge cases when dismissing a promised view controller
* Various minor fixes

# [3.1.0](https://github.com/mxcl/PromiseKit/releases/tag/3.1.0) Mar 26th, 2016

* Swift 2.2 support plus additional improvements from the community.

# [3.0.3](https://github.com/mxcl/PromiseKit/releases/tag/3.0.3) Feb 29th, 2016

* AnyPromise bridging to NSString and objc BOOL plus additional improvements from the community.

# [3.0.2](https://github.com/mxcl/PromiseKit/releases/tag/3.0.2) Jan 31st, 2016

* tvOS support

# [3.0.1](https://github.com/mxcl/PromiseKit/releases/tag/3.0.1) Jan 14th, 2016

* Minor fixes and improvements from the community.

# [3.0.0](https://github.com/mxcl/PromiseKit/releases/tag/3.0.0) Oct 1st, 2015

In Swift 2.0 `catch` and `defer` became reserved keywords mandating we rename our functions with these names. This forced a major semantic version change on PromiseKit and thus we took the opportunity to make other minor (source compatibility breaking) improvements.

Thus if you cannot afford to adapt to PromiseKit 3 but still want to use Xcode-7.0/Swift-2.0 we provide a [minimal changes branch] where `catch` and `defer` are renamed `catch_` and `defer_` and all other changes are the bare minimum to make PromiseKit 2 compile against Swift 2.

If you still are using Xcode 6 and Swift 1.2 then use PromiseKit 2.

[minimal changes branch]: https://github.com/mxcl/PromiseKit/tree/swift-2.0-minimal-changes

# [2.0](https://github.com/mxcl/PromiseKit/releases/tag/2.0.0) May 14th, 2015

[PromiseKit 2 announcement post](http://promisekit.org/news/2015/05/PromiseKit-2.0-Released/).

# [1.5.0](https://github.com/mxcl/PromiseKit/releases/tag/1.5.0)

Swift 1.2 support. Xcode 6.3 required.

# [1.4.1](https://github.com/mxcl/PromiseKit/releases/tag/1.4.1)

* Added a `race()` function to the Swift branch.
* Improved the zalgoness of `thenUnleashZalgo()`.
* Split the Swift CocoaPods out so it is completely modular like the objc version.

# [1.4.0](https://github.com/mxcl/PromiseKit/releases/tag/1.4.0)

Fixes abound. An additional set of features is a series of new constructors designed to make wrapping existing asynchronous systems easier. Check out `promiseWithAdapter` and company at [cocoadocs.org].

[cocoadocs.org]: (http://cocoadocs.org/docsets/PromiseKit/1.4.0/)

# [1.3.1](https://github.com/mxcl/PromiseKit/releases/tag/1.3.1)

The 1.3.1 tag has been pushed, but only for Carthage users. CocoaPods will skip this version most likely with a 1.3.2 release in the near future.
