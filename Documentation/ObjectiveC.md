# Objective-C

PromiseKit has two promise classes:

* `Promise<T>` (Swift)
* `AnyPromise` (Objective-C)

Each is designed to be an approproate promise implementation for the strong
points of its language:

* `Promise<T>` is strict, defined and precise.
* `AnyPromise` is loose and dynamic.

Unlike most libraries we have extensive bridging support, you can use PromiseKit
in mixed projects with mixed language targets and mixed language libraries.


# Using PromiseKit with Objective-C

`AnyPromise` is our promise class for Objective-C. It behaves almost identically to `Promise<T>` (our Swift promise class).

```objc
myPromise.then(^(NSString *bar){
    return anotherPromise;
}).then(^{
    //…
}).catch(^(NSError *error){
    //…
});
```

You make new promises using `promiseWithResolverBlock`:

```objc
- (AnyPromise *)myPromise {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve){
        resolve(foo);  // if foo is an NSError, rejects, else, resolves
    }];
}
```

---

You reject promises by throwing errors:

```objc
myPromise.then(^{
    @throw [NSError errorWithDomain:domain code:code userInfo:nil];
}).catch(^(NSError *error){
    //…
});
```

---

One important feature is the syntactic flexability of your handlers:

```objc
myPromise.then(^{
    // no parameters is fine
});

myPromise.then(^(id foo){
    // one parameter is fine
});

myPromise.then(^(id a, id b, id c){
    // up to three parameter is fine, no crash!
});

myPromise.then(^{
    return @1; // return anything or nothing, it's fine, no crash
});
```

We do runtime inspection of the block you pass to achieve this magic.

---

Another important distinction is that the equivalent function to Swift’s `recover` is combined with `AnyPromise`’s `catch`. This is typical to other “dynamic” promise implementations and thus achieves our goal that `AnyPromise` is loose and dynamic while `Promise<T>` is strict and specific.

A sometimes unexpected consequence of this is that returning nothing from a `catch` *resolves* the returned promise:

```objc
myPromise.catch(^{
    [UIAlertView …];
}).then(^{
    // always executes!
});
```

---

Another important distinction is that the `value` property returns even if the promise is rejected, in that case it returns the `NSError` object with which the promise was rejected.


# Bridging Between Objective-C & Swift

Let’s say you have:

```objc
@interface Foo
- (AnyPromise *)myPromise;
@end
```

Ensure this interface is included in your bridging header.

You can now use this in your Swift code:

```swift
let foo = Foo()
foo.myPromise.then { (obj: AnyObject?) -> Int in
    // it is not necessary to specify the type of `obj`
    // we just do that for demonstrative purposes
}
```

---

Let’s say you have:

```swift
@objc class Foo: NSObject {
    func stringPromise() -> Promise<String>    
    func barPromise() -> Promise<Bar>
}

@objc class Bar: NSObject { /*…*/ }
```

Ensure that your project is generating a `…-Swift.h` header so your Objective-C can see your Swift code.

If you built this and opened the `…-Swift.h` header you would only see this:

```objc
@interface Foo
@end

@interface Bar
@end
```

This is because Objective-C cannot import Swift objects that are generic. Thus we need to write some stubs:

```swift
@objc class Foo: NSObject {
    @objc func stringPromise() -> AnyPromise {
        return AnyPromise(stringPromise())
    }
    @objc func barPromise() -> AnyPromise {
        return AnyPromise(barPromise())
    }
}
```

If we built this and opened our generated header we would now see:

```objc
@interface Foo
- (AnyPromise *)stringPromise;
- (AnyPromise *)barPromise;
@end

@interface Bar
@end
```

Perfect.

Note that AnyPromise can only bridge objects that conform to `AnyObject` or derive `NSObject`. This is a limitation of Objective-C.

