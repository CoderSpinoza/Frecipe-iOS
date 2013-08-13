//
//  UICircle.h
//  Frecipe
//
//  Created by Hara Kang on 13. 7. 26..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICircle : UIView {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
}

@property (strong, nonatomic) UIColor *color;
@end
