//
//  PromiseKit+StoreKit.m
//  LedsRock
//
//  Created by Josejulio Martínez on 16/05/14.
//

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

- (Promise *)promise {
    PMKSKProductsRequestDelegater *d = [PMKSKProductsRequestDelegater new];
    [d pmk_reference];
    self.delegate = d;
    [self start];
    return [Promise new:^(id fulfiller, id rejecter){
        d->fulfiller = fulfiller;
        d->rejecter = rejecter;
    }];
}

@end
