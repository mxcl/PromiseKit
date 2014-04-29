Modern development is highly asynchronous: isn’t it about time iOS developers had tools that made programming asynchronously powerful, easy and delightful?

PromiseKit is not just a [Promises](http://wikipedia.org/wiki/Promise_%28programming%29) implementation, it is also a collection of helper functions that make the typical asynchronous patterns we use in iOS development delightful *too*.

PromiseKit is also designed to be integrated into other CocoaPods. If your library has asynchronous operations and you like PromiseKit, then add an opt-in subspec that provides Promises for your users. Documentation to help you integrate PromiseKit into your own pods is provided later in this guide.


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
pod 'PromiseKit/MapKit'
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

A `Promise` represents the *future* value of an asynchronous task. To obtain the value of that future, we `then` off the Promise.

```objc
Promise *promise = dispatch_promise(^{
    // we’re in a background thread
    return md5(email);
});

// `dispatch_promise` returns a promise representing the future
// value of the block it executes. You can `then` off any
// Promise object and it will receive the previous Promise’s
// value as its parameter.

promise = promise.then(^(NSString *md5){
    // we’re back in the main thread
    return [NSURLConnection GET:@"http://gravatar.com/avatar/%@", md5];
});

// The previous `then` returned a Promise. The next Promise
// will not execute any `then`s until that Promise is fulfilled.

promise.then(^(UIImage *gravatarImage){
    // The previous promise has fulfilled and provided
    // a `UIImage`. So lets finish and set the Gravatar.
    self.imageView.image = gravatarImage;
});
```

#Error Handling

Synchronous code has simple, clean error handling:

```objc
@try {
    id md5 = md5(email);
    id url = [@"http://gravatar.com/avatar/" stringByAppendingString:md5];
    url = [NSURL URLWithString:url];
    id error;
    id data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (error) @throw error;
    self.imageView.image = [UIImage imageWithData:data];
} @catch (id thrownObject) {
    //…
}
```

Error handling with asynchronous code is notoriously tricky. Here's an example using `NSURLConnection`, CoreLocation and MapKit:

```objc
void (^errorHandler)(NSError *) = ^(NSError *error){
    //…
};

id url = [NSURL URLWithString:@"http://example.com/user.json"];
id rq = [NSURLRequest requestWithURL:url];

[NSURLConnection sendAsynchronousRequest:rq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    if (connectionError) {
        errorHandler(connectionError);
    } else {
        id jsonError;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            errorHandler(jsonError);
        } else {
            id home = [json valueForKeyPath:@"user.home.address"];
            [[CLGeocoder new] geocodeAddressString:home completionHandler:^(NSArray *placemarks, NSError *error) {
                if (error) {
                    errorHandler(error);
                } else {
                    MKDirectionsRequest *rq = [MKDirectionsRequest new];
                    rq.source = [MKMapItem mapItemForCurrentLocation];
                    rq.destination = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithPlacemark:placemarks[0]]];
                    MKDirections *directions = [[MKDirections alloc] initWithRequest:rq];
                    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
                        if (error) {
                            errorHandler(error);
                        } else {
                            //…
                        }
                    }];
                }
            }];
        }
    }
}];
```

Not only does this code drift ever rightwards, reducing readability, but it doesn't handle exceptions that might be thrown (like if there are zero placemarks in the `placemarks` array). The code doesn’t even decode the JSON in a background thread (which may introduce UI lag). But who would want to add *yet another* closure?

##Promises Have Elegant Error Handling

```objc
#import "PromiseKit.h"

[NSURLConnection GET:@"http://example.com/user.json"].then(^(id json){
    id home = [json valueForKeyPath:@"user.home.address"];
    return [CLGeocoder geocode:home];
}).then(^(NSArray *placemarks){
    MKDirectionsRequest *rq = [MKDirectionsRequest new];
    rq.source = [MKMapItem mapItemForCurrentLocation];
    rq.destination = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithPlacemark:placemarks[0]]];
    return [MKDirections promise:rq];
}).then(^(MKDirectionsResponse *directions){
    //…
}).catch(^(NSError *error){
    //…
});
```

Raised exceptions or `NSError` objects returned from handlers bubble up to the first `catch` handler in the chain.

The above makes heavy use of PromiseKit’s category additions to the iOS SDK. Mostly PromiseKit’s categories are logical conversions of block-based or delegation-based patterns to Promises. The exception here is `NSURLConnection+PromiseKit` which detects that the response is JSON (from the HTTP headers) and deserializes that JSON in a background thread. All of PromiseKit’s categories are optional CocoaPods subspecs.


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

A key understanding is that Promises can only exist in two states, *pending* or *resolved*. The resolved state is either fulfilled or rejected (an `NSError` object). A Promise can move from pending to resolved **exactly once**. Whichever state the Promise is in, you can `then` off it.


#Waiting on Multiple Asynchronous Operations

One common reason to use asynchronous variants is so we can do two or more asynchronous operations simultaneously. However writing code that acts when all the simultaneous operations have completed is tricky and bug-prone. Not so with PromiseKit:

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


#Tolerant to the Max

The block you pass to `then` or `catch` can have return type of `Promise`, or any object, or nothing. And it can have a parameter of `id`, or a specific class type, or nothing.

So all of these are valid:

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

This is not usual to Objective-C or blocks. Usually everything is very explicit. We are using introspection to determine what arguments and return types you are working with. Thus, programming with PromiseKit has similarities to programming with (more) modern languages like Ruby or Javascript.

In fact these (and more) are also fine:

```objc
myPromise.then(^{
    return 1;
}).then(^(NSNumber *n){
    assert([n isEqual:@1]);
});

myPromise.then(^{
    return false;
}).then(^(NSNumber *n){
    assert([n isEqual:@NO]);
});
```


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

PromiseKit reads the response headers and decodes the result you actually wanted (in a background thread):

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
[NSURLConnection promise:rq].then(^(NSData *data){
    //…
})
```


##CLLocationManager+PromiseKit

A Promise to get the user’s location:

```objc
#import "PromiseKit+CoreLocation.h"

[CLLocationManager promise].then(^(CLLocation *currentUserLocation){
    //…
}).catch(^(NSError *error){
    //…
});
```


##CLGeocoder+PromiseKit

```objc
#import "PromiseKit+CoreLocation.h"

[CLGeocoder geocode:@"mount rushmore"].then(^(NSArray *placemarks){
    //…
}).catch(^(NSError *error){
    //…
});

CLLocation *someLocation = …;
[CLGeocoder reverseGeocode:someLocation].then(^(NSArray *placemarks){
    //…
}).catch(^(NSError *error){
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
        // PromiseKit automatically dismisses the MyDetailViewController
    });
}

@end

@implementation MyDetailViewController

- (void)someTimeLater {
    [self fulfill:someResult];
    
    // if you want to trigger the `catch` use `[self reject:foo]`
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


##MKDirections+PromiseKit

```objc
#import "PromiseKit+MapKit.h"

MKDirectionsRequest *rq = [MKDirectionsRequest new];
rq.source = [MKMapItem mapItemForCurrentLocation];
rq.destination = …;
[MKDirections promise:rq].then(^(MKDirectionsResponse *rsp){
    //…
}).catch(^{
    //…
});

[MKDirections promiseETA:rq].then(^(MKETAResponse *rsp){
    //…
}).catch(^{
    //…
});
```


#More Documentation

Check out [Promise.h](PromiseKit/Promise.h) and the rest of the sources.


#Promizing Your Codebase

This:

```objc
- (void)calculateTenThousandRandomNumbersWithCompletionBlock:(void(^)(NSArray *))completionBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *numbers = [NSMutableArray new];
        for (int x = 0; x < 10000; x++)
            [numbers addObject:@(arc4random())];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(numbers);
        });
    });
}

- (void)viewDidLoad {
    [self calculateTenThousandRandomNumbersWithCompletionBlock:^(NSArray *numbers){
        //…
    }];
}
```

Becomes this:

```objc
- (Promise *)tenThousandRandomNumbers {
    return dispatch_promise(^{
        NSMutableArray *numbers = [NSMutableArray new];
        for (int x = 0; x < 10000; x++)
            [numbers addObject:@(arc4random())];
        return numbers;
    });
}

- (void)viewDidLoad {
    self.tenThousandRandomNumbers.then(^(NSArray *numbers){
        //…
    }];
}
```

##Wrapping e.g. Parse

```objc
- (Promise *)allUsers {
    return [Promise new:^(PromiseResolver fulfiller, PromiseResolver rejecter){
        PFQuery *query = [PFQuery queryWithClassName:@"User"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                fulfiller(objects);
            } else {
                rejecter(error);
            }
        }];
    }];
}
```

`PromiseResolver` is `typedef void (^PromiseResolver)(id)`, i.e. a block that takes a parameter of `id` and returns `void`.


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
 * @return A Promise that will `then` a `UIImage *` object.
 */
- (Promise *)overlayKitten;

@end
```

It's crucially important to document your Promise methods [properly](http://nshipster.com/documentation/), because subsequent `then`s are not strongly typed, thus the only clue the user has is how you named your method and the documentation they can get when **⌥** clicking that method.

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

  s.default_subspec = 'base'  # ensures that the PromiseKit additions are opt-in

  s.subspec 'base' do |ss|
    ss.source_files = 'ABCKitten.{m,h}'
  end

  s.subspec 'PromiseKit' do |ss|
    ss.dependency 'PromiseKit/base', 'ABCKitten/base'
    ss.source_files = 'ABCKitten+PromiseKit.{m,h}'
  end
end
```

##Adding PromiseKit to Someone Else’s Pod

Firstly you should try submitting the above to the project itself. If they won’t add it then you'll need to make your own pod. Use the naming scheme: `ABCKitten+PromiseKit`.


#Why PromiseKit?

There are other Promise implementations for iOS, but in this author’s opinion, none of them are as pleasant to use as PromiseKit.

* [Bolts](https://github.com/BoltsFramework/Bolts-iOS) was the inspiration for PromiseKit. I thought that—finally—someone had written a decent Promises implementation for iOS. The lack of dedicated `catch` handler, the (objectively) ugly syntax and the overly complex design was a disappointment. To be fair Bolts is not a Promise implementation, it’s…something else. You may like it, and certainly it is backed by big names™. Fundamentally, Promise-type implementations are not hard to write, so really you’re making a decision based on how flexible the API is while simulatenously producing readable, clean code. I have worked hard to make PromiseKit the best choice.
* [RXPromise](https://github.com/couchdeveloper/RXPromise) is an excellent Promise implementation that is not quite perfect (IMHO). By default thens are executed in background threads, which usually is inconvenient. `then` always return `id` and always take `id`, which makes code less elegant. There is no explicit `catch`, instead `then` always takes two blocks, the second being the error handler, which is ugly. The interface for `Promise` allows any caller to resolve it breaking encapsulation. Otherwise an excellent implementation.
* [CollapsingFutures](https://github.com/Strilanc/ObjC-CollapsingFutures) looks good, but is not thoroughly documented so a thorough review would require further experimentation.
* [Many others](http://cocoapods.org/?q=promise)

PromiseKit is well tested, and inside apps on the store. It also is fully documented, even within Xcode (⌥ click any method).


#Caveats

* We are version 0.9 and thus reserve the right to remove/change API before 1.0. Probably we won’t; we’re just being prudent by stating this advisory.
* PromiseKit is not thread-safe. This is not intentional, we will fix that. However, in practice the only way to compromise PromiseKit is to keep a pointer to an pending Promise and use that from multiple threads. You can execute thens in many different contexts and the underlying immutability of Promises means PromiseKit is inherently thread-safe.
* If you don't have at least one catch handler in your chain then errors are silently absorbed which may cause you confusion. We intend to log unhandled errors, (with an opt-in method to have them get thrown and thus crash your app in cases where that is desired).


#Promises/A+ Compliance

PromiseKit is [compliant](http://promisesaplus.com) excluding:

* Our `then` does not take a failure handler, instead we have a dedicated `catch`

If you find further non-compliance please open a [ticket](https://github.com/mxcl/PromiseKit/issues/new).


#Terminology

* Promises start in a **pending** state.
* Promises **resolve** to become **fulfilled** or **rejected**.


#The Fine Print

The fine print of PromiseKit is mostly exactly what you would expect, so don’t confuse yourself: only come back here when you find yourself curious about more advanced techniques.

* Returning a Promise as the value of a `then` (or `catch`) handler will cause any subsequent handlers to wait for that Promise to resolve.
* Returning an instance of `NSError` or throwing an exception within a then block will cause PromiseKit to bubble that object up to the nearest catch handler.
* `catch` handlers always are passed an `NSError` object.
* Returning something other than an `NSError` from a `catch` handler causes PromiseKit to consider the error “corrected”, and execution will continue at the next `then` handler using the object you returned as the input.
* Not returning from a `catch` handler (or returning nil) causes PromiseKit to consider the Promise complete. No further bubbling occurs.
* Nothing happens if you add a `then` to a failed Promise (unless you subsequently add a `catch` handler to the Promise returned from that `then`)
* Adding a `catch` handler to a failed Promise will execute that fail handler: this is converse to adding the same to a **pending** Promise that has a higher `catch` than the one you just added.
