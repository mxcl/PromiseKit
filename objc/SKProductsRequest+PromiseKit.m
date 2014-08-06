//
//  PromiseKit+StoreKit.m
//  Aluxoft SCP
//
//  Created by Josejulio Martínez on 16/05/14.
//

#import "PromiseKit/Promise.h"
#import <objc/runtime.h>
#import "SKProductsRequest+PromiseKit.h"

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
    PMKRelease(self);
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    rejecter(error);
    request.delegate = nil;
    PMKRelease(self);
}

@end

@implementation SKProductsRequest (PromiseKit)

- (PMKPromise *)promise {
    PMKSKProductsRequestDelegater *d = [PMKSKProductsRequestDelegater new];
    PMKRetain(d);
    self.delegate = d;
    [self start];
    return [PMKPromise new:^(id fulfiller, id rejecter){
        d->fulfiller = fulfiller;
        d->rejecter = rejecter;
    }];
}

@end
