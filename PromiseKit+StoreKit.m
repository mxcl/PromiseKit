//
//  PromiseKit+StoreKit.m
//  LedsRock
//
//  Created by Josejulio Martínez on 16/05/14.
//
<<<<<<< HEAD
@import StoreKit.SKProductsRequest;
#import <objc/runtime.h>
=======

>>>>>>> upstream/master
#import "Private/PMKManualReference.h"
#import "PromiseKit/Promise.h"
#import "PromiseKit+StoreKit.h"

@interface PMKSKProductsRequestDelegater : NSObject <SKProductsRequestDelegate> {
@public
    void (^fulfiller)(id);
    void (^rejecter)(id);
}
@end

@implementation PMKSKProductsRequestDelegater
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    fulfiller(response);
}

- (void)requestDidFinish:(SKRequest *)request {
    request.delegate = nil;
    [self pmk_breakReference];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    rejecter(error);
    request.delegate = nil;
    [self pmk_breakReference];
}

@end

@implementation SKProductsRequest (PromiseKit)

<<<<<<< HEAD
- (Promise *)promise {
=======
- (PMKPromise *)promise {
>>>>>>> upstream/master
    PMKSKProductsRequestDelegater *d = [PMKSKProductsRequestDelegater new];
    [d pmk_reference];
    self.delegate = d;
    [self start];
<<<<<<< HEAD
    return [Promise new:^(id fulfiller, id rejecter){
=======
    return [PMKPromise new:^(id fulfiller, id rejecter){
>>>>>>> upstream/master
        d->fulfiller = fulfiller;
        d->rejecter = rejecter;
    }];
}

<<<<<<< HEAD
@end
=======
@end
>>>>>>> upstream/master
