//
//  PromiseKit+StoreKit.h
//  Aluxoft SCP
//
//  Created by Josejulio Martínez on 16/05/14.

#import <PromiseKit/fwd.h>
#import <StoreKit/SKRequest.h>

/**
 Note that SKProductsRequest is a subclass of SKRequest. Thus it also has
 a promise method.
*/
@interface SKRequest (PromiseKit)
- (PMKPromise *)promise;
@end
