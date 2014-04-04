@import Foundation.NSArray;
@import Foundation.NSError;
@import Foundation.NSObject;
@class Promise;


@interface Deferred : NSObject
- (void)resolve:(id)obj;
- (void)reject:(id)error;

@property (nonatomic, readonly) Promise *promise;
@end
