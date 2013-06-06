//
//  FrecipeTextField.m
//  Frecipe
//
//  Created by Hara Kang on 13. 6. 5..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeTextField.h"
#import <QuartzCore/QuartzCore.h>

@implementation FrecipeTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    self.layer.cornerRadius = 5.0f;
    self.clipsToBounds = YES;
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}


@end
