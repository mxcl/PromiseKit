Modern development is highly asynchronous: isn’t it about time iOS developers had tools that made programming asynchronously powerful, easy and delightful?

```objc
[CLLocationManager promise].catch(^{
    return self.chicagoLocation;
}).then(^(CLLocation *loc){
    return [NSURLConnection GET:@"http://user.net/%f/%f", loc.latitude, loc.longitude];
}).then(^(NSDictionary *user){
    UIAlertView *alert = [UIAlertView new];
    alert.title = [NSString stringWithFormat:@"Hi, %@!", user.name];
    [alert addButtonWithTitle:@"Bye"];
    [alert addButtonWithTitle:@"Hi!"];
    return alert.promise;
}).then(^(NSNumber *tappedButtonIndex, UIAlertView *alert){
    if (tappedButtonIndex.intValue == alert.cancelButtonIndex)
        return nil;
    id vc = [HelloViewController new]
    return [self promiseViewController:vc animated:YES completion:nil].then(^(id resultFromViewController){
        //…
    });
}).catch(^(NSError *err){
    //…
});
```

* PromiseKit can and should be integrated into the other Pods you use.
* PromiseKit is complete, well-tested and in apps on the store.

For guides and complete documentation visit [promisekit.org](http://promisekit.org).
