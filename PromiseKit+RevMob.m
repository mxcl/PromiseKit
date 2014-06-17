//
//  PromiseKit+RevMob.m
//  LedsRock
//
//  Created by Josejulio Martínez on 20/05/14.
//  Copyright (c) 2014 Aluxoft SCP. All rights reserved.
//

#import <objc/runtime.h>
#import "Private/PMKManualReference.h"
#import "PromiseKit/Promise.h"
#import "PromiseKit+RevMob.h"

@interface PMKRMRevMobAdDisplayedDelegater : NSObject <RevMobAdsDelegate> {
@public
    void (^fulfiller)(id);
    void (^rejecter)(id);
}
@property(readwrite) RevMobFullscreen* ads;
@end

@implementation PMKRMRevMobAdDisplayedDelegater

- (void)revmobAdDidFailWithError:(NSError *)error {
    rejecter(error);
    self.ads.delegate = nil;
    [self pmk_breakReference];
}

- (void)revmobAdDidReceive {
    fulfiller(PMKManifold(self.ads));
    self.ads.delegate = nil;
    [self pmk_breakReference];
}

@end

@implementation RevMobFullscreen(PromiseKit)

-(Promise*) promise {
    PMKRMRevMobAdDisplayedDelegater *d = [PMKRMRevMobAdDisplayedDelegater new];
    [d pmk_reference];
    self.delegate = d;
    d.ads = self;
    [self loadAd];
    return [Promise new:^(id fulfiller, id rejecter){
        d->fulfiller = fulfiller;
        d->rejecter = rejecter;
    }];
}

@end
