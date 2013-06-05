//
//  NSString+Frecipe.m
//  Frecipe
//
//  Created by Hara Kang on 13. 6. 4..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "NSString+Frecipe.h"

@implementation NSString (Frecipe)

- (BOOL)isEmail {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailPredicate evaluateWithObject:self];
}
@end
