//
//  FrecipeOperationQueue.h
//  Frecipe
//
//  Created by Hara Kang on 13. 6. 6..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FrecipeOperationQueue : NSOperationQueue
+ (FrecipeOperationQueue *)sharedQueue;
@end
