#import "NSFileManager+PromiseKit.h"
#import "PromiseKit/Promise.h"


@implementation NSFileManager (PromiseKit)

- (PMKPromise *)removeItemAtPath:(NSString *)path {
    return dispatch_promise(^{
        id error = nil;
        [self removeItemAtPath:path error:&error];
        return error;
    });
}

- (PMKPromise *)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath {
    return dispatch_promise(^{
        id error = nil;
        [self copyItemAtPath:path toPath:toPath error:&error];
        return error;
    });
}

- (PMKPromise *)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath {
    return dispatch_promise(^{
        id error = nil;
        [self moveItemAtPath:path toPath:toPath error:&error];
        return error;
    });
}

- (PMKPromise *)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes {
    return dispatch_promise(^{
        id error = nil;
        [self createDirectoryAtPath:path withIntermediateDirectories:createIntermediates attributes:attributes error:&error];
        return error;
    });
}

@end
