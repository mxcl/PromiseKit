#if __has_include("PromiseKit-Swift.h")
    #import "PromiseKit-Swift.h"
#else
    #import <PromiseKit/PromiseKit-Swift.h>
#endif
#import "PMKCallVariadicBlock.m"
#import "AnyPromise+Private.h"
#import "AnyPromise.h"

NSString *const PMKErrorDomain = @"PMKErrorDomain";


@implementation AnyPromise {
    __AnyPromise *d;
}

- (instancetype)initWith__D:(__AnyPromise *)dd {
    self = [super init];
    if (self) self->d = dd;
    return self;
}

- (instancetype)initWithResolver:(PMKResolver __strong *)resolver {
    self = [super init];
    if (self)
        d = [[__AnyPromise alloc] initWithResolver:^(void (^resolve)(id)) {
            *resolver = resolve;
        }];
    return self;
}

+ (instancetype)promiseWithResolverBlock:(void (^)(PMKResolver _Nonnull))resolveBlock {
    id d = [[__AnyPromise alloc] initWithResolver:resolveBlock];
    return [[self alloc] initWith__D:d];
}

+ (instancetype)promiseWithValue:(id)value {
    //TODO provide a more efficient route for sealed promises
    id d = [[__AnyPromise alloc] initWithResolver:^(void (^resolve)(id)) {
        resolve(value);
    }];
    return [[self alloc] initWith__D:d];
}

//TODO remove if possible, but used by when.m
- (void)__pipe:(void (^)(id _Nullable))block {
    [d __pipe:block];
}

//NOTE used by AnyPromise.swift
- (id)__d {
    return d;
}

- (AnyPromise *(^)(id))then {
    return ^(id block) {
        return [self->d __thenOn:dispatch_get_main_queue() execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(dispatch_queue_t, id))thenOn {
    return ^(dispatch_queue_t queue, id block) {
        return [self->d __thenOn:queue execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(id))thenInBackground {
    return ^(id block) {
        return [self->d __thenOn:dispatch_get_global_queue(0, 0) execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(dispatch_queue_t, id))catchOn {
    return ^(dispatch_queue_t q, id block) {
        return [self->d __catchOn:q execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(id))catch {
    return ^(id block) {
        return [self->d __catchOn:dispatch_get_main_queue() execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(id))catchInBackground {
    return ^(id block) {
        return [self->d __catchOn:dispatch_get_global_queue(0, 0) execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(dispatch_block_t))ensure {
    return ^(dispatch_block_t block) {
        return [self->d __ensureOn:dispatch_get_main_queue() execute:block];
    };
}

- (AnyPromise *(^)(dispatch_queue_t, dispatch_block_t))ensureOn {
    return ^(dispatch_queue_t queue, dispatch_block_t block) {
        return [self->d __ensureOn:queue execute:block];
    };
}

- (id)wait {
    return [d __wait];
}

- (BOOL)pending {
    return [[d valueForKey:@"__pending"] boolValue];
}

- (BOOL)rejected {
    return IsError([d __value]);
}

- (BOOL)fulfilled {
    return !self.rejected;
}

- (id)value {
    id obj = [d __value];

    if ([obj isKindOfClass:[PMKArray class]]) {
        return obj[0];
    } else {
        return obj;
    }
}

@end



@implementation AnyPromise (Adapters)

+ (instancetype)promiseWithAdapterBlock:(void (^)(PMKAdapter))block {
    return [self promiseWithResolverBlock:^(PMKResolver resolve) {
        block(^(id value, id error){
            resolve(error ?: value);
        });
    }];
}

+ (instancetype)promiseWithIntegerAdapterBlock:(void (^)(PMKIntegerAdapter))block {
    return [self promiseWithResolverBlock:^(PMKResolver resolve) {
        block(^(NSInteger value, id error){
            if (error) {
                resolve(error);
            } else {
                resolve(@(value));
            }
        });
    }];
}

+ (instancetype)promiseWithBooleanAdapterBlock:(void (^)(PMKBooleanAdapter adapter))block {
    return [self promiseWithResolverBlock:^(PMKResolver resolve) {
        block(^(BOOL value, id error){
            if (error) {
                resolve(error);
            } else {
                resolve(@(value));
            }
        });
    }];
}

@end
