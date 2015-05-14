//
//  PromiseKit+StoreKit.h
//  Aluxoft SCP
//
//  Created by Josejulio Martínez on 16/05/14.

#import <PromiseKit/AnyPromise.h>
#import <StoreKit/SKRequest.h>

/**
 To import the `SKRequest` category:

    use_frameworks!
    pod "PromiseKit/StoreKit"
 
 And then in your sources:
 
    #import <PromiseKit/PromiseKit.h>
*/
@interface SKRequest (PromiseKit)

/**
 Sends the request to the Apple App Store.

 @return A promise that fulfills when the request succeeds. If the
 receiver is an SKProductsRequest, the promise fulfills with its
 `SKProductsResponse`, otherwise the promise is void.
*/
- (AnyPromise *)promise;

@end
