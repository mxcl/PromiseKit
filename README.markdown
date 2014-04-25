Modern development is highly asynchronous: isn’t it about time iOS developers had tools that made programming asynchronously powerful, easy and delightful?

PromiseKit is not just a [Promises](http://wikipedia.org/wiki/Promise_%28programming%29) implementation, it is also a collection of helper functions that make the typical asynchronous patterns we use in iOS development delightful *too*.

PromiseKit is also designed to be integrated into other CocoaPods. If your library has asynchronous operations and you like PromiseKit, then add an opt-in subspec that provides Promises for your users. Documentation to help you integrate PromiseKit into your own pods is provided later in this README.


#Importing PromiseKit

In your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```ruby
pod 'PromiseKit'
```

PromiseKit is modulized; if you only want `Promise` and none of our category additions:

```ruby
pod 'PromiseKit/base'
```

Or if you only want some of our categories:

```ruby
pod 'PromiseKit/Foundation'
pod 'PromiseKit/UIKit'
pod 'PromiseKit/CoreLocation'
```


#Why Promises?

Synchronous code is clean code. For example, here's the synchronous code to show a gravatar image:

```objc
NSString *md5 = md5(email);
NSString *url = [@"http://gravatar.com/avatar/" stringByAppendingString:md5];
NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
self.imageView.image = [UIImage imageWithData:data];
```

Clean but blocking: the UI lags: the user rates you one star.

The asynchronous analog suffers from *rightward-drift*:

```objc
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *md5 = md5(email);
    NSString *url = [@"http://gravatar.com/avatar/" stringByAppendingString:md5];
    NSURLRequest *rq = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [NSURLConnection sendAsynchronousRequest:rq queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        UIImage *gravatarImage = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = gravatarImage;
        });
    }];
});
```

The code that does the actual work is now buried inside asynchronicity boilerplate. It is harder to read. The code is less clean.

Promises are chainable, standardized representations of asynchronous tasks. The equivalent code with PromiseKit looks like this:

```objc
#import "PromiseKit.h"

dispatch_promise(^{
    return md5(email);
}).then(^(NSString *md5){
    return [NSURLConnection GET:@"http://gravatar.com/avatar/%@", md5];
}).then(^(UIImage *gravatarImage){
    self.imageView.image = gravatarImage;
});
```

Code with promises is about as close as we can get to the minimal cleanliness of synchronous code.

##Explaining That Promise Code

A `Promise` object itself represents the *future* value of an asynchronous task.

```objc
dispatch_promise(^{
    // we’re in a background thread
    return md5(email);
}).then(^(NSString *md5){
    // we’re back in the main thread
    // this next line returns a `Promise *`
    return [NSURLConnection GET:@"http://gravatar.com/avatar/%@", md5];
}).then(^(UIImage *gravatarImage){
    // since the last `then` block returned a Promise,
    // PromiseKit waited for it to complete before we
    // were executed. But now we're done with its result,
    // so let’s set that Gravatar image.
    self.imageView.image = gravatarImage;
});
```

#Error Handling

Synchronous code has simple, clean error handling:

```objc
extern id download(id url);

@try {
    id json1 = download(@"http://api.service.com/user/me");
    id uname = [json1 valueForKeyPath:@"user.name"];
    id json2 = download([NSString stringWithFormat:@"http://api.service.com/followers/%@", uname]);
    self.userLabel.text = @(json2[@"count"]).description;
} @catch (NSError *error) {
    //…
}

id download(id url) {
    id url = [NSURL URLWithString:@"http://api.service.com/user/me"]
    id data = [NSData dataWithContentsOfURL:self.url];
    id error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:data error:&error];
    if (error) @throw error;
}
```

Error handling with asynchronous code is notoriously tricky:

```objc
void (^errorHandler)(NSError *) = ^(NSError *error){
    //…
};

id url = @"http://api.service.com/user/me";
id rq = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
[NSURLConnection sendAsynchronousRequest:rq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    if (connectionError) {
        errorHandler(connectionError);
    } else {
        dispatch_async(bgq, ^{
            id jsonError = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data error:&jsonError]
            dispatch_async(mainq, ^{
                if (jsonError) {
                    errorHandler(jsonError);
                } else {
                    id uname = [json valueForKeyPath:@"user.name"];
                    id url = [NSString stringWithFormat:@"http://api.service.com/followers/%@", uname];
                    id rq = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
                    [NSURLConnection sendAsynchronousRequest:rq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                        if (connectionError) {
                            errorHandler(connectionError);
                        } else {
                            dispatch_async(bgq, ^{
                                id jsonError = nil;
                                id json = [NSJSONSerialization JSONObjectWithData:data error:&jsonError]
                                dispatch_async(mainq, ^{
                                    if (jsonError) {
                                        errorHandler(jsonError);
                                    } else {
                                        self.userLabel.text = @(json2[@"count"]).description;
                                    }
                                });
                            });
                        }
                    }
                }
            });
        });
    }
}];
```

Wow! Such rightward-drift. To be fair the above [could be simplified](https://gist.github.com/mxcl/11267639), but without creating your own `NSOperationQueue` and without using early-return statements and without DRYing out something as common as deserialzing some downloaded JSON, this is what you get. In fact standard asynchronicity handling in iOS practically encourages you to deserialize the JSON on the main thread—simply to avoid rightward-drift.

##Promises Have Elegant Error Handling

```objc
#import "PromiseKit.h"

[NSURLConnection GET:@"http://api.service.com/user/me"].then(^(id json){
    id name = [json valueForKeyPath:@"user.name"];
    return [NSURLConnection GET:@"http://api.service.com/followers/%@", name];
}).then(^(id json){
    self.userLabel.text = @(json[@"count"]).description;
}).catch(^(NSError *error){
    //…
});
```

Raised exceptions or `NSError` objects returned from handlers bubble up to the first `catch` handler in the chain.

PromiseKit’s `NSURLConnection` additions correctly propogate errors for you (as well as decoding the JSON automatically in a background thread based on the mime-type the server returns).


#Say Goodbye to Asynchronous State Machines

Promises represent the future value of a task. You can add more than one `then` handler to a promise. Even after the promise has been fulfilled. If the promise already has a value, the then handler is called immediately:

```objc
@implementation MyViewController {
    Promise *gravatar;
}

- (void)viewDidLoad {
    gravatar = dispatch_promise(^{
        return md5(email);
    }).then(^(NSString *md5){
        return [NSURLConnection GET:@"http://gravatar.com/avatar/%@", md5];
    });

    gravatar.then(^(UIImage *image){
        self.imageView.image = image;
    });
}

- (void)someTimeLater {
    gravatar.then(^(UIImage *image){
        // likely called immediately, but maybe not. We don’t have to worry!
        self.otherImageView.image = image;
    });
}

@end
```

A key understanding is that Promises can only exist in two states, *pending* or *fulfilled*. The fulfilled state is either a value or an `NSError` object. A Promise can move from pending to fulfilled **exactly once**.


#Waiting on Multiple Asynchronous Operations

One powerful reason to use asynchronous variants is so we can do two or more asynchronous operations simultaneously. However writing code that acts when the simultaneous operations have all completed is hard. Not so with PromiseKit:

```objc
Promise *grabcat = [NSURLConnection GET:@"http://placekitten.org/%d/%d", w, h];
Promise *locater = [CLLocationManager promise];

[Promise when:@[grabcat, locater]].then(^(NSArray *results){
    // results[0] is the `UIImage *` from grabcat
    // results[1] is the `CLLocation *` from locater
}).catch(^(NSError *error){
    // with `when`, if any of the Promises fail, the `catch` handler is executed
    NSArray *suberrors = error.userInfo[PMKThrown];

    // `suberrors` may not just be `NSError` objects, any promises that succeeded
    // have their success values passed to this handler also. Thus you could
    // return a value from this `catch` and have the Promise chain continue, if
    // you don't care about certain errors or can recover.
});
```


#Forgiving Syntax

In case you didn't notice, the block you pass to `then` or `catch` can have return type of `Promise`, or any object, or nothing. And it can have a parameter of `id`, or a specific class type, or nothing.

So, these are all valid:

```objc
myPromise.then(^{
    //…
});

myPromise.then(^(id obj){
    //…
});

myPromise.then(^(id obj){
    return @1;
});

myPromise.then(^{
    return @2;
});
```

Clang is smart so you don’t (usually) have to specify a return type for your block.

This is not usual to Objective-C or blocks. Usually everything is very explicit. We are using introspection to determine what arguments and return types you are working with. Thus, programming with PromiseKit has similarities to programming with more modern languages like Ruby or Javascript.


#The Category Additions

PromiseKit aims to provide a category analog for all one-time asynchronous operations in the iOS SDK.

Notably we don’t provide a Promise for eg. `UIButton` actions. Promises can only resolve once, and buttons can be pushed again and again.


##NSURLConnection+PromiseKit

```objc
#import "PromiseKit+Foundation.h"

[NSURLConnection GET:@"http://promisekit.org"].then(^(NSData *data){
    
}).catch(^(NSError *error){
    NSHTTPURLResponse *rsp = error.userInfo[PMKURLErrorFailingURLResponse];
    int HTTPStatusCode = rsp.statusCode;
});
```

And a convenience string format variant:

```objc
[NSURLConnection GET:@"http://example.com/%@", folder].then(^{
    //…
});
```

And a variant that constructs a correctly URL encoded query string from a dictionary:

```objc
[NSURLConnection GET:@"http://example.com" query:@{@"foo": @"bar"}].then(^{
    //…
});
```

And a POST variant:

```objc
[NSURLConnection POST:@"http://example.com" formURLEncodedParameters:@{@"key": @"value"}].then(^{
    //…
});
```

PromiseKit reads the response headers and tries to be helpful:

```objc
[NSURLConnection GET:@"http://example.com/some.json"].then(^(NSDictionary *json){
    assert([json isKindOfClass:[NSDictionary class]]);
});

[NSURLConnection GET:@"http://placekitten.org/100/100"].then(^(UIImage *image){
    assert([image isKindOfClass:[UIImage class]]);
});
```

Otherwise we return the raw `NSData`.

And of course a variant that just takes an `NSURLRequest *`:

```objc
NSMutableURLRequest *rq = [NSMutableURLRequest requestWithURL:url];
[rq addValue:@"PromiseKit" forHTTPHeader:@"User-Agent"]; 
[NSURLConnetion promise:rq].then(^(NSData *data){
    //…
})
```


##CLLocationManager+PromiseKit

A Promise to get the user’s location:

```objc
#import "PromiseKit+CoreLocation.h"

[CLLocationManager promise].then(^(CLLocation *currentUserLocation){
    //…
});
```


##UIAlertView+PromiseKit

A promise for showing a `UIAlertView`:

```objc
#import "PromiseKit+UIKit.h"

UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You Didn’t Save!"
                      message:@"You will lose changes."
                     delegate:nil
            cancelButtonTitle:@"Cancel"
            otherButtonTitles:@"Lose Changes", @"Panic", nil];

alert.promise.then(^(NSNumber *dismissedIndex){
    //…
});
```

This Promise will not trigger a `catch` handler. At one point we had the cancel button trigger `catch`, but this led to unreliable error handling. Only errors trigger `catch` handlers.

##UIActionSheet+PromiseKit

Same pattern as for `UIAlertView`.


##UIViewController+PromiseKit

We provide a pattern for modally presenting ViewControllers and getting back a result:

```objc
#import "PromiseKit+UIKit.h"

@implementation MyRootViewController

- (void)foo {
    UIViewController *vc = [MyDetailViewController new];
    [self promiseViewController:vc animated:YES completion:nil].then(^(id result){
        // the result from below in `someTimeLater`
        // PromiseKit dismisses the MyDetailViewController instance when the
        // `Deferred` is resolved
    });
}

@end

@implementation MyDetailViewController
@property Deferred *deferred;

- (void)viewWillDefer:(Deferred *)deferMe {
    // PromiseKit calls this so you can control the presentation
    // of this ViewController. Deferred is documented below.
    _deferred = deferMe;
}

- (void)someTimeLater {
    [_deferred resolve:someResult];
}

@end
```

As a bonus if you pass a `MFMailComposeViewController` we handle its delegation behind the scenes and convert it into a Promise:

```objc
id mailer = [MFMailComposerViewController new];
[self promiseViewController:mailer animated:YES completion:nil].then(^(NSNumber  *num){
    // num is the result passed from the MFMailComposeViewControllerDelegate
}).catch(^{
    // the error from the delegate if that happened
})
```

Please submit equivalents for eg. `UIImagePickerController`.


#More Documentation

Check out [Promise.h](PromiseKit/Promise.h) and the rest of the sources.


#Deferred

If you want to write your own methods that return Promises then often you will need a `Deferred` object. Promises are deliberately opaque: you can't directly modify them, only their parent promise can.

A `Deferred` has a promise, and using a `Deferred` you can set that Promise's value, the Deferred then recursively calls any sub-promises. For example:

```objc
- (Promise *)tenThousandRandomNumbers {
    Deferred *d = [Deferred new];

    dispatch_async(q, ^{
        NSMutableArray *numbers = [NSMutableArray new];
        for (int x = 0; x < 10000; x++)
            [numbers addObject:@(arc4random())];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (logic) {
                [d resolve:numbers];
            } else {
                [d reject:[NSError errorWith…]];
            }
        });
    });

    return d.promise;
}

- (void)viewDidLoad {
    [self tenThousandRandomNumbers].then(^(NSMutableArray *numbers){
        //…
    });
}
```

Although for the common case of an operation that runs in the background we offer the convenience function `dispatch_promise`, which is like `dispatch_async`, but returns a Promise (which continues on the main queue). So the above would be:

```objc
- (Promise *)tenThousandRandomNumbers {
    return dispatch_promise(^{
        NSMutableArray *numbers = [NSMutableArray new];
        for (int x = 0; x < 10000; x++)
            [numbers addObject:@(arc4random())];
        return numbers;
    });
}
```

`dispatch_promise` runs on `DISPATCH_QUEUE_PRIORITY_DEFAULT`. If you need another queue we also provide: `dispatch_promise_on`.


#The Fine Print

The fine print of PromiseKit is mostly exactly what you would expect, so don’t confuse yourself: only come back here when you find yourself curious about more advanced techniques.

* Returning a Promise as the value of a `then` (or `catch`) handler will cause any subsequent handlers to wait for that Promise to fulfill.
* Returning an instance of `NSError` or throwing an exception within a then block will cause PromiseKit to bubble that object up to the nearest catch handler.
* `catch` handlers always are passed an `NSError` object.
* Returning something other than an `NSError` from a `catch` handler causes PromiseKit to consider the error resolved, and execution will continue at the next `then` handler using the object you returned as the input.
* Not returning from a `catch` handler (or returning nil) causes PromiseKit to consider the Promise complete. No further bubbling occurs.
* Nothing happens if you add a `then` to a failed Promise
* Adding a `catch` handler to a failed Promise will execute that fail handler: this is converse to adding the same to a **pending** Promise.


#Adding Promises to Third Party Libraries

It would be great if every library with asynchronous functionality would offer opt-in `Promise *` variants for the asynchronous mechanisms.

Should you want to add PromiseKit integration to your library, the general premise is to add an opt-in `subspec` to your `podspec` that provides methods that return `Promise`s. For example if we imagine a library that overlays a kitten on an image:

```objc
@interface ABCKitten
- (instancetype)initWithImage:(UIImage *)image;
- (void)overlayKittenWithCompletionBlock:(void)(^)(UIImage *, NSError *))completionBlock;
@end
```

Opt-in PromiseKit support would include a new file `ABCKitten+PromiseKit.h`:

```objc
#import <PromiseKit/Promise.h>
#import "ABCKitten.h"


@interface ABCKitten (PromiseKit)

/**
 * Returns a Promise that overlays a kitten image.
 * @return A Promise that will then a `UIImage *` object.
 */
- (Promise *)overlayKitten;

@end
```

It's crucially important to document your Promise methods [properly](http://nshipster.com/documentation/), because the result of a Promise can be any object type and your users need to be able to easily look up the types by ⌥ clicking the method.

Consumers of your library would then include in their `Podfile`:

```ruby
pod 'ABCKitten/PromiseKit'
```

This is the “opt-in” step.

Finally you need to modify your `podspec`. If it was something like this:

```ruby
Pod::Spec.new do |s|
  s.name         = "ABCKitten"
  s.version      = "1.1"
  s.source_files = 'ABCKitten.{m,h}'
end
```

Then you would need to convert it to the following:

```ruby
Pod::Spec.new do |s|
  s.name         = "ABCKitten"
  s.version      = "1.1"

  s.default_subspec = 'base'  # ensures that we are opt-in

  s.subspec 'base' do |ss|
    ss.source_files = 'ABCKitten.{m,h}'
  end

  s.subspec 'PromiseKit' do |ss|
    ss.dependency 'PromiseKit/base', 'ABCKitten/base'
    ss.source_files = 'ABCKitten+PromiseKit.{m,h}'
  end
end
```

As a further example, the actual implementation of `- (Promise *)overlayKitten` would likely be as simple as this:

```objc
- (Promise *)overlayKitten {
    Deferred *deferred = [Deferred new];
    [self overlayKittenWithCompletionBlock:^(UIImage *img, NSError *err){
        if (err)
            [deferred reject:err];
        else
            [deferred resolve:img];
    }];
    return deferred.promise;
}
```


#Adding PromiseKit to Someone Else’s Pod

Firstly you should try submitting the above to the project itself. If they won’t add it then you'll need to make your own pod. Use the naming scheme: `ABCKitten+PromiseKit`.


#Why PromiseKit?

There are other Promise implementations for iOS, but in this author’s opinion, none of them are as pleasant to use as PromiseKit.

* [Bolts](https://github.com/BoltsFramework/Bolts-iOS) was the inspiration for PromiseKit. I thought that—finally—someone had written a decent Promises implementation for iOS. The lack of dedicated `catch` handler, the (objectively) ugly syntax and the overly complex design was a disappointment. To be fair Bolts is not a Promise implementation, it’s… something else. You may like it, and certainly it is backed by big names™. Fundamentally, Promise-type implementations are not hard to write, so you really are making a decision based on how flexible the API is while simulatenously producing readable, clean code. I have worked hard to make PromiseKit the best choice.
* [RXPromise](https://github.com/couchdeveloper/RXPromise) is an excellent Promise implementation that is mostly let down by syntax choices. By default thens are executed in background threads, which usually is inconvenient. `then` always return `id` and always take `id`, which makes code less elegant. There is no explicit `catch`, instead `then` always takes two blocks, the second being the error handler, which is ugly. The interface for `Promise` allows any caller to resolve it breaking encapsulation. Otherwise an excellent implementation.
* [CollapsingFutures](https://github.com/Strilanc/ObjC-CollapsingFutures) looks good, but not thoroughly documented so hard to say without more experimentation.
* [Many others](http://cocoapods.org/?q=promise)

PromiseKit is well tested, and inside apps on the store. It also is fully documented, even within Xcode (⌥ click any method).


#Caveats

* We are version 0.9 and thus reserve the right to remove/change API before 1.0. Probably we won’t; we’re just being prudent by stating this advisory.
* PromiseKit is not thread-safe. This is not intentional, we will fix that. However, in practice the only way to compromise PromiseKit is to keep a pointer to an unresolved Promise and use that from multiple threads. You can execute thens in many different contexts and the underlying immutability of Promises means PromiseKit is inherently thread-safe.
