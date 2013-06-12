//
//  FrecipeFunctions.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FrecipeFunctions : NSObject
+ (NSDateFormatter *)sharedDateFormatter;
+ (NSString *)currentDate;
+ (NSString *)compareWithCurrentDate:(NSString *)specifiedDate;


@end
