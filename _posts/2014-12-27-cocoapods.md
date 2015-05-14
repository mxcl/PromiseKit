---
category: pods
layout: default
---

For instructions on how to install PromiseKit with CocoaPods [see the Getting Started guide](/getting-started).

# Pods That Add Promises To Third Party Libraries

Use PromiseKit with your favorite third party libraries:

* [Parse](https://github.com/hathway/Parse-PromiseKit)
* [RevMob](https://github.com/mxcl/PromiseKit/pull/47)
* [AFNetworking](https://github.com/csotiriou/AFNetworking-PromiseKit) (alternatives:  [1](https://github.com/skeeet/AFNetworking-PromiseKit))
* [Facebook SDK](https://github.com/FastrBooks/Facebook-PromiseKit)

Or see if there’s anything that uses PromiseKit on CocoaPods that you could use:

* [uses:PromiseKit](https://cocoapods.org/?q=uses%3Apromisekit*)

# Pods Built on PromiseKit

* [MBTNetworking](https://github.com/madbat/MBTNetworking) (pretty interesting networking library built on AFNetworking, Mantle and PromiseKit)

# How To Add Promises to Third Party Libraries

It would be great if every library with asynchronous functionality would offer opt-in `PMKPromise *` variants for the asynchronous mechanisms.

Should you want to add PromiseKit integration to your library, the general premise is to add an opt-in `subspec` to your `podspec` that provides methods that return `Promise`s. For example if we imagine a library that overlays a kitten on an image:

{% highlight objectivec %}
@interface ABCKitten
- (instancetype)initWithImage:(UIImage *)image;
- (void)overlayKittenWithCompletionBlock:(void)(^)(UIImage *, NSError *))completionBlock;
@end
{% endhighlight %}

Opt-in PromiseKit support would include a new file `ABCKitten+PromiseKit.h`:

{% highlight objectivec %}
#import <PromiseKit/Promise.h>
#import "ABCKitten.h"


@interface ABCKitten (PromiseKit)

/**
 * Returns a Promise that overlays a kitten image.
 * @return A Promise that will `then` a `UIImage *` object.
 */
- (PMKPromise *)overlayKitten;

@end
{% endhighlight %}

It's crucially important to document your Promise methods [properly](http://nshipster.com/documentation/), because subsequent `then`s are not strongly typed, thus the only clue the user has is how you named your method and the documentation they can get when **⌥** clicking that method.

Consumers of your library would then include in their `Podfile`:

{% highlight ruby %}
pod 'ABCKitten/PromiseKit'
{% endhighlight %}

This is the “opt-in” step.

Finally you need to modify your `podspec`. If it was something like this:

{% highlight ruby %}
Pod::Spec.new do |s|
  s.name         = "ABCKitten"
  s.version      = "1.1"
  s.source_files = 'ABCKitten.{m,h}'
end
{% endhighlight %}

Then you would need to convert it to the following:

{% highlight ruby %}
Pod::Spec.new do |s|
  s.name         = "ABCKitten"
  s.version      = "1.1"

  s.default_subspec = 'base'  # ensures that the PromiseKit additions are opt-in

  s.subspec 'base' do |ss|
    ss.source_files = 'ABCKitten.{m,h}'
  end

  s.subspec 'PromiseKit' do |ss|
    ss.dependency 'PromiseKit/Promise', '~> 1.5'
    ss.dependency 'ABCKitten/base'
    ss.source_files = 'ABCKitten+PromiseKit.{m,h}'
  end
end
{% endhighlight %}


## Adding PromiseKit to a Pod You Don’t Maintain

Firstly you should try submitting the above to the project itself. If they won’t add it then you'll need to make your own pod. Use the naming scheme: `ABCKitten+PromiseKit`. Don’t name it with `PromiseKit` first (it’s not PromiseKit plus foo it’s foo plus PromiseKit!). Also use a `+`: there’s enough dashes in project names already. `+` is more descriptive, it’s more distinctive and CocoaPods accepts such names *just fine*.

<div><a class="pagination" href="/troubleshooting">Next: Troubleshooting</a></div>
