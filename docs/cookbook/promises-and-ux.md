---
layout: docs
redirect_from: "/promises-and-ux/"
---

# Promises &amp; User Experience

A truly polished app is not just in the details like turning autocomplete off for the username field in your login screen. Nowadays the true mark of polish is that asynchronous transitions in your apps state are polished too. Without promises this kind of polish can rapidly make your codebase unmanageable.

Promises make your asychronous code standardized and modular. Once you realize this many tricks that before would make the code absurdly complicated become easy and your app can be more polished. For example here we animate a view up during an asynchronous operation and down afterwards, but in the event of an error the view animates down while the `UIAlertView` presents. It’s a small visual glitch, but what if it were trivial to fix it?

```objc
[UIView promiseWithDuration:0.3 animations:^{
    view.frame = CGRectOffset(view.frame, 0, -100);
}].then(^{
    return [self doWork];
}).catch(^(NSError *error){
    [[UIAlertView …] show];
}).finally(^{
    view.frame = CGRectOffset(view.frame, 0, +100);
})
```

Because Promises are standardized, we can in fact easily prevent the finally from triggering by wrapping the UIAlertView asynchronous interactions in a promise. PromiseKit already provides this wrapper:

```objc
[UIView promiseWithDuration:0.3 animations:^{
    view.frame = CGRectOffset(view.frame, 0, -100);
}].then(^{
    return [self doWork];
}).catch(^(NSError *error){
    return [UIAlertView …].promise;
}).finally(^{
    view.frame = CGRectOffset(view.frame, 0, +100);
})
```

Did you spot the difference? By returning the alertView’s promise the finally animation will occur when the alertView disappears and our app will feel that little more polished.

Without promises this code would be fickle and, frankly, gross.
