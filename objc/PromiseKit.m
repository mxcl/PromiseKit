#import "assert.h"
@import Dispatch.introspection;
@import Foundation.NSDictionary;
@import Foundation.NSError;
@import Foundation.NSException;
@import Foundation.NSKeyValueCoding;
@import Foundation.NSMethodSignature;
@import Foundation.NSPointerArray;
#import "Private/NSMethodSignatureForBlock.m"
#import "PromiseKit/Promise.h"
#import <pthread.h>

#define IsPromise(o) ([o isKindOfClass:[PMKPromise class]])
#define IsError(o) ([o isKindOfClass:[NSError class]])
#define PMKE(txt) [NSException exceptionWithName:@"PromiseKit" reason:@"PromiseKit: " txt userInfo:nil]

static const id PMKNull = @"PMKNull";

@interface PMKArray : NSObject
@end

// deprecated
NSString const*const PMKThrown = PMKUnderlyingExceptionKey;



static inline NSError *NSErrorWithThrown(id e) {
    id userInfo = [NSMutableDictionary new];
    userInfo[PMKUnderlyingExceptionKey] = e;
    if ([e isKindOfClass:[NSException class]])
        userInfo[NSLocalizedDescriptionKey] = [e reason];
    else
        userInfo[NSLocalizedDescriptionKey] = [e description];
    return [NSError errorWithDomain:PMKErrorDomain code:PMKErrorCodeThrown userInfo:userInfo];
}

/**
 *  Try to keep running on the same queue if possible
 */
static inline void dispatch_async_safe(dispatch_queue_t queue, void (^block)()){
    if (queue == dispatch_get_current_queue()) {
        block();
    }
    /**
     *  pthread_main_np is the fastest way to detect if we are on the main thread
     */
    else if(pthread_main_np() != 0 && dispatch_get_main_queue() == queue){
        block();
    }
    else{
        dispatch_async(queue, block);
    }
}

/**
 `then` and `catch` are method-signature tolerant, this function calls
 the block correctly and normalizes the return value to `id`.
 */
static id safely_call_block(id frock, id result) {
    if (!frock)
        @throw PMKE(@"Internal error");

    if (result == PMKNull)
        result = nil;

    @try {
        NSMethodSignature *sig = NSMethodSignatureForBlock(frock);
        const NSUInteger nargs = sig.numberOfArguments;
        const char rtype = sig.methodReturnType[0];

        #define call_block_with_rtype(type) ({^type{ \
            switch (nargs) { \
                default:  @throw PMKE(@"Invalid argument count for handler block"); \
                case 1:   return ((type(^)(void))frock)(); \
                case 2: { \
                    type (^block)(id) = frock; \
                    return [result class] == [PMKArray class] \
                        ? block(result[0]) \
                        : block(result); \
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
            }}();})

        switch (rtype) {
            case 'v':
                call_block_with_rtype(void);
                return PMKNull;
            case '@':
                return call_block_with_rtype(id) ?: PMKNull;
            case '*': {
                char *str = call_block_with_rtype(char *);
                return str ? @(str) : PMKNull;
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
                    return PMKNull;
                }
                // else fall through!
            default:
                @throw PMKE(@"Unsupported method signature… Why not fork and fix?");
        }
    } @catch (id e) {
      #ifdef PMK_RETHROW_LIKE_A_MOFO
        if ([e isKindOfClass:[NSException class]] && (
            [e name] == NSGenericException ||
            [e name] == NSRangeException ||
            [e name] == NSInvalidArgumentException ||
            [e name] == NSInternalInconsistencyException ||
            [e name] == NSObjectInaccessibleException ||
            [e name] == NSObjectNotAvailableException ||
            [e name] == NSDestinationInvalidException ||
            [e name] == NSPortTimeoutException ||
            [e name] == NSInvalidSendPortException ||
            [e name] == NSInvalidReceivePortException ||
            [e name] == NSPortSendException ||
            [e name] == NSPortReceiveException))
                @throw e;
      #endif
        return [e isKindOfClass:[NSError class]] ? e : NSErrorWithThrown(e);
    }
}



@implementation PMKPromise {
/**
 We have public @implementation instance variables so PMKResolve
 can fulfill promises. Our usage is like the C++ `friend` keyword.
 */
@public
    NSMutableArray *handlers;
    id result;
}

- (instancetype)init {
    @throw PMKE(@"init is not a valid initializer for PMKPromise");
    return nil;
}

- (void)dealloc {
    if (!result && handlers.count)
        NSLog(@"PromiseKit: Promise about to be deallocated before it has been resolved! This is likely a bug and you are likely to crash. @see https://github.com/mxcl/PromiseKit/issues/50");
}

- (PMKPromise *(^)(id))then {
    return ^(id block){
        return self.thenOn(dispatch_get_main_queue(), block);
    };
}

- (PMKPromise *(^)(dispatch_queue_t, id))thenOn {
    if (IsPromise(result))
        return ((PMKPromise *)result).thenOn;

    if ([result isKindOfClass:[NSError class]])
        return ^(dispatch_queue_t q, id b){
            return [PMKPromise promiseWithValue:result];
        };

    if (result) return ^(dispatch_queue_t q, id block) {
        return dispatch_promise_on(q, ^{   // don’t release Zalgo
            return safely_call_block(block, result);
        });
    };

    return ^(dispatch_queue_t q, id block){
        __block PMKPromiseFulfiller fulfiller;
        __block PMKPromiseRejecter rejecter;
        PMKPromise *next = [PMKPromise new:^(PMKPromiseFulfiller fluff, PMKPromiseRejecter rejunk) {
            fulfiller = fluff;
            rejecter = rejunk;
        }];
        [handlers addObject:^(id selfDotResult){
            if (IsError(selfDotResult)) {
                next->result = selfDotResult;
                PMKResolve(next);
            }
            else dispatch_async_safe(q, ^{
                id rv = safely_call_block(block, selfDotResult);
                if (IsError(rv))
                    rejecter(rv);
                else
                    fulfiller(rv);
            });
        }];
        return next;
    };
}

- (PMKPromise *(^)(id))catch {
    if (IsPromise(result))
        return ((PMKPromise *)result).catch;

    if (IsError(result)) return ^(id block) {
        return dispatch_promise_on(dispatch_get_main_queue(), ^{   // don’t release Zalgo
            return safely_call_block(block, result);
        });
    };

    if (result) return ^id(id block){
        return [PMKPromise promiseWithValue:result];
    };

    return ^(id block){
        __block PMKPromiseFulfiller fulfiller;
        __block PMKPromiseRejecter rejecter;
        PMKPromise *next = [PMKPromise new:^(PMKPromiseFulfiller fluff, PMKPromiseRejecter rejunk) {
            fulfiller = fluff;
            rejecter = rejunk;
        }];
        [handlers addObject:^(id selfDotResult){
            if (IsError(selfDotResult)) {
                dispatch_async_safe(dispatch_get_main_queue(), ^{
                    id rv = safely_call_block(block, selfDotResult);
                    if (IsError(rv))
                        rejecter(rv);
                    else if (rv)
                        fulfiller(rv);
                });
            } else {
                next->result = selfDotResult;
                PMKResolve(next);
            }
        }];
        return next;
    };
}

- (PMKPromise *(^)(void(^)(void)))finally {
    if (IsPromise(result))
        return ((PMKPromise *)result).finally;

    if (result) return ^(void (^block)(void)) {
        return dispatch_promise_on(dispatch_get_main_queue(), ^{
            block();
            return result;
        });
    };

    return ^(void (^block)(void)){
        __block PMKPromiseFulfiller fulfiller;
        __block PMKPromiseRejecter rejecter;
        PMKPromise *next = [PMKPromise new:^(PMKPromiseFulfiller fluff, PMKPromiseRejecter rejunk) {
            fulfiller = fluff;
            rejecter = rejunk;
        }];
        [handlers addObject:^(id passthru){
            dispatch_async_safe(dispatch_get_main_queue(), ^{
                block();
                if (IsError(passthru))
                    rejecter(passthru);
                else
                    fulfiller(passthru);
            });
        }];
        return next;
    };
}

+ (PMKPromise *)all:(id<NSFastEnumeration, NSObject>)promises {
    __block NSUInteger count = [(id)promises count];  // FIXME
    
    if (count == 0)
        return [PMKPromise promiseWithValue:@[]];

    #define rejecter(key) ^(NSError *err){ \
        id userInfo = err.userInfo.mutableCopy; \
        userInfo[PMKFailingPromiseIndexKey] = key; \
        err = [NSError errorWithDomain:err.domain code:err.code userInfo:userInfo]; \
        rejecter(err); \
    }

    if ([promises isKindOfClass:[NSDictionary class]])
        return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
            NSMutableDictionary *results = [NSMutableDictionary new];
            for (id key in promises) {
                PMKPromise *promise = promises[key];
                if (!IsPromise(promise))
                    promise = [PMKPromise promiseWithValue:promise];
                promise.catch(rejecter(key));
                promise.then(^(id o){
                    if (o)
                        results[key] = o;
                    if (--count == 0)
                        fulfiller(results);
                });
            }
        }];

    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:count];

        NSUInteger ii = 0;

        for (__strong PMKPromise *promise in promises) {
            [results addObject:[NSNull null]];

            if (!IsPromise(promise))
                promise = [PMKPromise promiseWithValue:promise];
            promise.catch(rejecter(@(ii)));
            promise.then(^(id o){
                [results replaceObjectAtIndex:ii withObject:(o ?: [NSNull null])];
                if (--count == 0)
                    fulfiller(results);
            });
            ii++;
        }
    }];

    #undef rejecter
}

+ (PMKPromise *)when:(id)promises {
    if ([promises conformsToProtocol:@protocol(NSFastEnumeration)]) {
        return [self all:promises];
    } else {
        return [self all:@[promises]].then(^(NSArray *values){
            return values[0];
        });
    }
}

+ (PMKPromise *)until:(id (^)(void))blockReturningPromises catch:(id)failHandler
{
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Warc-retain-cycles"

    return [PMKPromise new:^(void(^fulfiller)(id), id rejecter){
        __block void (^block)() = ^{
            id promises = blockReturningPromises();
            [self when:promises].then(^(id o){
                fulfiller(o);
                block = nil;  // break retain cycle
            }).catch(^(id e){
                PMKPromise *rv = safely_call_block(failHandler, e);
                if ([rv isKindOfClass:[PMKPromise class]])
                    rv.then(block);
                else if (![rv isKindOfClass:[NSError class]])
                    block();
            });
        };
        block();
    }];

  #pragma clang diagnostic pop
}


+ (PMKPromise *)promiseWithValue:(id)value {
    PMKPromise *p = [PMKPromise alloc];
    p->result = value ?: PMKNull;
    return p;
}


static void PMKResolve(PMKPromise *this) {
    id const value = ({
        PMKPromise *rv = this->result;
        if (IsPromise(rv) && !rv.pending)
            rv = rv.value ?: PMKNull;
        rv;
    });

    if (IsPromise(value)) {
        PMKPromise *rsvp = (PMKPromise *)value;
        [rsvp->handlers addObject:^(id o){
            this->result = o;
            PMKResolve(this);
        }];
    } else {
        for (void (^handler)(id) in this->handlers)
            handler(value);
        this->handlers = nil;
    }
}


+ (PMKPromise *)new:(void(^)(PMKPromiseFulfiller, PMKPromiseRejecter))block {
    PMKPromise *this = [PMKPromise alloc];
    this->handlers = [NSMutableArray new];

    id fulfiller = ^(id value){
        if (this->result)
            return NSLog(@"PromiseKit: Promise already resolved");
        if (IsError(value))
            @throw PMKE(@"You may not fulfill a Promise with an NSError");
        if (!value)
            value = PMKNull;

        this->result = value;
        PMKResolve(this);
    };

    id rejecter = ^(id error){
        if (this->result)
            return NSLog(@"PromiseKit: Promise already resolved");
        if (IsPromise(error)) {
            if ([error rejected]) {
                error = ((PMKPromise *)error).value;
            } else
                @throw PMKE(@"You may not reject a Promise with a Promise");
        }
        if (!error)
            error = [NSError errorWithDomain:PMKErrorDomain code:PMKErrorCodeUnknown userInfo:nil];
        if (![error isKindOfClass:[NSError class]]) {
            NSLog(@"PromiseKit: Warning, you should reject with proper NSError objects!");
            error = [NSError errorWithDomain:PMKErrorDomain code:PMKErrorCodeInvalidUsage userInfo:@{
                NSLocalizedDescriptionKey: [error description]
            }];
        }

        this->result = error;
        PMKResolve(this);
    };

    @try {
        block(fulfiller, rejecter);
    } @catch (id e) {
        this->result = [e isKindOfClass:[NSError class]] ? e : NSErrorWithThrown(e);
    }

    return this;
}

- (BOOL)pending {
    if (IsPromise(result)) {
        return [result pending];
    } else
        return result == nil;
}

- (BOOL)resolved {
    return result != nil;
}

- (BOOL)fulfilled {
    return self.resolved && ![result isKindOfClass:[NSError class]];
}

- (BOOL)rejected {
    return self.resolved && [result isKindOfClass:[NSError class]];
}

- (id)value {
    if (IsPromise(result))
        return [(PMKPromise*)result value];
    if (result == PMKNull)
        return nil;
    else
        return result;
}

- (NSString *)description {
    if (self.pending)
        return [NSString stringWithFormat:@"Promise: %lu pending handlers", (unsigned long)handlers.count];
    if (self.rejected)
        return [NSString stringWithFormat:@"Promise: rejected: %@", result];

    assert(self.fulfilled);

    return [NSString stringWithFormat:@"Promise: fulfilled: %@", result];
}

@end



PMKPromise *dispatch_promise(id block) {
    return dispatch_promise_on(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

PMKPromise *dispatch_promise_on(dispatch_queue_t queue, id block) {
    return [PMKPromise new:^(void(^fulfiller)(id), void(^rejecter)(id)){
        dispatch_async_safe(queue, ^{
            id result = safely_call_block(block, nil);
            if ([result isKindOfClass:[NSError class]])
                rejecter(result);
            else
                fulfiller(result);
        });
    }];
}



@implementation PMKArray
{ @public NSArray *objs; }

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return objs.count >= idx+1 ? objs[idx] : nil;
}

@end



#undef PMKManifold

id PMKManifold(NSArray *args) {
    PMKArray *aa = [PMKArray new];
    aa->objs = args;
    return aa;
}
