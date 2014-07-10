//
//  ClassSwizzling.h
//  Aluxoft SCP
//
//  Created by Josejulio Martínez on 18/06/14.
//  Copyright (c) 2014 Josejulio Martínez. All rights reserved.
//

#import <objc/runtime.h>
#import <string.h>
#import <Foundation/NSString.h>

static __attribute__((unused)) void swizzleClass(const char* classPrefix, id target, SEL originalSelector, SEL swizzledSelector) {
    Class klass = [target class];
    NSString* className = NSStringFromClass(klass);
    
    if (strncmp(classPrefix, [className UTF8String], strlen(classPrefix)) != 0) {
        NSString* subclassName = [NSString stringWithFormat:@"%s%@", classPrefix, className];
        Class subclass = NSClassFromString(subclassName);
        if (subclass == nil) {
            subclass = objc_allocateClassPair(klass, [subclassName UTF8String], 0);
            if (subclass != nil) {
                Method originalMethod = class_getInstanceMethod(klass, originalSelector);
                Method swizzledMethod = class_getInstanceMethod(klass, swizzledSelector);
                method_exchangeImplementations(originalMethod, swizzledMethod);
                objc_registerClassPair(subclass);
            }
        }
        if (subclass != nil) {
            object_setClass(target, subclass);
        }
    }
}
