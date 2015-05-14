#import "CLGeocoder+AnyPromise.h"
#import <CoreLocation/CLError.h>
#import <CoreLocation/CLErrorDomain.h>
#import "PromiseKit.h"


@implementation CLGeocoder (PromiseKit)

+ (void)load {
    [NSError registerCancelledErrorDomain:kCLErrorDomain code:kCLErrorGeocodeCanceled];
}

- (AnyPromise *)reverseGeocode:(CLLocation *)location {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
       [self reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
           resolve(error ?: PMKManifold(placemarks.firstObject, placemarks));
        }];
    }];
}

- (AnyPromise *)geocode:(id)address {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        id handler = ^(NSArray *placemarks, NSError *error) {
            resolve(error ?: PMKManifold(placemarks.firstObject, placemarks));
        };
        if ([address isKindOfClass:[NSDictionary class]]) {
            [self geocodeAddressDictionary:address completionHandler:handler];
        } else {
            [self geocodeAddressString:address completionHandler:handler];
        }
    }];
}

@end



@implementation CLGeocoder (PMKDeprecated)

+ (AnyPromise *)reverseGeocode:(CLLocation *)location {
    return [[CLGeocoder new] reverseGeocode:location];
}

+ (AnyPromise *)geocode:(id)input {
    return [[CLGeocoder new] geocode:input];
}

@end
