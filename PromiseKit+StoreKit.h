//
//  PromiseKit+StoreKit.h
//  Aluxoft SCP
//
//  Created by Josejulio Martínez on 16/05/14.

@import StoreKit.SKProductsRequest;
@class PMKPromise;


@interface SKProductsRequest (PromiseKit)
- (PMKPromise *)promise;
@end
