//
//  UIViewController+Frecipe.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 2..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "UIViewController+Frecipe.h"

@implementation UIViewController (Frecipe)

- (BOOL)isTall {
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    if (height == 568 || height == 1024) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isIpad {
    NSString *device = [[UIDevice currentDevice] model];
    
    return [device hasPrefix:@"iPad"];
}

- (BOOL)isIphone {
    NSString *device = [[UIDevice currentDevice] model];
    
    return [device hasPrefix:@"iPhone"];
}

@end
