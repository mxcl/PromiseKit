//
//  PromiseKit+StoreKit.h
//  LedsRock
//
//  Created by Josejulio Martínez on 16/05/14.

@class Promise;

@interface SKProductsRequest (PromiseKit)
- (Promise *)promise;
@end