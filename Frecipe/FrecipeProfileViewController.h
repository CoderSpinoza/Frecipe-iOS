//
//  FrecipeProfileViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrecipeRatingView.h"
#import "FrecipeMainViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@interface FrecipeProfileViewController : FrecipeMainViewController
@property (strong, nonatomic) NSString *userId;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *fbProfilePictureView;
@property (weak, nonatomic) IBOutlet UIButton *followButton;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *detailInfoView;
@property (weak, nonatomic) IBOutlet UILabel *numOfRecipesTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *numOfRecipesButton;
@property (weak, nonatomic) IBOutlet UILabel *numOfFollowersTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *numOfFollowersButton;
@property (weak, nonatomic) IBOutlet UILabel *numOfLikesTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *numOfLikesButton;
@property (weak, nonatomic) IBOutlet UILabel *popularRecipeTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *popularRecipeButton;
@property (weak, nonatomic) IBOutlet UICollectionView *recipesCollectionView;
@property (weak, nonatomic) IBOutlet FrecipeRatingView *averageRatingView;

@property (nonatomic, assign) BOOL fromSegue;

@end
