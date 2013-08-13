//
//  UICircle.m
//  Frecipe
//
//  Created by Hara Kang on 13. 7. 26..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "UICircle.h"

@implementation UICircle
@synthesize color = _color;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (UICircle *)circleWithColor:(UIColor *)color Radius:(CGFloat)radius {
    return [[self alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(ctx);
    
    [self.color getRed:&red green:&green blue:&blue alpha:nil];
    CGContextSetRGBFillColor(ctx, red, green, blue, 1.0f);  // white color
    CGContextFillEllipseInRect(ctx, CGRectMake(10.0f, 10.0f, 100.0f, 100.0f));  // a white filled circle with a diameter of 100 pixels, centered in (60, 60)
    UIGraphicsPopContext();
}


@end
