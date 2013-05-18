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
    [self addSubview:imageView];
    
    [self sendSubviewToBack:imageView];
}
@end
