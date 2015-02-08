---
category: docs
layout: default
---

# Integrating PromiseKit Into Your App

In your [Podfile](http://guides.cocoapods.org/using/using-cocoapods.html):

{% highlight ruby %}
pod 'PromiseKit'
{% endhighlight %}

In your `.m` files:

{% highlight c %}
#import <PromiseKit.h>
{% endhighlight %}

In your `.swift` files:
{% highlight swift %}
import PromiseKit
{% endhighlight %}

PromiseKit is modulized; if you only want `PMKPromise` and none of our category additions:

{% highlight ruby %}
pod 'PromiseKit/Promise'
{% endhighlight %}

Or if you only want some of our categories:

{% highlight ruby %}
pod 'PromiseKit/NSURLConnection'
pod 'PromiseKit/UIActionSheet'
pod 'PromiseKit/UIAlertView'
# et cetera
{% endhighlight %}

There is a CocoaPods subspec for every category and an umbrella subspec for every framework (eg. `Promisekit/Foundation`, `Promisekit/UIKit`, etc.). If you don’t want to think about it then choose `pod 'PromiseKit'` or `pod 'PromiseKit/all'`; `all` is *everything*. 

<aside>
Asking for just the `PromiseKit` pod gives you the 80% most people want, ie. `PMKPromise`, the `NSURLConnection` & `NSNotifcationCenter` category additions and the `UIKit` category additions.
</aside>


## Without CocoaPods

If you don’t want to use CocoaPods you can use [CocoaPods Packager](https://github.com/CocoaPods/cocoapods-packager) to generate a static version of PromiseKit and just embed that.

Please though! Update every now and again!


## Carthage

Carthage support is coming, if you are capable, please add it and create a pull request!


<div><a class="pagination" href="/swift">Next: Specifics Regarding Swift PromiseKit</a></div>
