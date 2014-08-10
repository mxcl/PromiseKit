---
category: home
layout: default
---

# Troubleshooting

There are a few common issues that come up when using PromiseKit:


## 1. Unexpected Continuation

Not returning from a catch will resolve that promise `nil` and continue. For example:

{% highlight objectivec %}
self.somePromise.catch(^(NSError *err){
    [UIAlertView show:err];
}).then(^(id o){
    // this block always executes!
    assert(o == nil);
})
{% endhighlight %}

This is a rigid adherance to Promises/A+, however we are [considering changing](https://github.com/mxcl/PromiseKit/issues/62) it to “rethrow” the error.

Really though, this is bad chain design. Probably what you wanted was to nest the chains. Sometimes rightward-drift is *correct* and makes the code clearer.


## 2. `EXC_BAD_ACCESS`

ARC is pretty good, but in some cases it is possible for your Promise chain to be partially deallocated. Usually when wrapping delegate systems. PromiseKit itself has macros that force additional retains and releases to avoid this.
