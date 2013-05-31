//
//  UIView+Frecipe.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 16..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "UIView+Frecipe.h"

@implementation UIView (Frecipe)

- (void)setBackgroundImage:(UIImage *)image {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
    imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    imageView.layer.cornerRadius = self.layer.cornerRadius;
    [self addSubview:imageView];
    [self sendSubviewToBack:imageView];
}

- (void)setShadowWithColor:(UIColor *)color Radius:(CGFloat)radius Offset:(CGSize)offset Opacity:(CGFloat)opacity {
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = color.CGColor;
    self.layer.shadowRadius = radius;
    self.layer.shadowOffset = offset;
    self.layer.shadowOpacity = opacity;
    self.layer.shadowPath = [[UIBezierPath bezierPathWithRect:self.bounds] CGPath];
//    self.layer.shouldRasterize = YES;
}

- (void)setBasicShadow {
    [self setShadowWithColor:[UIColor grayColor] Radius:2.0f Offset:CGSizeMake(0, 0) Opacity:0.9f];
}
@end
