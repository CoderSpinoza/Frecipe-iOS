//
//  FrecipeBadgeView.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 3..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeBadgeView.h"

@implementation FrecipeBadgeView
@synthesize text = _text;
@synthesize badgeTextColor = _badgeTextColor;
@synthesize badgeInsetColor = _badgeInsetColor;
@synthesize badgeFrameColor = _badgeFrameColor;
@synthesize cornerRadius = _cornerRadius;

- (void)setText:(NSString *)text {
    _text = text;
    if (text.length > 0) {
        [self resizeWithString:text];
    }
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.text = @"15";
        self.badgeTextColor = [UIColor whiteColor];
        self.badgeInsetColor = [UIColor redColor];
        self.badgeFrameColor = [UIColor whiteColor];
        self.cornerRadius = 0.4;
        [self resizeWithString:self.text];
    }
    return self;
    
}

- (id)initWithString:(NSString *)badgeText {
    self = [super initWithFrame:CGRectMake(0, 0, 25, 25)];
    if (self) {
        self.text = badgeText;
        self.badgeTextColor = [UIColor whiteColor];
        self.badgeInsetColor = [UIColor redColor];
        self.badgeFrameColor = [UIColor whiteColor];
        self.cornerRadius = 0.4;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (id)initWithString:(NSString *)text withStringColor:(UIColor *)stringColor withInsetColor:(UIColor *)insetColor withFrameColor:(UIColor *)frameColor {
    self = [super initWithFrame:CGRectMake(0, 0, 25, 25)];
    if (self) {
        self.text = text;
        self.badgeTextColor = stringColor;
        self.badgeInsetColor = insetColor;
        self.badgeFrameColor = frameColor;
        self.cornerRadius = 0.4;
    }
    return self;
}

+ (FrecipeBadgeView *)customBadgeWithString:(NSString *)text {
    return [[self alloc] initWithString:text];
}

+ (FrecipeBadgeView *)customBadgeWithString:(NSString *)text withStringColor:(UIColor *)stringColor withInsetColor:(UIColor *)insetColor withBadgeFrameColor:(UIColor *)frameColor {
    return [[self alloc] initWithString:text withStringColor:stringColor withInsetColor:insetColor withFrameColor:frameColor];
}

- (void)drawRoundedRectWithContext:(CGContextRef)context withRect:(CGRect)rect {
    CGContextSaveGState(context);
	
	CGFloat radius = CGRectGetMaxY(rect)*self.cornerRadius;
	CGFloat puffer = CGRectGetMaxY(rect)*0.10;
	CGFloat maxX = CGRectGetMaxX(rect) - puffer;
	CGFloat maxY = CGRectGetMaxY(rect) - puffer;
	CGFloat minX = CGRectGetMinX(rect) + puffer;
	CGFloat minY = CGRectGetMinY(rect) + puffer;
    
    CGContextBeginPath(context);
	CGContextSetFillColorWithColor(context, [self.badgeInsetColor CGColor]);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
	CGContextSetShadowWithColor(context, CGSizeMake(1.0,1.0), 3, [[UIColor blackColor] CGColor]);
    CGContextFillPath(context);
    
	CGContextRestoreGState(context);
}

- (void)drawFrameWithContext:(CGContextRef)context withRect:(CGRect)rect {
    CGFloat radius = CGRectGetMaxY(rect)*self.cornerRadius;
	CGFloat puffer = CGRectGetMaxY(rect)*0.10;
	
	CGFloat maxX = CGRectGetMaxX(rect) - puffer;
	CGFloat maxY = CGRectGetMaxY(rect) - puffer;
	CGFloat minX = CGRectGetMinX(rect) + puffer;
	CGFloat minY = CGRectGetMinY(rect) + puffer;
	
	
    CGContextBeginPath(context);
	CGFloat lineSize = 2;

	CGContextSetLineWidth(context, lineSize);
	CGContextSetStrokeColorWithColor(context, [self.badgeFrameColor CGColor]);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
	CGContextClosePath(context);
	CGContextStrokePath(context);

}

- (void)drawShineWithContext:(CGContextRef)context withRect:(CGRect)rect {
    CGContextSaveGState(context);
    
	CGFloat radius = CGRectGetMaxY(rect)*self.cornerRadius;
	CGFloat puffer = CGRectGetMaxY(rect)*0.10;
	CGFloat maxX = CGRectGetMaxX(rect) - puffer;
	CGFloat maxY = CGRectGetMaxY(rect) - puffer;
	CGFloat minX = CGRectGetMinX(rect) + puffer;
	CGFloat minY = CGRectGetMinY(rect) + puffer;
	CGContextBeginPath(context);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
	CGContextClip(context);
	
	
	size_t num_locations = 2;
	CGFloat locations[2] = { 0.0, 0.4 };
	CGFloat components[8] = {  0.92, 0.92, 0.92, 1.0, 0.82, 0.82, 0.82, 0.4 };
    
	CGColorSpaceRef cspace;
	CGGradientRef gradient;
	cspace = CGColorSpaceCreateDeviceRGB();
	gradient = CGGradientCreateWithColorComponents (cspace, components, locations, num_locations);
	
	CGPoint sPoint, ePoint;
	sPoint.x = 0;
	sPoint.y = 0;
	ePoint.x = 0;
	ePoint.y = maxY;
	CGContextDrawLinearGradient (context, gradient, sPoint, ePoint, 0);
	
	CGColorSpaceRelease(cspace);
	CGGradientRelease(gradient);
	
	CGContextRestoreGState(context);

}
- (void)resizeWithString:(NSString *)text {
    CGSize retValue;
	CGFloat rectWidth, rectHeight;
	CGSize stringSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:12]];
	CGFloat flexSpace;
	if ([text length]>=2) {
		flexSpace = [text length];
		rectWidth = 25 + (stringSize.width - 5);
        rectHeight = 25;
		retValue = CGSizeMake(rectWidth, rectHeight);
	} else {
		retValue = CGSizeMake(25, 25);
	}
	self.frame = CGRectMake(self.frame.origin.x - stringSize.width + 10, self.frame.origin.y, retValue.width, retValue.height);
	_text = text;
	[self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawRoundedRectWithContext:context withRect:rect];
    [self drawShineWithContext:context withRect:rect];
    [self drawFrameWithContext:context withRect:rect];
    if (self.text.length > 0) {
        [self.badgeTextColor set];
        CGFloat sizeOfFont = 13.5;
        UIFont *font = [UIFont boldSystemFontOfSize:sizeOfFont];
        CGSize textSize = [self.text sizeWithFont:font];
        [self.text drawAtPoint:CGPointMake((rect.size.width/2-textSize.width/2), (rect.size.height/2-textSize.height/2)) withFont:font];
    }
    
}


@end
