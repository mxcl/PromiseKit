//
//  Created by merowing on 09/05/2014.
//
//
//

#import <PromiseKit/PromiseKit.h>
#import "SLRequest+AnyPromise.h"


@implementation SLRequest (PromiseKit)

- (AnyPromise *)promise {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {

            assert(![NSThread isMainThread]);

            if (error)
                return resolve(error);

            NSInteger const statusCode = urlResponse.statusCode;
            if (statusCode < 200 || statusCode >= 300) {
                id userInfo = [NSMutableDictionary new];
                userInfo[PMKURLErrorFailingURLResponseKey] = urlResponse;
                userInfo[NSLocalizedDescriptionKey] = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];

                if (responseData) {
                    id str = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    userInfo[PMKURLErrorFailingStringKey] = str;
                }

                resolve([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo]);
            }
            else if (PMKHTTPURLResponseIsJSON(urlResponse)) {
                id err = nil;
                id json = [NSJSONSerialization JSONObjectWithData:responseData options:PMKJSONDeserializationOptions error:&err];
                resolve(err ?: PMKManifold(json, urlResponse, responseData));
            } else {
                resolve(PMKManifold(responseData, urlResponse, responseData));
            }
        }];
    }];
}

@end
