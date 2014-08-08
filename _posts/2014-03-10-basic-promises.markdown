---
category: home
layout: default
---

# Promises: The Basics

A Promise represents the *future* value of an asynchronous task.

Promises are useful because:

1. They are chainable;
2. They standardize the API of asynchronous operations;
3. They clean up asynchronous code paths; and
4. They simplify error handling.


## Promises In Practice

Cocoa development can become a mess of asynchronous patterns and asynchronous boilerplate. Here's an example:

{% highlight objectivec %}
@implementation MyViewController

- (void)viewDidLoad {
    id rq = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://placekitten.com/320/320"]];

    void (^handleError)(id) = ^(NSString *msg){
        UIAlertView *alert = [[UIAlertView alloc] init… delegate:self …];
        [alert show];
    };

    [NSURLConnection sendAsynchronousRequest:rq completionHandler:^(id response, id data, id error) {
        if (error) {
            handle([error localizedDescription]);
        } else {
            UIImage *image = [UIImage imageWithData:data];
            if (!image) {
                handleError(@"Bad server response");
            } else {
                self.imageView.image = image;
            }
        }
    }];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // hopefully we won’t ever have multiple UIAlertViews handled in this class
    [self dismissViewControllerAnimated:YES];
}

@end
{% endhighlight %}

The code is ugly, error handling is tricky, the error path spreads over multiple methods and the 90% path is buried inside asynchronicity boilerplate and error handling. Surely there is a better way? Promises are a better way:

{% highlight objectivec %}
#import <PromiseKit.h>

- (void)viewDidLoad {
    [NSURLConnection GET:@"http://placekitten.com/320/320"].then(^(UIImage *image) {
        self.imageView.image = image;
    }).catch(^(NSError *error){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:…];
        [alert promise].then(^{
            [self dismissViewControllerAnimated:YES];
        })
    });
}
{% endhighlight %}

PromiseKit leads to elegant, almost procedural, code with the error handling kept out of the way of the usual path, while simultaneously making it simple to handle errors effectively.

<aside>Indeed PromiseKit’s `NSURLConnection` categories decode the rich data type for you based on the mimetype. Here you get a `UIImage`, decoded in a background thread with the additional error handling that entails for free.</aside>


### Chaining Promises

A `Promise` represents the *future* value of an asynchronous task. To obtain the value of that future, we `then` off that Promise:

{% highlight objectivec %}
UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:…];
[sheet promise].then(^(NSNumber *buttonIndex){
    //…
});
{% endhighlight %}

Modern development though usually involves sequences of consecutive, serial, asynchronous tasks. Block-based solutions result in rightward-drift:

{% highlight objectivec %}
UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:…];
[sheet promise].then(^(NSNumber *buttonIndex){
    int const size = (buttonIndex.intValue + 1) * 100;
    [NSURLConnection GET:@"http://placekitten.com/%d/%d", size, size].then(^(UIImage *kittenImage){
        self.imageView = kittenImage;
    });
});
{% endhighlight %}

It doesn’t take long for rightward-drift to impede readability and make you want to refactor. Promises solve this by making `then` chainable.

{% highlight objectivec %}
UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:…];
[sheet promise].then(^(NSNumber *buttonIndex){
    int const size = (buttonIndex.intValue + 1) * 100;
    return [NSURLConnection GET:@"http://placekitten.com/%d/%d", size, size];
}).then(^(UIImage *kittenImage){
    self.imageView = image;
});
{% endhighlight %}

By returning promises from your `then` handlers you can chain asynchronous tasks together making them occur consecutively.

Though, you don’t have to return promises, any value you return is passed to subsequent `then` handlers:

{% highlight objectivec %}
UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:…];
[sheet promise].then(^(NSNumber *buttonIndex){
    return buttonIndex;
}).then(^(NSNumber *buttonIndex){
    return buttonIndex;
}).then(^(NSNumber *buttonIndex){
    NSLog(@"Button index: %@", buttonIndex);
});
{% endhighlight %}


### Error Handling

One of the best parts of Promises is the implicit and standardized error handling. If an error occurs during your Promise chain, the nearest `catch` handler is executed, skipping any `then` handlers in between.

Thus create promise chains that correlate to a sequence of events with the same error domain. Often very long chains imply poor judgement about error handling.

Notably, any exceptions thrown during promise execution are caught and turned into `NSError`s.

<aside>If you throw some other kind of object the `NSError` will have its `localizedDescription` set to that object’s description. This means throwing strings can be a direct way to show the user an error message. The thrown object will be available in the `NSError`’s `userInfo`’s `PMKUnderlyingExceptionKey`.</aside>


### Causing Errors

To cause your chain to be rejected simply return an `NSError` or throw an exception within a `then` block.


### Continuation

You can return from an error handler. Returning anything but an `NSError` implies the error has been resolved, and the chain will continue.

{% highlight objectivec %}
[CLLocationManager promise].catch(^(NSError *error){
    return CLLocationChicago;
}).then(^(CLLocation *userLocation){
    // the user’s location, or Chicago if an error occurred
});
{% endhighlight %}

This is useful for error-correction. If the error is fatal, then you can return the error again, or return a new Error.


## A Pause for Terminology

* Promises start in a **pending** state.
* Promises **resolve** with a **value** to become **fulfilled** or **rejected**.


## Synchronizing with `+when:`

`+when:` returns a new promise that is fulfilled when all its promises fulfill:

{% highlight objectivec %}
PMKPromise *promise1 = [NSURLConnection GET:@"http://placekitten.com/100/100"];
PMKPromise *promise2 = [UIView promiseWithDuration:0.3 animations:^{
    self.frame = CGRectOffset(self.frame, 0, 200);
}];

[PMKPromise when:@[promise1, promise2]].then(^(NSArray *results){
    UIImage *kittenImage = results[0];
    NSNumber *animationCompleted = results[1];
});
{% endhighlight %}

`+when:` makes it easy to act after multiple asynchronous operations have resolved. If any promise is rejected the `when` is immediately rejected with that `NSError`.

If you pass an `NSDictionary` to `when` you will get an `NSDictionary` of values in subsequent `then`s.
