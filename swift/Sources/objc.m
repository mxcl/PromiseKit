@import Foundation;
@import ObjectiveC.runtime;


void *PMKManualReferenceAssociatedObject = &PMKManualReferenceAssociatedObject;


void PMKRetain(NSObject *obj) {
    objc_setAssociatedObject(obj, PMKManualReferenceAssociatedObject, obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void PMKRelease(NSObject *obj) {
    objc_setAssociatedObject(obj, PMKManualReferenceAssociatedObject, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


static NSArray *PMKQueryMagic(NSString *key, id value) {
    NSMutableArray *parts = [NSMutableArray new];

    // Sort dictionary keys to ensure consistent ordering in query string,
    // which is important when deserializing potentially ambiguous sequences,
    // such as an array of dictionaries
    #define sortDescriptor [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)]

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[sortDescriptor]]) {
            id recursiveKey = key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey;
            [parts addObjectsFromArray:PMKQueryMagic(recursiveKey, dictionary[nestedKey])];
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        for (id nestedValue in value)
            [parts addObjectsFromArray:PMKQueryMagic([NSString stringWithFormat:@"%@[]", key], nestedValue)];
    } else if ([value isKindOfClass:[NSSet class]]) {
        for (id obj in [value sortedArrayUsingDescriptors:@[sortDescriptor]])
            [parts addObjectsFromArray:PMKQueryMagic(key, obj)];
    } else
        [parts addObjectsFromArray:@[key, value]];

    return parts;

    #undef sortDescriptor
}

static inline NSString *enc(NSString *in) {
    return (__bridge_transfer  NSString *) CFURLCreateStringByAddingPercentEscapes(
               kCFAllocatorDefault,
               (__bridge CFStringRef)in.description,
               CFSTR("[]."),
               CFSTR(":/?&=;+!@#$()',*"),
               kCFStringEncodingUTF8);
}


NSString *PMKDictionaryToURLQueryString(NSDictionary *params) {
    NSMutableString *s = [NSMutableString new];
    if (!params) return s;
    NSEnumerator *e = PMKQueryMagic(nil, params).objectEnumerator;
    for (;;) {
        id obj = e.nextObject;
        if (!obj) break;
        [s appendFormat:@"%@=%@&", enc(obj), enc(e.nextObject)];
    }
    [s deleteCharactersInRange:NSMakeRange(s.length-1, 1)];
    return s;
}
