//
//  FrecipeUser.m
//  Frecipe
//
//  Created by Hara Kang on 13. 6. 18..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeUser.h"

@implementation FrecipeUser

+ (void)clearUserInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [defaults dictionaryRepresentation];
    for (NSString *key in dict) {
        [defaults removeObjectForKey:key];
    }
    [defaults synchronize];
}
@end
