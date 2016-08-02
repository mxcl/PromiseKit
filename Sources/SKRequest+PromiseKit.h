//
//  PromiseKit+StoreKit.h
//  Aluxoft SCP
//
//  Created by Josejulio Martínez on 16/05/14.

#import <PromiseKit/fwd.h>
#import <StoreKit/SKRequest.h>

/**
 To import the `SKRequest` category:

    pod "PromiseKit/SKRequest"

 Or you can import all categories on `StoreKit`:

    pod "PromiseKit/StoreKit"

 Notably, `SKProductsRequest` subclasses `SKRequest`. So, it also has the following methods.
*/
@interface SKRequest (PromiseKit)

/**
 Sends the request to the Apple App Store.

 @return A void promise that fulfills when the request succeeds.
*/
- (PMKPromise *)promise;

@end
