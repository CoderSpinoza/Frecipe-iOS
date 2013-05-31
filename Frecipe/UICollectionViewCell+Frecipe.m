//
//  UICollectionViewCell+Frecipe.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 20..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "UICollectionViewCell+Frecipe.h"

@implementation UICollectionViewCell (Frecipe)

- (void)startShaking {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.duration = 0.1;
    animation.repeatCount = 4;
    animation.autoreverses = YES;
    animation.fromValue = [NSValue valueWithCGPoint:
                           CGPointMake(self.center.x - 3.0f, self.center.y)];
    animation.toValue = [NSValue valueWithCGPoint:
                         CGPointMake(self.center.x + 3.0f, self.center.y)];
    [self.layer addAnimation:animation forKey:@"position"];
}

@end
