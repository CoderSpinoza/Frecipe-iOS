//
//  FrecipeFunctions.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeFunctions.h"

@implementation FrecipeFunctions

+ (NSString *)currentDate {
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc] init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *date = [formattedDate stringFromDate:[NSDate date]];
    return date;
}

+ (NSString *)compareWithCurrentDate:(NSString *)specifiedDate {
    NSMutableString *dateString = [NSMutableString stringWithString:specifiedDate];
    
    dateString = [[dateString stringByReplacingOccurrencesOfString:@"T" withString:@" "] mutableCopy];
    dateString = [[dateString stringByReplacingOccurrencesOfString:@"Z" withString:@""] mutableCopy];
    NSDateFormatter *localFormat = [[NSDateFormatter alloc] init];
    
    [localFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [localFormat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    NSDate *date = [localFormat dateFromString:dateString];
    
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:date];
    NSInteger timeInterval = (NSInteger)interval;
    
    NSInteger days = timeInterval / 86400;
    NSInteger hours = (timeInterval % 86400) / 3600;
    NSInteger minutes = (timeInterval % 86400 % 3600) / 60;
    NSInteger seconds = timeInterval % 86400 % 3600 % 60;
    
    if (days){
        [localFormat setDateFormat:@"LLL dd, yyyy, hh:mm a"];
        [localFormat setTimeZone:[NSTimeZone localTimeZone]];
        return [localFormat stringFromDate:date];
    } else if (hours) {
        return [NSString stringWithFormat:@"%d hours ago", hours];
    } else if (minutes) {
        return [NSString stringWithFormat:@"%d minutes ago", minutes];
    } else if (seconds) {
        return [NSString stringWithFormat:@"%d seconds ago", seconds];
    } else {
        return @"Just now";
    }
}


@end
