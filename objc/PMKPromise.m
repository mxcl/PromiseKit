#import <assert.h>
@import Dispatch.introspection;
@import Foundation.NSDictionary;
@import Foundation.NSError;
@import Foundation.NSException;
@import Foundation.NSKeyValueCoding;
@import Foundation.NSMethodSignature;
@import Foundation.NSOperation;
@import Foundation.NSPointerArray;
#import "Private/NSMethodSignatureForBlock.m"
#import "PromiseKit/Promise.h"
#import <string.h>

#define IsPromise(o) ([o isKindOfClass:[PMKPromise class]])
#define IsError(o) ([o isKindOfClass:[NSError class]])
#define PMKE(txt) [NSException exceptionWithName:@"PromiseKit" reason:@"PromiseKit: " txt userInfo:nil]

static const id PMKNull = @"PMKNull";

@interface PMKError : NSError
{ @public BOOL consumed; }
+ (instancetype):(id)foo;
@end

// deprecated
NSString const*const PMKThrown = PMKUnderlyingExceptionKey;



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

        #define null_to_nil(val) ({^id{ \
            return (val == [NSNull null]) ? nil : val; \
        }();})
        
        #define call_block_with_rtype(type) ({^type{ \
            switch (nargs) { \
                default:  @throw PMKE(@"Invalid argument count for handler block"); \
                case 1:   return ((type(^)(void))frock)(); \
                case 2: { \
                    type (^block)(id) = frock; \
                    return [result class] == [PMKArray class] \
                        ? block(null_to_nil(result[0])) \
                        : block(result); \
                } \
                case 3: { \
                    type (^block)(id, id) = frock; \
                    return [result class] == [PMKArray class] \
                        ? block(null_to_nil(result[0]), null_to_nil(result[1])) \
                        : block(result, nil); \
                } \
                case 4: { \
                    type (^block)(id, id, id) = frock; \
                    return [result class] == [PMKArray class] \
                        ? block(null_to_nil(result[0]), null_to_nil(result[1]), null_to_nil(result[2])) \
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
        return [PMKError:e];
    }
}



@implementation PMKPromise {
/**
 We have public @implementation instance variables so PMKResolve()
 can fulfill promises. Our usage is like the C++ `friend` keyword.
 */
@public
	dispatch_queue_t _promiseQueue;
    NSMutableArray *_handlers;
    id _result;
}

- (instancetype)init {
    @throw PMKE(@"init is not a valid initializer for PMKPromise");
    return nil;
}

#if OS_OBJECT_USE_OBJC == 0
- (void)dealloc {
    dispatch_release(_promiseQueue);
}
#endif

- (PMKPromise *(^)(id))then {
    return ^(id block){
        return self.thenOn(dispatch_get_main_queue(), block);
    };
}

- (PMKPromise *(^)(id))catch {
    return ^(id block){
        return self.catchOn(dispatch_get_main_queue(), block);
    };
}

- (PMKPromise *(^)(dispatch_block_t))finally {
    return ^(dispatch_block_t block) {
        return self.finallyOn(dispatch_get_main_queue(), block);
    };
}


typedef PMKPromise *(^PMKResolveOnQueueBlock)(dispatch_queue_t, id);
typedef void(^PMKResolveHandler)(id result, PMKPromise *next, dispatch_queue_t q, id block, PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter);

// This function generates the block that is returned from thenOn,
// catchOn and finallyOn. It takes a block that is called when the
// promise is resolved and one that is called in two cases where it is
// determined that the promise has already been resolved.
static PMKResolveOnQueueBlock PMKMakeCallback(PMKPromise *this, PMKResolveOnQueueBlock (^alreadyResolved)(id result), PMKResolveHandler whenResolved) {
    __block PMKPromise *(^callBlock)(dispatch_queue_t, id block);
    __block id result;
    
    dispatch_sync(this->_promiseQueue, ^{
        result = this->_result;
        
        if (result == nil) {
            callBlock = ^(dispatch_queue_t q, id block) {
                __block PMKPromise *next = nil;
                __block id promiseResult;

                // HACK we seem to expose some bug in ARC where this block can
                // be an NSStackBlock which then gets deallocated by the time
                // we get around to using it. So we force it to be malloc'd.
                block = [block copy];
                
                dispatch_barrier_sync(this->_promiseQueue, ^{
                    promiseResult = this->_result;
                    
                    if (promiseResult == nil) {
                        __block PMKPromiseFulfiller fulfiller;
                        __block PMKPromiseRejecter rejecter;
                        next = [PMKPromise new:^(PMKPromiseFulfiller fluff, PMKPromiseRejecter rejunk) {
                            fulfiller = fluff;
                            rejecter = rejunk;
                        }];
                        [this->_handlers addObject:^(id r){
                            whenResolved(r, next, q, block, fulfiller, rejecter);
                        }];
                    }
                });
                
                // This can still happen if the promise was resolved after
                // .thenOn read it and decided which block to return and the
                // call to the block.
                
                if (next == nil) {
                    next = alreadyResolved(promiseResult)(q, block);
                }
                
                return next;
            };
        }
    });
    
    if (callBlock == nil) {
        // We could just always return the above block, but then every caller would
        // trigger a barrier_sync on the promise queue. Instead, if we know that the
        // promise is resolved (since that makes it immutable), we can return a simpler
        // block that don't use a barrier in those cases.

        callBlock = alreadyResolved(result);
    }
    
    return callBlock;
}


- (PMKResolveOnQueueBlock)thenOn {
    return PMKMakeCallback(self, ^(id result){
        if (IsPromise(result)) {
            return ((PMKPromise *)result).thenOn;
        }
        
        if (IsError(result)) {
            return ^(dispatch_queue_t q, id block) {
                return [PMKPromise promiseWithValue:result];
            };
        }
        
        return ^(dispatch_queue_t q, id block) {
            return dispatch_promise_on(q, ^{   // don’t release Zalgo
                return safely_call_block(block, result);
            });
        };
    }, ^(id result, PMKPromise *next, dispatch_queue_t q, id block, PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
        if (IsError(result)) {
            PMKResolve(next, result);
        }
        else dispatch_async(q, ^{
            id rv = safely_call_block(block, result);
            if (IsError(rv))
                rejecter(rv);
            else
                fulfiller(rv);
        });
    });
}

- (PMKPromise *(^)(dispatch_queue_t, id))catchOn {
    return PMKMakeCallback(self, ^(id result){
        if (IsPromise(result)) {
            return ((PMKPromise *)result).catchOn;
        }
        
        if (IsError(result)) return ^(dispatch_queue_t q, id block) {
            return dispatch_promise_on(q, ^{   // don’t release Zalgo
                id rv = safely_call_block(block, result);
                if (rv != result) {
                    // if the handler rethrows the error, it is not consumed
                    ((PMKError *)result)->consumed = YES;
                }
                return rv;
            });
        };
        
        return ^(dispatch_queue_t q, id block) {
            return [PMKPromise promiseWithValue: result];
        };
    }, ^(id result, PMKPromise *next, dispatch_queue_t q, id block, PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
        if (IsError(result)) {
            dispatch_async(q, ^{
                id rv = safely_call_block(block, result);
                if (IsError(rv)) {
                    if (rv != result) ((PMKError *)result)->consumed = YES;
                    rejecter(rv);
                } else {
                    ((PMKError *)result)->consumed = YES;
                    fulfiller(rv);
                }
            });
        } else {
            PMKResolve(next, result);
        }
    });
}

- (PMKPromise *(^)(dispatch_queue_t, dispatch_block_t))finallyOn {
    return PMKMakeCallback(self, ^(id result){
        if (IsPromise(result))
            return ((PMKPromise *)result).finallyOn;
        
        return ^(dispatch_queue_t q, dispatch_block_t block) {
            return dispatch_promise_on(q, ^{
                block();
                return result;
            });
        };
    }, ^(id passthru, PMKPromise *next, dispatch_queue_t q, dispatch_block_t block, PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
        dispatch_async(q, ^{
            block();
            
            if (IsError(passthru))
                rejecter(passthru);
            else
                fulfiller(passthru);
        });
    });
}

+ (PMKPromise *)promiseWithValue:(id)value {
    PMKPromise *p = [PMKPromise alloc];
    p->_promiseQueue = PMKCreatePromiseQueue();
    p->_result = value ?: PMKNull;
    return p;
}

static dispatch_queue_t PMKCreatePromiseQueue() {
    return dispatch_queue_create("org.promiseKit.Q", DISPATCH_QUEUE_CONCURRENT);
}

static id PMKResult(PMKPromise *this) {
    __block id r;
    dispatch_sync(this->_promiseQueue, ^{
        r = this->_result;
    });
    return r;
}

static NSArray* PMKSetResult(PMKPromise *this, id result) {
    __block NSArray* handlers;
    
    dispatch_barrier_sync(this->_promiseQueue, ^{
        handlers = this->_handlers;
        this->_result = result;
        this->_handlers = nil;
    });
    
    return handlers;
}

static void PMKResolve(PMKPromise *this, id result) {
    __block id r = result ?: PMKNull;
    __block PMKPromise *rv = IsPromise(r) ? r : nil;
    
    if (rv) {
        dispatch_barrier_sync(rv->_promiseQueue, ^{
            id promiseValue = rv->_result;
            
            if (promiseValue == nil) {
                [rv->_handlers addObject:^(id o){
                    PMKResolve(this, o);
                }];
                r = nil;
            }
            else {
                r = promiseValue;
            }
        });
    }
    
    if (r) {
        NSArray* handlers = PMKSetResult(this, r);
        
        if (r == PMKNull) {
            r = nil;
        }
        
        for (void (^handler)(id) in handlers) {
            handler(r);
        }
    }
}

+ (PMKPromise *)new:(void(^)(PMKPromiseFulfiller, PMKPromiseRejecter))block {
    PMKPromise *this = [PMKPromise alloc];
    this->_promiseQueue = PMKCreatePromiseQueue();
    this->_handlers = [NSMutableArray new];

    id fulfiller = ^(id value){
        if (PMKResult(this))
            return NSLog(@"PromiseKit: Promise already resolved");
        if (IsError(value))
            @throw PMKE(@"You may not fulfill a Promise with an NSError");

        PMKResolve(this, value);
    };

    id rejecter = ^(id error){
        if (PMKResult(this))
            return NSLog(@"PromiseKit: Promise already resolved");
        if (IsPromise(error)) {
            if ([error rejected]) {
                error = ((PMKPromise *)error).value;
            } else
                @throw PMKE(@"You may not reject a Promise with a Promise");
        }
        if (!error)
            error = [PMKError errorWithDomain:PMKErrorDomain code:PMKUnknownError userInfo:nil];
        if (!IsError(error)) {
            NSLog(@"PromiseKit: Warning: Reject promises with NSErrors!");
            error = [PMKError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:@{
                NSLocalizedDescriptionKey: [error description]
            }];
        }

        PMKResolve(this, [PMKError:error]);
    };

    @try {
        block(fulfiller, rejecter);
    } @catch (id e) {
        PMKSetResult(this, [PMKError:e]);
    }

    return this;
}

- (BOOL)pending {
	id result = PMKResult(self);
    if (IsPromise(result)) {
        return [result pending];
    } else
        return result == nil;
}

- (BOOL)resolved {
    return PMKResult(self) != nil;
}

- (BOOL)fulfilled {
	id result = PMKResult(self);
    return result != nil && !IsError(result);
}

- (BOOL)rejected {
	id result = PMKResult(self);
    return result != nil && IsError(result);
}

- (id)value {
	id result = PMKResult(self);
    if (IsPromise(result))
        return [(PMKPromise *)result value];
    if (result == PMKNull)
        return nil;
    else
        return result;
}

- (NSString *)description {
    __block id result;
    __block NSUInteger handlerCount;
    dispatch_sync(_promiseQueue, ^{
        result = _result;
        handlerCount = _handlers.count;
    });
    
    BOOL pending = IsPromise(result) ? [result pending] : (result == nil);
    BOOL resolved = result != nil;
    BOOL fulfilled = resolved && !IsError(result);
    BOOL rejected = resolved && IsError(result);
    
    if (pending)
        return [NSString stringWithFormat:@"Promise: %lu pending handlers", (unsigned long)handlerCount];
    if (rejected)
        return [NSString stringWithFormat:@"Promise: rejected: %@", result];
    
    assert(fulfilled);
    
    return [NSString stringWithFormat:@"Promise: fulfilled: %@", result];
}

@end



PMKPromise *dispatch_promise(id block) {
    return dispatch_promise_on(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

PMKPromise *dispatch_promise_on(dispatch_queue_t queue, id block) {
    return [PMKPromise new:^(void(^fulfiller)(id), void(^rejecter)(id)){
        dispatch_async(queue, ^{
            id result = safely_call_block(block, nil);
            if (IsError(result))
                rejecter(result);
            else
                fulfiller(result);
        });
    }];
}



@implementation PMKArray { NSUInteger count; id objs[3]; }

+ (instancetype):(NSUInteger)count, ... {
    PMKArray *this = [self new];
    this->count = count;
    va_list args;
    va_start(args, count);
    for (NSUInteger x = 0; x < count; ++x)
        this->objs[x] = va_arg(args, id);
    va_end(args);
    return this;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
	if (count <= idx) {
        // this check is necessary due to lack of checks in `safely_call_block`
		return nil;
    }
    return objs[idx];
}

@end



@implementation PMKError

+ (instancetype):(id)foo {
    if ([foo isKindOfClass:[PMKError class]])
        return foo;
    if ([foo isKindOfClass:[NSError class]])
        return [PMKError errorWithDomain:[foo domain] ?: PMKErrorDomain code:[foo code] userInfo:[foo userInfo]];
    else {
        id userInfo = [NSMutableDictionary new];
        userInfo[PMKUnderlyingExceptionKey] = foo;
        userInfo[NSLocalizedDescriptionKey] = [foo isKindOfClass:[NSException class]]
                ? [foo reason]
                : [foo description];
        return [PMKError errorWithDomain:PMKErrorDomain code:PMKUnhandledExceptionError userInfo:userInfo];
    }
}

- (void)dealloc {
    if (!consumed)
        NSLog(@"PromiseKit: Unhandled error: %@", self);
}

@end



NSOperationQueue *PMKOperationQueue() {
    static NSOperationQueue *q;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        q = [NSOperationQueue new];
        q.name = @"org.promisekit.Q";
    });
    return q;
}



void *PMKManualReferenceAssociatedObject = &PMKManualReferenceAssociatedObject;
