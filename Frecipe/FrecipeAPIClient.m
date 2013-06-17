//
//  FrecipeAPIClient.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeAPIClient.h"
#import "FrecipeAppDelegate.h"

@implementation FrecipeAPIClient

+ (FrecipeAPIClient *)client {
    NSString *url;
    if (PRODUCTION) {
        if (STAGING) {
            url = @"http://frecipe-staging.herokuapp.com";
        } else {
            url = @"http://frecipe.herokuapp.com";
        }
    } else {
        url = @"http://localhost:5000";
    }
    
    static FrecipeAPIClient *sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        
        sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:url]];
    });
    return sharedClient;
}


@end
