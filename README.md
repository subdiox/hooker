# hooker
Function hooker (injector) for macOS

# Installation
Just add `hooker.h` and `hooker.m` to your Xcode project.

# Hooking
```objective-c
#import "hooker.h"

@interface Sample : NSObject<Hook>
@end

@implementation Sample
+ (NSArray)targetClasses {
    return @[@"SampleClass"];
}

- (void)hook_sampleMethod1 {
    NSLog(@"instance method 'sampleMethod1' is hooked!");
    [self orig_sampleMethod1];
    // do whatever you want
}

+ (id)hook_sampleMethod2 {
    NSLog(@"class method 'sampleMethod2' is hooked!");
    return [self orig_sampleMethod2];
}

- (void)orig_sampleMethod1 {}
+ (id)orig_sampleMethod2 {}
@end
```

# How to use after build
```console
$ DYLD_INSERT_LIBRARIES=(path to dylib file) (executable file)
```
