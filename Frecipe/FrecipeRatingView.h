//
//  FrecipeRatingView.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 29..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FrecipeRatingViewDelegate;

@interface FrecipeRatingView : UIView

@property (strong, nonatomic) id<FrecipeRatingViewDelegate> delegate;

@property (strong, nonatomic) UIButton *oneStarButton;
@property (strong, nonatomic) UIButton *twoStarButton;
@property (strong, nonatomic) UIButton *threeStarButton;
@property (strong, nonatomic) UIButton *fourStarButton;
@property (strong, nonatomic) UIButton *fiveStarButton;

@property (nonatomic, assign) NSInteger rating;
@property (nonatomic, assign) BOOL editable;
- (void)reset;

@end

@protocol FrecipeRatingViewDelegate 

- (void)ratingViewDidRate:(FrecipeRatingView *)ratingView rating:(NSInteger)rating;

@end
