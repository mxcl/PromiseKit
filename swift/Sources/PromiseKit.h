@import UIKit;

FOUNDATION_EXPORT double PromiseKitVersionNumber;
FOUNDATION_EXPORT const unsigned char PromiseKitVersionString[];

@import Foundation.NSDictionary;
@import Foundation.NSString;

void PMKRetain(id obj);
void PMKRelease(id obj);

NSString *PMKDictionaryToURLQueryString(NSDictionary *params);
