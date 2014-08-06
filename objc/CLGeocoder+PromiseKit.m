#import "CLGeocoder+PromiseKit.h"
#import "PromiseKit/Promise.h"


@implementation CLGeocoder (PromiseKit)

+ (PMKPromise *)reverseGeocode:(CLLocation *)location {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
       [[CLGeocoder new] reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error) {
                rejecter(error);
            } else
                fulfiller(PMKManifold(placemarks.firstObject, placemarks));
        }];
    }];
}

+ (PMKPromise *)geocode:(id)address {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        id handler = ^(NSArray *placemarks, NSError *error) {
            if (error) {
                rejecter(error);
            } else
                fulfiller(PMKManifold(placemarks.firstObject, placemarks));
        };
        if ([address isKindOfClass:[NSDictionary class]]) {
            [[CLGeocoder new] geocodeAddressDictionary:address completionHandler:handler];
        } else {
            [[CLGeocoder new] geocodeAddressString:address completionHandler:handler];
        }
    }];
}

@end
