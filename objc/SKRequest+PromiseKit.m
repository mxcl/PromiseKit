//
//  PromiseKit+StoreKit.m
//  Aluxoft SCP
//
//  Created by Josejulio Martínez on 16/05/14.
//

#import "PromiseKit/Promise.h"
#import <objc/runtime.h>
#import "SKRequest+PromiseKit.h"
#import <StoreKit/SKProductsRequest.h>

@interface PMKSKRequestDelegater : NSObject <SKProductsRequestDelegate> {
@public
    void (^fulfill)(id);
    void (^reject)(id);
}
@end

@implementation PMKSKRequestDelegater
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    fulfill(response);
}

- (void)requestDidFinish:(SKRequest *)request {
    fulfill(nil);
    request.delegate = nil;
    PMKRelease(self);
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    reject(error);
    request.delegate = nil;
    PMKRelease(self);
}

@end

@implementation SKProductsRequest (PromiseKit)

- (PMKPromise *)promise {
    PMKSKRequestDelegater *d = [PMKSKRequestDelegater new];
    PMKRetain(d);
    self.delegate = d;
    [self start];
    return [PMKPromise new:^(id fulfiller, id rejecter){
        d->fulfill = fulfiller;
        d->reject = rejecter;
    }];
}

@end
