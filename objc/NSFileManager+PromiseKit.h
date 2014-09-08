#import <Foundation/NSFileManager.h>
#import <PromiseKit/fwd.h>


/**
 All operations are executed in a background thread. Often (but not
 always) these would be fast enough to run on the main thread, but the
 advantage of promises here is that any errors are propogated through
 your promise chain.
*/
@interface NSFileManager (PromiseKit)

- (PMKPromise *)removeItemAtPath:(NSString *)path;
- (PMKPromise *)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath;
- (PMKPromise *)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath;
- (PMKPromise *)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes;

@end
