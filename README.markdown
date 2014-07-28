Modern development is highly asynchronous: isn’t it about time iOS developers had tools that made programming asynchronously powerful, easy and delightful?

![PromiseKit](http://promisekit.org/public/img/tight-header.png)

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


#Swift

To test the waters, PromiseKit is available as a Swift variant. If you want to use it in your app then drag and drop `swift/PromiseKit.xcodeproj` into your project.

Currently the Swift and Objective-C versions are indepenedent. We hope to fix that as Xcode 6 matures.

We provide a demo project for the Swift version, just open the provided xcodeproj.

Please be aware that (much like the language) the Swift version is a work in progress.

```swift
CLLocationManager.promise().catch {
    // If location cannot be determined, default to Chicago
    return CLLocation(latitude: 41.89, longitude: -87.63)
}.then {
    let (lat, lon) = ($0.coordinate.latitude, $0.coordinate.longitude)
    return NSURLConnection.GET("http://user.net/\(lat)/\(lon)")
}.then { (user:NSDictionary) in
    let alert = UIAlertView()
    alert.title = "Hi " + user["name"]
    alert.addButtonWithTitle("Bye")
    alert.addButtonWithTitle("Hi")
    return alert.promise()
}.then { [unowned self] tappedButtonIndex -> Promise<Void>? in
    if tappedButtonIndex == 0 {
        return nil
    }
    let vc = HelloViewController()
    return self.promiseViewController(vc).then { (modallyPresentedResult:String) -> Void in
        //…
    }
}.catch { error in
    //…
}
```
