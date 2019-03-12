# Objective-C

PromiseKit has two promise classes:

* `Promise<T>` (Swift)
* `AnyPromise` (Objective-C)

Each is designed to be an appropriate promise implementation for the strong points of its language:

* `Promise<T>` is strict, defined and precise.
* `AnyPromise` is loose and dynamic.

Unlike most libraries, we have extensive bridging support, you can use PromiseKit
in mixed projects with mixed language targets and mixed language libraries.


# Using PromiseKit with Objective-C

`AnyPromise` is our promise class for Objective-C. It behaves almost identically to `Promise<T>`, our Swift promise class.

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

One important feature is the syntactic flexibility of your handlers:

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

A sometimes unexpected consequence of this fact is that returning nothing from a `catch` *resolves* the returned promise:

```objc
myPromise.catch(^{
    [UIAlertView …];
}).then(^{
    // always executes!
});
```

---

Another important distinction is that the `value` property returns even if the promise is rejected; in that case, it returns the `NSError` object with which the promise was rejected.


# Bridging Between Objective-C & Swift

Let’s say you have:

```objc
@interface Foo
- (AnyPromise *)myPromise;
@end
```

Ensure that this interface is included in your bridging header. You can now use the 
following pattern in your Swift code:

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

Ensure that your project is generating a `…-Swift.h` header so that Objective-C can see your Swift code.

If you built this project and opened the `…-Swift.h` header, you would only see this:

```objc
@interface Foo
@end

@interface Bar
@end
```

That's because Objective-C cannot import Swift objects that are generic. So we need to write some stubs:

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

If we built this and opened our generated header, we would now see:

```objc
@interface Foo
- (AnyPromise *)stringPromise;
- (AnyPromise *)barPromise;
@end

@interface Bar
@end
```

Perfect.

Note that AnyPromise can only bridge objects that conform to `AnyObject` or derive from `NSObject`. This is a limitation of Objective-C.

# Using ObjC AnyPromises from Swift

Simply use them, the type of your handler parameter is `Any`:

```objective-c
- (AnyPromise *)fetchThings {
    return [AnyPromise promiseWithValue:@[@"a", @"b", @"c"]];
}
```

Since ObjC is not type-safe and Swift is, you will (probably) need to cast the `Any` to whatever it is you actually are feeding:

```swift
Foo.fetchThings().done { any in
    let bar = any as! [String]
}
```

## :warning: Caution:

ARC in Objective-C, unlike in Objective-C++, is not exception-safe by default.
So, throwing an error will result in keeping a strong reference to the closure 
that contains the throw statement.
This pattern will consequently result in memory leaks if you're not careful.

> *Note:* Only having a strong reference to the closure would result in memory leaks.
> In our case, PromiseKit automatically keeps a strong reference to the closure until it's released.

__Workarounds:__

1. Return a Promise with value NSError\
Instead of throwing a normal error, you can return a Promise with value NSError instead.

```objc
myPromise.then(^{
    return [AnyPromise promiseWithValue:[NSError myCustomError]];
}).catch(^(NSError *error){
    if ([error isEqual:[NSError myCustomError]]) {
        // In case, same error as the one we thrown
        return;
    }
    //…
});
```
2. Enable ARC for exceptions in Objective-C (not recommended)\
You can add this  ```-fobjc-arc-exceptions to your``` to your compiler flags to enable ARC for exceptions.
This is not recommended unless you've read the Apple documentation and are comfortable with the caveats.

For more details on ARC and exceptions:
https://clang.llvm.org/docs/AutomaticReferenceCounting.html#exceptions

