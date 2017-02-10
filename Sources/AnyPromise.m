#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/PromiseKit-Swift.h>


NSString *const PMKErrorDomain = @"PMKErrorDomain";



AnyPromise *PMKAfter(NSTimeInterval duration) {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC));
        dispatch_after(time, dispatch_get_global_queue(0, 0), ^{
            resolve(@(duration));
        });
    }];
}



#import <Foundation/NSMethodSignature.h>

struct PMKBlockLiteral {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;	// NULL
    	unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
    	void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
    	void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

typedef NS_OPTIONS(NSUInteger, PMKBlockDescriptionFlags) {
    PMKBlockDescriptionFlagsHasCopyDispose = (1 << 25),
    PMKBlockDescriptionFlagsHasCtor = (1 << 26), // helpers have C++ code
    PMKBlockDescriptionFlagsIsGlobal = (1 << 28),
    PMKBlockDescriptionFlagsHasStret = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    PMKBlockDescriptionFlagsHasSignature = (1 << 30)
};

// It appears 10.7 doesn't support quotes in method signatures. Remove them
// via @rabovik's method. See https://github.com/OliverLetterer/SLObjectiveCRuntimeAdditions/pull/2
#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8
NS_INLINE static const char * pmk_removeQuotesFromMethodSignature(const char *str){
    char *result = malloc(strlen(str) + 1);
    BOOL skip = NO;
    char *to = result;
    char c;
    while ((c = *str++)) {
        if ('"' == c) {
            skip = !skip;
            continue;
        }
        if (skip) continue;
        *to++ = c;
    }
    *to = '\0';
    return result;
}
#endif

static NSMethodSignature *NSMethodSignatureForBlock(id block) {
    if (!block)
        return nil;

    struct PMKBlockLiteral *blockRef = (__bridge struct PMKBlockLiteral *)block;
    PMKBlockDescriptionFlags flags = (PMKBlockDescriptionFlags)blockRef->flags;

    if (flags & PMKBlockDescriptionFlagsHasSignature) {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);

        if (flags & PMKBlockDescriptionFlagsHasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }

        const char *signature = (*(const char **)signatureLocation);
#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8
        signature = pmk_removeQuotesFromMethodSignature(signature);
        NSMethodSignature *nsSignature = [NSMethodSignature signatureWithObjCTypes:signature];
        free((void *)signature);

        return nsSignature;
#endif
        return [NSMethodSignature signatureWithObjCTypes:signature];
    }
    return 0;
}



#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSError.h>
#import <dispatch/once.h>
#import <string.h>

#ifndef PMKLog
#define PMKLog NSLog
#endif

@interface PMKArray : NSObject {
@public
    id objs[3];
    NSUInteger count;
} @end

@implementation PMKArray

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    if (count <= idx) {
        // this check is necessary due to lack of checks in `pmk_safely_call_block`
        return nil;
    }
    return objs[idx];
}

@end

id __PMKArrayWithCount(NSUInteger count, ...) {
    PMKArray *this = [PMKArray new];
    this->count = count;
    va_list args;
    va_start(args, count);
    for (NSUInteger x = 0; x < count; ++x)
        this->objs[x] = va_arg(args, id);
    va_end(args);
    return this;
}


static inline id _PMKCallVariadicBlock(id frock, id result) {
    NSCAssert(frock, @"");

    NSMethodSignature *sig = NSMethodSignatureForBlock(frock);
    const NSUInteger nargs = sig.numberOfArguments;
    const char rtype = sig.methodReturnType[0];

    #define call_block_with_rtype(type) ({^type{ \
        switch (nargs) { \
            case 1: \
                return ((type(^)(void))frock)(); \
            case 2: { \
                const id arg = [result class] == [PMKArray class] ? result[0] : result; \
                return ((type(^)(id))frock)(arg); \
            } \
            case 3: { \
                type (^block)(id, id) = frock; \
                return [result class] == [PMKArray class] \
                    ? block(result[0], result[1]) \
                    : block(result, nil); \
            } \
            case 4: { \
                type (^block)(id, id, id) = frock; \
                return [result class] == [PMKArray class] \
                    ? block(result[0], result[1], result[2]) \
                    : block(result, nil, nil); \
            } \
            default: \
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"PromiseKit: The provided block’s argument count is unsupported." userInfo:nil]; \
        }}();})

    switch (rtype) {
        case 'v':
            call_block_with_rtype(void);
            return nil;
        case '@':
            return call_block_with_rtype(id) ?: nil;
        case '*': {
            char *str = call_block_with_rtype(char *);
            return str ? @(str) : nil;
        }
        case 'c': return @(call_block_with_rtype(char));
        case 'i': return @(call_block_with_rtype(int));
        case 's': return @(call_block_with_rtype(short));
        case 'l': return @(call_block_with_rtype(long));
        case 'q': return @(call_block_with_rtype(long long));
        case 'C': return @(call_block_with_rtype(unsigned char));
        case 'I': return @(call_block_with_rtype(unsigned int));
        case 'S': return @(call_block_with_rtype(unsigned short));
        case 'L': return @(call_block_with_rtype(unsigned long));
        case 'Q': return @(call_block_with_rtype(unsigned long long));
        case 'f': return @(call_block_with_rtype(float));
        case 'd': return @(call_block_with_rtype(double));
        case 'B': return @(call_block_with_rtype(_Bool));
        case '^':
            if (strcmp(sig.methodReturnType, "^v") == 0) {
                call_block_with_rtype(void);
                return nil;
            }
            // else fall through!
        default:
            @throw [NSException exceptionWithName:@"PromiseKit" reason:@"PromiseKit: Unsupported method signature." userInfo:nil];
    }
}

static id PMKCallVariadicBlock(id frock, id result) {
    @try {
        return _PMKCallVariadicBlock(frock, result);
    } @catch (id reason) {
        if ([reason isKindOfClass:[NSError class]])
            return reason;
        if ([reason isKindOfClass:[NSString class]])
            return [NSError errorWithDomain:PMKErrorDomain code:PMKUnexpectedError userInfo:@{NSLocalizedDescriptionKey: reason}];

        @throw reason;
    }
}



@interface AnyPromise (Swift)
- (void)pipeTo:(void (^ __nonnull)(__nullable id))block;
@end


#define IsError(x) [x isKindOfClass:[NSError class]]


@implementation AnyPromise (ObjC)

#define __when(queue, test) \
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) { \
        return [self pipeTo:^(id obj){ \
            if (test(obj)) { \
                dispatch_async(queue, ^{ \
                    resolve(PMKCallVariadicBlock(block, obj)); \
                }); \
            } else { \
                resolve(obj); \
            } \
        }]; \
    }];

- (AnyPromise *(^)(id))then {
    return ^(id block) {
        return __when(dispatch_get_main_queue(), !IsError);
    };
}

- (AnyPromise *(^)(dispatch_queue_t, id))thenOn {
    return ^(dispatch_queue_t queue, id block) {
        return __when(queue, !IsError);
    };
}

- (AnyPromise *(^)(id))thenInBackground {
    return ^(id block) {
        return __when(dispatch_get_global_queue(0, 0), !IsError);
    };
}

- (AnyPromise *(^)(dispatch_block_t))ensure {
    return ^(dispatch_block_t block) {
        [self pipeTo:^(id __unused obj){
            dispatch_async(dispatch_get_main_queue(), block);
        }];
        return self;

    };
}

- (AnyPromise *(^)(dispatch_queue_t, dispatch_block_t))ensureOn {
    return ^(dispatch_queue_t queue, dispatch_block_t block) {
        [self pipeTo:^(id __unused obj){
            dispatch_async(queue, block);
        }];
        return self;
    };
}

- (AnyPromise *(^)(id))catch {
    return ^(id block) {
        return __when(dispatch_get_main_queue(), IsError);
    };
}

@end
