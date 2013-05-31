//
//  UIView+Frecipe.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 16..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Frecipe)

- (void)setBackgroundImage:(UIImage *)image;
- (void)setShadowWithColor:(UIColor *)color Radius:(CGFloat)radius Offset:(CGSize)offset Opacity:(CGFloat)opacity;
- (void)setBasicShadow;
@end
