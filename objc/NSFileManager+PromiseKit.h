#import <Foundation/NSFileManager.h>
#import <PromiseKit/fwd.h>


/**
 All operations are executed in a background thread. Often (but not
 always) these would be fast enough to run on the main thread, but a
 further advantage of promises here is that any errors are propogated
 through your promise chain.
*/
@interface NSFileManager (PromiseKit)

/// @see [NSFileManager removeItemAtPath:]
- (PMKPromise *)removeItemAtPath:(NSString *)path;
/// @see [NSFileManager copyItemAtPath:toPath]
- (PMKPromise *)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath;
/// @see [NSFileManager moveItemAtPath:toPath]
- (PMKPromise *)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath;
/// @see [NSFileManager createDirectoryAtPath:withIntermediateDirectories:attributes:]
- (PMKPromise *)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes;

@end
