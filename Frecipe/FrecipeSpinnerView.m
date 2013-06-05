//
//  FrecipeSpinnerView.m
//  Frecipe
//
//  Created by Hara Kang on 13. 6. 5..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeSpinnerView.h"
#import <QuartzCore/QuartzCore.h>

@implementation FrecipeSpinnerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    self.backgroundColor = [UIColor blackColor];
    self.alpha = 0.9;
    self.layer.cornerRadius = 5.0f;
    self.layer.masksToBounds = YES;
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 20)];
    self.label.textColor = [UIColor whiteColor];
    self.label.font = [UIFont boldSystemFontOfSize:14];
    self.label.backgroundColor = [UIColor clearColor];
    [self addSubview:self.spinner];
    [self addSubview:self.label];
    self.label.text = @"Loading";
    self.label.textAlignment = NSTextAlignmentCenter;
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code

    self.spinner.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    self.label.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2 + 35);
    
    
}


@end
