//
//  hooker.m
//  hooker
//
//  Created by subdiox on 2018/11/16.
//  Copyright © 2018 subdiox. All rights reserved.
//

@import Foundation;
@import ObjectiveC.runtime;
@import MachO.dyld;
#import "hooker.h"

@interface Hooker : NSObject

@end

@implementation Hooker

#define HOOK_PREFIX @"hook_"
#define ORIG_PREFIX @"orig_"

+ (void)load {
    [self implementAllMethodHooks];
}


+ (void)implementAllMethodHooks {
    unsigned classCount;
    Class *classes = objc_copyClassList(&classCount);
    if (!classes) {
        NSLog(@"Error: Couldn't get class list");
        return;
    }
    
    Protocol *hookProtocol = @protocol(Hook);
    
    for (int index = 0; index < classCount; index += 1) {
        Class hookClass = classes[index];
        if (class_conformsToProtocol(hookClass, hookProtocol) == false) {
            continue;
        }
        [self implementHooksForClass:hookClass];
    }
    
    free(classes);
}

+ (void)implementHooksForClass:(Class)hookClass {
    const char *className = class_getName(hookClass);
    Class metaClass = hookClass;
    if (class_isMetaClass(metaClass) == FALSE && className != NULL) {
        Class potentialMetaClass = objc_getMetaClass(className);
        if (potentialMetaClass) {
            metaClass = potentialMetaClass;
        }
        
        NSArray *targetClasses = [hookClass targetClasses];
        
        for (NSString *targetClassName in targetClasses) {
            Class targetClass = NSClassFromString(targetClassName);
            if (!targetClass) {
                NSLog(@"Couldn't find target class %@", targetClassName);
                continue;
            }
            [self implementMethodHooksForClass:hookClass
                                    targetClass:targetClass];
        }
    }
}

+ (void)implementMethodHooksForClass:(Class)hookClass
                         targetClass:(Class)targetClass {
    unsigned int instanceMethodsCount;
    Method *instanceMethods = class_copyMethodList(hookClass, &instanceMethodsCount);
    if (!instanceMethods) {
        NSLog(@"Couldn't get instance method list for class: %s", class_getName(hookClass));
    } else {
        for (int methodIndex = 0; methodIndex < instanceMethodsCount; methodIndex += 1) {
            Method hookMethod = instanceMethods[methodIndex];
            if (!hookMethod) {
                continue;
            }
            
            SEL hookMethodSelector = method_getName(hookMethod);
            if (!hookMethodSelector) {
                continue;
            }
            
            NSString *hookMethodName = NSStringFromSelector(hookMethodSelector);
            if ([hookMethodName hasPrefix:HOOK_PREFIX] == FALSE) {
                if ([hookMethodName hasPrefix:ORIG_PREFIX] == FALSE) {
                    [self addMethodToClass:targetClass fromClass:hookClass method:hookMethod];
                }
                continue;
            }
            
            NSString *targetMethodName = [hookMethodName substringFromIndex:HOOK_PREFIX.length];
            SEL targetMethodSelector = NSSelectorFromString(targetMethodName);
            Method targetMethod = class_getInstanceMethod(targetClass, targetMethodSelector);
            
            if (!targetMethod) {
                NSLog(@"Error: Target class %s doesn't incorporate instance method %@",
                      class_getName(targetClass), targetMethodName);
                continue;
            }
            
            const char *targetTypeEncoding = method_getTypeEncoding(targetMethod);
            const char *hookedTypeEncoding = method_getTypeEncoding(hookMethod);
            if (strcmp(targetTypeEncoding, hookedTypeEncoding) != 0) {
                NSLog(@"Error: Not implementing hook: target type encoding %s doesn't match hook type encoding: %s for selector %s",
                      targetTypeEncoding, hookedTypeEncoding, sel_getName(targetMethodSelector));
                return;
            }
            
            IMP hookImplementation = method_getImplementation(hookMethod);
            if (!hookImplementation) {
                NSLog(@"Error: Couldn't get implementation for instance method %@", hookMethodName);
                continue;
            }
            
            NSString *originalStoreMethodName = [ORIG_PREFIX stringByAppendingString:targetMethodName];
            SEL originalStoreSelector = NSSelectorFromString(originalStoreMethodName);
            
            Method originalStoreMethod = class_getInstanceMethod(hookClass, originalStoreSelector);
            if (!originalStoreMethod) {
                class_getClassMethod(hookClass, originalStoreSelector);
            }
            
            IMP originalImplementation = method_getImplementation(targetMethod);
            if (!originalImplementation) {
                NSLog(@"Error: Couldn't get implementation for instance method %@", targetMethodName);
                continue;
            }
            
            if (originalStoreMethod) {
                class_addMethod(targetClass, originalStoreSelector, originalImplementation, targetTypeEncoding);
            }
            
            IMP previousImplementation = class_replaceMethod(targetClass, targetMethodSelector, hookImplementation, targetTypeEncoding);
            if (previousImplementation != NULL) {
                NSLog(@"Implemented hook for instance method [%s %@]", class_getName(targetClass), targetMethodName);
            } else {
                NSLog(@"Failed to implement hook for instance method [%s %@]", class_getName(targetClass), targetMethodName);
            }
        }
        free(instanceMethods);
    }
    
    unsigned int classMethodsCount;
    Method *classMethods = class_copyMethodList(object_getClass(hookClass), &classMethodsCount);
    if (!classMethods) {
        NSLog(@"Couldn't get class method list for class: %s", class_getName(hookClass));
    } else {
        for (int methodIndex = 0; methodIndex < classMethodsCount; methodIndex += 1) {
            Method hookMethod = classMethods[methodIndex];
            if (!hookMethod) {
                continue;
            }
            
            SEL hookMethodSelector = method_getName(hookMethod);
            if (!hookMethodSelector) {
                continue;
            }
            
            NSString *hookMethodName = NSStringFromSelector(hookMethodSelector);
            if ([hookMethodName hasPrefix:HOOK_PREFIX] == FALSE) {
                if ([hookMethodName hasPrefix:ORIG_PREFIX] == FALSE) {
                    [self addMethodToClass:targetClass fromClass:hookClass method:hookMethod];
                }
                continue;
            }
            
            NSString *targetMethodName = [hookMethodName substringFromIndex:HOOK_PREFIX.length];
            SEL targetMethodSelector = NSSelectorFromString(targetMethodName);
            Method targetMethod = class_getClassMethod(targetClass, targetMethodSelector);
            
            if (!targetMethod) {
                NSLog(@"Error: Target class %s doesn't incorporate class method %@",
                      class_getName(targetClass), targetMethodName);
                continue;
            }
            
            const char *targetTypeEncoding = method_getTypeEncoding(targetMethod);
            const char *hookedTypeEncoding = method_getTypeEncoding(hookMethod);
            if (strcmp(targetTypeEncoding, hookedTypeEncoding) != 0) {
                NSLog(@"Error: Not implementing hook: target type encoding %s doesn't match hook type encoding: %s for selector %s",
                      targetTypeEncoding, hookedTypeEncoding, sel_getName(targetMethodSelector));
                return;
            }
            
            IMP hookImplementation = method_getImplementation(hookMethod);
            if (!hookImplementation) {
                NSLog(@"Error: Couldn't get implementation for class method %@", hookMethodName);
                continue;
            }
            
            NSString *originalStoreMethodName = [ORIG_PREFIX stringByAppendingString:targetMethodName];
            SEL originalStoreSelector = NSSelectorFromString(originalStoreMethodName);
            
            Method originalStoreMethod = class_getInstanceMethod(hookClass, originalStoreSelector);
            if (!originalStoreMethod) {
                class_getClassMethod(hookClass, originalStoreSelector);
            }
            
            IMP originalImplementation = method_getImplementation(targetMethod);
            if (!originalImplementation) {
                NSLog(@"Error: Couldn't get implementation for class method %@", targetMethodName);
                continue;
            }
            
            if (originalStoreMethod) {
                class_addMethod(objc_getMetaClass(class_getName(targetClass)), originalStoreSelector, originalImplementation, targetTypeEncoding);
            }
            
            IMP previousImplementation = class_replaceMethod(object_getClass(targetClass), targetMethodSelector, hookImplementation, targetTypeEncoding);
            if (previousImplementation != NULL) {
                NSLog(@"Implemented hook for class method [%s %@]", class_getName(targetClass), targetMethodName);
            } else {
                NSLog(@"Failed to implement hook for class method [%s %@]", class_getName(targetClass), targetMethodName);
            }
        }
        free(classMethods);
    }
}

+ (void)addMethodToClass:(Class)targetClass fromClass:(Class)hookClass method:(Method)method {
    SEL selector = method_getName(method);
    const char *typeEncoding = method_getTypeEncoding(method);
    IMP implementation = method_getImplementation(method);
    class_addMethod(targetClass, selector, implementation, typeEncoding);
}

@end
