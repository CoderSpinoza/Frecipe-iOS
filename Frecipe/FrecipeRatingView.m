//
//  FrecipeRatingView.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 29..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeRatingView.h"

@implementation FrecipeRatingView
@synthesize oneStarButton = _oneStarButton;
@synthesize twoStarButton = _twoStarButton;
@synthesize threeStarButton = _threeStarButton;
@synthesize fourStarButton = _fourStarButton;
@synthesize fiveStarButton = _fiveStarButton;
@synthesize rating = _rating;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        NSLog(@"frame");
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _oneStarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _twoStarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _threeStarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _fourStarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _fiveStarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        _oneStarButton.tag = 1;
        _twoStarButton.tag = 2;
        _threeStarButton.tag = 3;
        _fourStarButton.tag = 4;
        _fiveStarButton.tag = 5;
        
        [_oneStarButton setImage:[UIImage imageNamed:@"star_empty.png"] forState:UIControlStateNormal];
        [_oneStarButton setImage:[UIImage imageNamed:@"star_full.png"] forState:UIControlStateSelected];
        [_twoStarButton setImage:[UIImage imageNamed:@"star_empty.png"] forState:UIControlStateNormal];
        [_twoStarButton setImage:[UIImage imageNamed:@"star_full.png"] forState:UIControlStateSelected];
        [_threeStarButton setImage:[UIImage imageNamed:@"star_empty.png"] forState:UIControlStateNormal];
        [_threeStarButton setImage:[UIImage imageNamed:@"star_full.png"] forState:UIControlStateSelected];
        [_fourStarButton setImage:[UIImage imageNamed:@"star_empty.png"] forState:UIControlStateNormal];
        [_fourStarButton setImage:[UIImage imageNamed:@"star_full.png"] forState:UIControlStateSelected];
        [_fiveStarButton setImage:[UIImage imageNamed:@"star_empty.png"] forState:UIControlStateNormal];
        [_fiveStarButton setImage:[UIImage imageNamed:@"star_full.png"] forState:UIControlStateSelected];
        
        [_oneStarButton addTarget:self action:@selector(tapStarButton:) forControlEvents:UIControlEventTouchUpInside];
        [_twoStarButton addTarget:self action:@selector(tapStarButton:) forControlEvents:UIControlEventTouchUpInside];
        [_threeStarButton addTarget:self action:@selector(tapStarButton:) forControlEvents:UIControlEventTouchUpInside];
        [_fourStarButton addTarget:self action:@selector(tapStarButton:) forControlEvents:UIControlEventTouchUpInside];
        [_fiveStarButton addTarget:self action:@selector(tapStarButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_oneStarButton];
        [self addSubview:_twoStarButton];
        [self addSubview:_threeStarButton];
        [self addSubview:_fourStarButton];
        [self addSubview:_fiveStarButton];
        
        self.editable = YES;
        
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGFloat height = self.frame.size.height;
    CGFloat width = self.frame.size.width / 9;

    _oneStarButton.frame = CGRectMake(0, 0, width, height);
    _twoStarButton.frame = CGRectMake(width * 2, 0, width, height);
    _threeStarButton.frame = CGRectMake(width * 4, 0, width, height);
    _fourStarButton.frame = CGRectMake(width * 6, 0, width, height);
    _fiveStarButton.frame = CGRectMake(width * 8, 0, width, height);
}

- (void)reset {
    self.oneStarButton.selected = NO;
    self.twoStarButton.selected = NO;
    self.threeStarButton.selected = NO;
    self.fourStarButton.selected = NO;
    self.fiveStarButton.selected = NO;
    self.rating = 0;
}

- (void)setRating:(NSInteger)rating {
    self.oneStarButton.selected = rating >= self.oneStarButton.tag;
    self.twoStarButton.selected = rating >= self.twoStarButton.tag;
    self.threeStarButton.selected = rating>= self.threeStarButton.tag;
    self.fourStarButton.selected = rating >= self.fourStarButton.tag;
    self.fiveStarButton.selected = rating >= self.fiveStarButton.tag;
    
    _rating = rating;
}

- (void)tapStarButton:(UIButton *)button {
    
    if (self.editable) {
        self.rating = button.tag;
    }    
    [self.delegate ratingViewDidRate:self rating:self.rating];
}

@end
