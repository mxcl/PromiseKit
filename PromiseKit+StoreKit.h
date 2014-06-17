//
//  PromiseKit+StoreKit.h
//  LedsRock
//
//  Created by Josejulio Martínez on 16/05/14.

<<<<<<< HEAD
@class Promise;

@interface SKProductsRequest (PromiseKit)
- (Promise *)promise;
@end
=======
@import StoreKit.SKProductsRequest;
@class PMKPromise;


@interface SKProductsRequest (PromiseKit)
- (PMKPromise *)promise;
@end
>>>>>>> upstream/master
