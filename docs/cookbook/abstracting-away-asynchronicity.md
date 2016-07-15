---
layout: docs
redirect_from: "/abstracting-away-asynchronicity/"
---

# Abstracting Away Asynchronicity

Complex asynchronous state machines exist in our apps. Correct use of promises can remove the state machine entirely. The code becomes what people are calling: *reactive*.

For example, our app shows the local weather with on-demand user refresh. Periodically we check the user’s location to ensure the weather information we display is accurate.

If we are still checking the user’s location, we don’t want the refresh to happen yet. We want to delay it, until we know the location. With conventional methods, this is a very limited state machine that we can represent without special tools:

```objc
@interface MyViewController
@property BOOL updatingLocation;
@property BOOL refreshWhenDoneUpdatingLocation;
@property CLLocationManager *locationManager;
@end

- (void)userDidPullRefresh {
    if (self.updatingLocation) {
        self.refreshWhenDoneUpdatingLocation = YES;
    } else {
        NSURLRequest *request = …
        [NSURLConnection sendAsynchronousRequest:… ^{
            [self.tableView reloadData];
        }];
    }
}

- (void)locationManagerDidUpdateLocation:(CLLocation *)location {
    if (self.refreshWhenDoneUpdatingLocation) {
        self.refreshWhenDoneUpdatingLocation = NO;
        [self userDidPullRefresh];
    }
}

- (void)shouldStartUpdatingLocation {
    if (!self.updatingLocation) {
        self.updatingLocation = YES;
        [self.locationManager startUpdatingLocation];
    }
}
```

Not too complicated. The code is understandable. However it would be simpler with promises:

```objc
@interface MyViewController
@property AnyPromise *locationUpdater;
@end

- (void)userDidPullRefresh {
    self.locationUpdater.then(^{
        NSURL *url = …
        return [NSURLConnection GET:url];
    }).catch(^{
        return [UIAlertView …].promise;
    });
}

- (void)shouldStartUpdatingLocation {
    if (!self.locationUpdater.pending) {
        self.locationUpdater = [CLLocationManager promise];
    }
}
```

We store the location update promise as a property. If it is pending the refresh will happen when it resolves, if it is already resolved the refresh will happen (almost) immediately.

Effectively we have abstracted around the asychronicty and we can treat the promise properties as the value they will eventually represent.

<aside>This uses very little memory. Once a promise resolves all handlers are released, meaining a resolved promise uses only very slightly more memory than its `value`. If you want to be particularly frugal you can use `when`, since when can take a value or a promise, but this means having a property of type `id` and wrapping all use of this property in `when`s.</aside>

<hr>

## Features Creep

Suddenly your client wants a new feature. On ocassion they will push notify all users with a silent notification that should show an advert based on the weather at the user’s location. Now we have a gnarly state machine:

```objc
@interface MyViewController
@property BOOL updatingLocation;
@property BOOL refreshWhenDoneUpdatingLocation;
@proeprty BOOL showAdWhenAsyncAllDone;
@property CLLocationManager *locationManager;
@end

- (void)userDidPullRefresh {
    if (self.refreshingWeather)
        return;
    
    if (self.updatingLocation) {
        self.refreshWhenDoneUpdatingLocation = YES;
    } else {
        self.refreshingWeather = YES;

        NSURLRequest *request = …
        [NSURLConnection sendAsynchronousRequest:… ^{
            self.refreshingWeather = NO;            
            [self.tableView reloadData];
            
            if (self.showAdWhenAsyncAllDone) {
                self.showAdWhenAsyncAllDone = NO;
                [self showAd];
            }
        }];
    }
}

- (void)locationManagerDidUpdateLocation:(CLLocation *)location {
    if (self.refreshWhenDoneUpdatingLocation || self.showAdWhenAsyncAllDone) {
        self.refreshWhenDoneUpdatingLocation = NO;
        [self userDidPullRefresh];
    }
}

- (void)shouldStartUpdatingLocation {
    if (!self.updatingLocation) {
        self.updatingLocation = YES;
        [self.locationManager startUpdatingLocation];
    }
}

- (void)shouldShowAd {
    if (self.updatingLocation || self.refreshingWeather) {
        self.showAdWhenAsyncAllDone = YES;
    } else {
        [self showAd];
    }
}
```

Yikes. Promises transform this code:

```objc
@interface MyViewController
@property AnyPromise *locater;
@property AnyPromise *refresher;
@end

- (void)userDidPullRefresh {
    if (self.refresher.pending)
        return;

    self.refresher = self.locater.then(^(CLLocation *location){
        NSURL *url = …
        return [NSURLSession GET:url];
    }).catch(^{
        return [UIAlertView …].promise;
    });
}

- (void)shouldStartUpdatingLocation {
    if (!self.locationUpdater.pending) {
        self.locationUpdater = [CLLocationManager promise];
    }
}

- (void)shouldShowAd {
    PMKWhen(@[self.locater, self.refresher]).then(^{
        [self showAd];
    });
}
```

Concise, elegant, readable.
