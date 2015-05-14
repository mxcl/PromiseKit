---
category: pods
layout: default
---

For instructions on how to install PromiseKit with CocoaPods [see the Getting Started guide](/getting-started).

# Pods That Come With Promises

Many pods come with promises or add promises to other famous libraries (eg. AFNetworking). [uses:PromiseKit](https://cocoapods.org/?q=uses%3Apromisekit).

# How To Add Promises to Third Party Libraries

It would be great if every library with asynchronous functionality would offer opt-in promises for the asynchronous mechanisms.

Should you want to add PromiseKit integration to your library, the general premise is to add an opt-in `subspec` to your `podspec` that provides methods that return `Promise`s. For example if we imagine a library that overlays a kitten on an image:

{% highlight objectivec %}
@interface ABCKitten
- (instancetype)initWithImage:(UIImage *)image;
- (void)overlayKittenWithCompletionBlock:(void)(^)(UIImage *, NSError *))completionBlock;
@end
{% endhighlight %}

Opt-in PromiseKit support would include a new file `ABCKitten+AnyPromise.h`:

{% highlight objectivec %}
#import <PromiseKit/Promise.h>
#import "ABCKitten.h"


@interface ABCKitten (PromiseKit)

/**
 * Returns a Promise that overlays a kitten image.
 * @return A Promise that will `then` a `UIImage *` object.
 */
- (AnyPromise *)overlayKitten;

@end
{% endhighlight %}

It's crucially important to document your `AnyPromise` methods [properly](http://nshipster.com/documentation/), because subsequent `then`s are not strongly typed, thus the only clue the user has is how you named your method and the documentation they can get when **⌥** clicking that method.

Obviously, Swift promises are strongly typed, but still documentation is a good thing!

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

  # This bit is important, it makes it so the default pod incantation doesn’t
  # force a PromiseKit dependency.
  s.default_subspec = 'CoreKitten'

  s.subspec 'CoreKitten' do |ss|
    ss.source_files = 'ABCKitten.{m,h}'
  end

  s.subspec 'PromiseKit' do |ss|
    # Don’t depend on the whole of PromiseKit! Just the core parts.
    ss.dependency 'PromiseKit/CorePromise', '~> 2.0'

    ss.dependency 'ABCKitten/CoreKitten'
    ss.source_files = 'ABCKitten+AnyPromise.{m,h}'
  end
end
{% endhighlight %}


## Adding PromiseKit to a Pod You Don’t Maintain

Firstly you should try submitting the above to the project itself. If they won’t
add it then you'll need to make your own pod. Use the naming scheme:
`ABCKitten+PromiseKit`. Don’t name it with `PromiseKit` first (it’s not
PromiseKit plus foo it’s foo plus PromiseKit!). Also use a `+`: there’s enough
dashes in project names already. `+` is more descriptive, it’s more distinctive
and CocoaPods accepts such names *just fine*.


## `Promise<T>` or `AnyPromise`?

If your library is Swift, provide `Promise<T>` and if your library is ObjC,
provide `AnyPromise`. We don’t suggest providing both. PromiseKit itself
provides bridging mechanisms, support the language you like.


<div><a class="pagination" href="/troubleshooting">Next: Troubleshooting</a></div>
