//
//  PromiseKit+StoreKit.m
//  LedsRock
//
//  Created by Josejulio Martínez on 16/05/14.
//
@import StoreKit.SKProductsRequest;
#import <objc/runtime.h>
#import "Private/PMKManualReference.h"
#import "PromiseKit/Promise.h"
#import "PromiseKit+StoreKit.h"

@interface PMKSKProductsRequestDelegater : NSObject <SKProductsRequestDelegate> {
@public
    void (^fulfiller)(id);
}
@end

@implementation PMKSKProductsRequestDelegater
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    fulfiller(PMKManifold(request, response));
    [self pmk_breakReference];
}
@end

@implementation SKProductsRequest (PromiseKit)

- (Promise *)promise {
    PMKSKProductsRequestDelegater *d = [PMKSKProductsRequestDelegater new];
    [d pmk_reference];
    self.delegate = d;
    [self start];
    return [Promise new:^(id fulfiller, id rejecter){
        d->fulfiller = fulfiller;
    }];
}

@end