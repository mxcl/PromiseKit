Modern development is highly asynchronous; isn’t it about time iOS developers had tools that made programming asynchronously powerful, easy and delightful?

PromiseKit is not just a Promises implementation, it is also a collection of helper functions that make the typical asynchronous patterns we use in iOS development delightful *too*.

PromiseKit is also designed to be integrated into other CocoaPods. If your library has asynchronous operations and you like PromiseKit, then add an opt-in subspec that provides Promises for your users. Documentation to help you integrate PromiseKit into your own pods is provided later in this README.


#Using PromiseKit

In your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```ruby
pod 'PromiseKit'
```

PromiseKit is modulized. If you don’t want any of our category additions:

```ruby
pod 'PromiseKit/base'
```

Or if you only want some of our categories:

```ruby
pod 'PromiseKit/Foundation'
pod 'PromiseKit/UIKit'
pod 'PromiseKit/CoreLocation'
```


#What’s This All About?

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
    [NSURLConnection sendAsynchronousRequest:rq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        UIImage *gravatarImage = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = gravatarImage;
        });
    }];
});
```

The code that does the actual work is now buried inside asynchronicity boilerplate. It is harder to read. The code is less clean.

Promises are chainable, standardized representations of asynchronous tasks. The equivalent code with PromiseKit looks like:

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

Code with promises is about as close as we can get to the minimal cleanliness of synchronous code (at least until Apple give us `@await`…).

The above code dispatches a promise to a background queue (where it computes the md5), the md5 is then input to the next Promise which returns a new Promise that downloads the gravatar. If you return a Promise from a `then` block the next Promise (ie. the Promise returned by the `then`) waits (asynchronously) for that Promise to fulfill before it executes its `then` blocks. PromiseKit’s `NSURLConnection` category methods automatically decode images in a background thread before passing them to the next Promise.

#Error Handling

Synchronous code has simple, clean error handling:

```objc
@try {
    NSString *md5 = md5(email);
    NSString *url = [@"http://gravatar.com/avatar/" stringByAppendingString:md5];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    self.imageView.image = [UIImage imageWithData:data];
} @catch (NSError *error) {
    //TODO
}
```

Error handling with asynchronous code is notoriously tricky:

```objc
void (^errorHandler)(NSError *) = ^(NSError *error){
    //TODO
};

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    @try {
        NSString *md5 = md5(email);
        NSString *url = [@"http://gravatar.com/avatar/" stringByAppendingString:md5];
        NSURLRequest *rq = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [NSURLConnection sendAsynchronousRequest:rq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

            // the code is now misleading since exceptions thrown in this
            // block will not bubble up to our @catch

            if (connectionError) {
                errorHandler(connectionError);
            } else {
                UIImage *img = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = img;
                });
            }
        }];
    } @catch (NSError *err) {
        errorHandler(err);
    }
});
```

Yuck! Hideous! And *even more* rightward-drift.

Promises have elegant error handling:

```objc
#import "PromiseKit.h"

dispatch_promise(^{
    return md5(email);
}).then(^(NSString *md5){
    return [NSURLConnection GET:@"http://gravatar.com/avatar/%@", md5];
}).then(^(UIImage *gravatarImage){
    self.imageView.image = gravatarImage;
}).catch(^(NSError *error){
    //TODO
});
```

Errors bubble up to the first `catch` handler in the chain.


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
id grabcat = [NSURLConnection GET:@"http://placekitten.org/%d/%d", w, h];
id locater = [CLLocationManater promise];

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
    //noop
});

myPromise.then(^(id obj){
    //noop
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


#The Niceties

PromiseKit aims to provide a category analog for all one-time asynchronous features in the iOS SDK (eg. not for UIButton actions, Promises fulfill ***once*** so some parts of the SDK don’t make sense as Promises).

An additional important consideration is that we only trigger the catch handler for errors. Thus `UIAlertView` does not trigger the catch handler for cancel button pushes. Initially we had it that way, and it led to error handling code that was messy and unreliable. The error path is **only** for errors.


##NSURLConnection+PromiseKit

```objc
#import "PromiseKit+Foundation.h"

[NSURLConnection GET:@"http://promisekit.org"].then(^(NSData *data){
    
}).catch(^(NSError *error){
    NSHTTPURLResponse *rsp = error.userInfo[PMKURLErrorFailingURLResponse];
    int HTTPStatusCode = rsp.statuscode;
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
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Yes! Indeed, we converted the JSON data into an NSDictionary for you!");
    }
});

[NSURLConnection GET:@"http://placekitten.org/100/100"].then(^(UIImage *image){
    if ([image isKindOfClass:[UIImage class]]) {
        NSLog(@"Yes! Indeed, we converted the data into a UIImage for you!");
    }
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


##NSURLCache+PromiseKit

Sometimes you just want to query the `NSURLCache` because doing an `NSURLConnection` will take too long and just return the same data anyway. We perform the same header analysis as the `NSURLConnection` categories, so eg. you will get back a `UIImage *` or whatever. If there is nothing in the cache, then you get back `nil`.

```objc
#import "PromiseKit+Foundation.h"

[[NSURLCache sharedURLCache] promisedResponseForRequest:rq].then(^(id o){
    return o ?: [NSURLConnection GET:rq];
});
```


##CLLocationManager+PromiseKit

A promise for a one time update of the user’s location:

```objc
#import "PromiseKit+CoreLocation.h"

[CLLocationManager promise].then(^(CLLocation *currentUserLocation){
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
        // Deferred is resolved
    });
}

@end

@implementation MyDetailViewController
@property Deferred *deferred;

- (void)viewWillDefer:(Deferred *)deferMe {
    // Deferred is documented below this section
    _deferred = deferMe;
}

- (void)someTimeLater {
    [_deferred resolve:someResult];
}

@end
```

As a bonus we handle some of the tedious special ViewController types for you so you don't have to delegate. Currently just `MFMailComposeViewController`. So you can `then` off of it without having to write any delegate code:

```objc
id mailer = [MFMailComposerViewController new];
[self promiseViewController:mailer animated:YES completion:nil].then(^(NSNumber  *num){
    // num is the result passed from the MFMailComposeViewControllerDelegate
}).catch(^{
    // the error from the delegate if that happened
})
```

Note that simply importing `PromiseKit.h` will import everything.


#Promise Factories

With the next version of Promise Kit we plan to add a Promise-Factory type feature so we can have promises generated from `NSNotificationCenter` and `UIControl`s and that sort of thing. It doesn't make sense to have plain promises because Promises can only be fulfilled once.

PromiseKit aims to be a complete and delightful addition to your toolkit.


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

`dispatch_promise` runs on `DISPATCH_QUEUE_PRIORITY_DEFAULT`. If you want other queue priorities then write your own dispatch wrapper around a `Deferred`.


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

  s.default_subspec = 'base'

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
* [Many others](http://cocoapods.org/?q=promise)

PromiseKit is well tested, and inside apps on the store. It also is fully documented, even within Xcode (⌥ click any method).


#Caveats

* We are version 0.9 and thus reserve the right to remove API before 1.0. Probably we won’t; we’re just being prudent by stating this advisory.
* PromiseKit is not thread-safe. This is not intentional, we will fix that. However, in practice the only way to compromise PromiseKit is to keep a pointer to an unresolved Promise and use that from multiple threads. You can execute thens in many different contexts and the underlying immutability of Promises means PromiseKit is inherently thread-safe.
