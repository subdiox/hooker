# hooker
Function hooker (injector) for macOS

# Hooking
```objective-c
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

+ (NSInteger)hook_sampleMethod2 {
    NSLog(@"class method 'sampleMethod2' is hooked!");
    return [self orig_sampleMethod2];
}

- (void)orig_sampleMethod1 {}
+ (NSInteger)orig_sampleMethod2 {}
@end
```

# How to use after build
DYLD_INSERT_LIBRARIES=(path to dylib file) (executable file)
