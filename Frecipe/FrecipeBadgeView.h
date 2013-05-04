//
//  FrecipeBadgeView.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 3..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
@interface FrecipeBadgeView : UIView

@property (strong, nonatomic) NSString *text;
@property(strong, nonatomic) UIColor *badgeTextColor;
@property(strong, nonatomic) UIColor *badgeInsetColor;
@property(strong, nonatomic) UIColor *badgeFrameColor;
@property (nonatomic, assign) CGFloat cornerRadius;

+ (FrecipeBadgeView *) customBadgeWithString:(NSString *)badgeString;
+ (FrecipeBadgeView *) customBadgeWithString:(NSString *)text withStringColor:(UIColor*)stringColor withInsetColor:(UIColor*)insetColor  withBadgeFrameColor:(UIColor*)frameColor;
- (void) resizeWithString:(NSString *)badgeString;

@end
