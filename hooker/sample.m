//
//  sample.m
//  hooker
//
//  Created by subdiox on 2018/11/16.
//  Copyright © 2018 subdiox. All rights reserved.
//

#import "sample.h"

@implementation Sample

+ (NSArray *)targetClasses {
    return @[@"UIViewController"];
}

- (void)hook_viewDidLoad {
    [self orig_viewDidLoad];
    NSLog(@"viewDidLoad is called");
}

// MARK: - Placeholders

- (void)orig_viewDidLoad { }

@end
