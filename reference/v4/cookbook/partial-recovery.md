---
layout: docs
redirect_from: "/partial-recovery/"
---

#  Partial Recovery

Sometimes you have promises that are semi-recoverable. Rather than lump all error handling together and figure out the error with if statements instead add a `catch` to that promise directly. It leads to a little rightward-drift, but it is the best way to implement semi-recoverability.

```objc
self.fetch.then(^(id json){
    return [CLLocationManager promise].catch(^id(NSError *err){
        if (err.code == kCLErrorLocationUnknown)
            return self.chicagoLocation;
        return err;  // “re-throw”
    });
}).then(^{
    //…
});
```

This can be especially important when using `when`/`all` since those methods will immediately reject their promise if any of the promises provided them rejects, often one can recover at least some of the provided promises.

Note that we had to change the above block’s return to `id` so that it could return two different types.
