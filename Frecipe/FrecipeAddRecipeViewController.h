//
//  FrecipeAddRecipeViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FrecipeAddRecipeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *recipeNameField;
@property (weak, nonatomic) IBOutlet UITextField *ingredientField;
@property (weak, nonatomic) IBOutlet UITextField *directionField;
@property (weak, nonatomic) IBOutlet UIButton *recipeImageButton;
@property (weak, nonatomic) IBOutlet UITableView *ingredientsTableView;
@property (weak, nonatomic) IBOutlet UITableView *directionsTableView;

@property (strong, nonatomic) NSString *editing;
@property (strong, nonatomic) NSString *recipeId;
@property (strong, nonatomic) NSMutableArray *ingredients;
@property (strong, nonatomic) NSMutableArray *directions;

@end
