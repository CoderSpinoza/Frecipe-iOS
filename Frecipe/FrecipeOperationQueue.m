//
//  FrecipeOperationQueue.m
//  Frecipe
//
//  Created by Hara Kang on 13. 6. 6..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeOperationQueue.h"

@implementation FrecipeOperationQueue

+ (FrecipeOperationQueue *)sharedQueue {
    static FrecipeOperationQueue *sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = [[FrecipeOperationQueue alloc] init];
    });
    return sharedQueue;
}

@end
