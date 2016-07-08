@import Foundation;
@import XCTest;

__attribute__((objc_runtime_name("PMKInjected")))
__attribute__((objc_subclassing_restricted))
@interface Injected: NSObject
+ (void)setErrorUnhandler:(void(^)(NSError *))newErrorUnhandler;
+ (void)setUp;
@end

#define PMKTestErrorDomain @"PMKTestErrorDomain"
