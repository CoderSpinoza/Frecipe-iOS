//
//  TriangleView.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 10..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "TriangleView.h"

@implementation TriangleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGMutablePathRef path = CGPathCreateMutable();
    
    // add a triangle to the path
    CGContextMoveToPoint(context, 0, height);
    CGContextAddLineToPoint(context, width, height);
    CGContextAddLineToPoint(context, width / 2, 0);
    
    CGContextClosePath(context);
    
    CGContextAddPath(context, path);
    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:0.9 green:0.4 blue:0.4 alpha:0.9] CGColor]);
    CGContextFillPath(context);
    CGPathRelease(path);
}


@end
