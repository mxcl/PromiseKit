---
category: docs
layout: default
---

# Bridging From Objective-C to Swift

{% highlight objectivec %}
// foo.h
@interface Foo: NSObject
- (AnyPromise *)bar;
@end
{% endhighlight %}

{% highlight objectivec %}
// bridging header
#import "foo.h"
{% endhighlight %}

{% highlight swift %}
Foo.bar().then { (param: NSString) in
    // **Note** that param must be specialized
}

// or:

moo().then {
    Foo.bar()
}.then { param in
    // param is AnyObject?
}
{% endhighlight %}


# Bridging From Swift to Objective-C

{% highlight swift %}
class Foo {
    func bar1() -> Promise<String> {
        //…
    }

    @objc func bar2() -> AnyPromise {

        // since ObjC cannot see generic objects we have
        // to bridge by writing an adapting function.

        return AnyPromise(bound: bar1())
    }
}
{% endhighlight %}

{% highlight objectivec %}
#import "PROJECTNAME-Swift.h"

[Foo bar2].then(^(NSString *moo){
    //…
});
{% endhighlight %}

<div><a class="pagination" href="/api">Next: API Overview</a></div>
