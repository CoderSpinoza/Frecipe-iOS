//
//  FrecipeRecipeDetailViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrecipeRatingView.h"

@interface FrecipeRecipeDetailViewController : UIViewController

@property (strong, nonatomic) NSString *recipeId;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UIButton *likesButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIImageView *recipeImageView;
@property (weak, nonatomic) IBOutlet UILabel *ingredientsLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionsLabel;
@property (weak, nonatomic) IBOutlet UITableView *ingredientsTableView;
@property (weak, nonatomic) IBOutlet UITableView *directionsTableView;
@property (weak, nonatomic) IBOutlet UIView *ratingBorderView;
@property (weak, nonatomic) IBOutlet FrecipeRatingView *ratingView;
@property (weak, nonatomic) IBOutlet FrecipeRatingView *averageRatingView;
@end
