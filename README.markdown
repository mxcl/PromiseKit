Modern development is highly asynchronous: isn’t it about time iOS developers had tools that made programming asynchronously powerful, easy and delightful?

![PromiseKit](http://promisekit.org/public/img/tight-header.png)

```objc
UIActionSheet *sheet = …;
sheet.message = @"Share photo with your new local bestie?";
sheet.promise.then(^(NSNumber *dismissedButtonIndex){
    if (dismissedButtonIndex.intValue == alert.cancelButtonIndex)
        return;

    UIImagePickerController *picker = …;
    [self promiseViewController:picker animated:YES completion: nil].then(^(UIImage *img, NSData *imgData){

        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        return [CLLocationManager promise].then(^(CLLocation *located){
            return [NSURLConnection GET:@"share.com/token/%f/%f", located.latitude, located.longitude];
        }).finally(^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }).then(^(NSDictionary *json){
            // the JSON is automatically decoded

            MFMessageViewController *messagevc = …;
            messagevc.to = json[@"to_email"];
            messagevc.body = json[@"message_text"];
            [messagevc addAttachmentData:imgData typeIdentifier:(NSString *)kUTTypeJPEG filename:@"image.jpeg"];
            
            return [self promiseViewController:messagevc animated:YES completion:nil];
        });
        
    }).catch(^(NSError *error){
        // because we returned promises in the above handler, any errors
        // that may occur during execution of the chain will be caught here
        [[UIAlertView:error] show];
    });
});
```

* PromiseKit can and should be integrated into the other Pods you use.
* PromiseKit is complete, well-tested and in apps on the store.

For guides and complete documentation visit [promisekit.org](http://promisekit.org).


#Swift

To test the waters, PromiseKit is available as a Swift variant. If you want to use it in your app then drag and drop `swift/PromiseKit.xcodeproj` into your project.

Currently the Swift and Objective-C versions are indepenedent. We intend to fix that as Xcode 6 matures.

We provide a demo project for the Swift version, just open the provided xcodeproj.

Please be aware that (much like the language) the Swift version is a work in progress.

```swift
let sheet = UIAlertView(…)
sheet.message = "Share photo with your new local bestie?"
sheet.promise().then { dismissedButtonIndex in
    if dismissedButtonIndex == alert.cancelButtonIndex
        return

    let picker = UIImagePickerController(…)
    promiseViewController(picker).then { (img, imgData) in

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        return CLLocationManager.promise().then { located in
            return NSURLConnection.GET("share.com/token/\(located.latitude)/\(located.longitude)")
        }.finally {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }.then { (json: NSDictionary) in
            let messagevc = MFMessageViewController(…)
            messagevc.to = json["to_email"]
            messagevc.body = json["message_text"]
            messagevc.addAttachmentData(imgData, typeIdentifier:kUTTypeJPEG, filename:"image.jpeg")
            return promiseViewController(messagevc)
        }
        
    }.catch { error in
        // because we returned promises in the above handler, any errors
        // that may occur during execution of the chain will be caught here
        UIAlertView(error).show()
    })
})
```
