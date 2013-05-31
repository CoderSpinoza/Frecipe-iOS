//
//  FrecipeGroceryListViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrecipeMainViewController.h"

@interface FrecipeGroceryListViewController : FrecipeMainViewController

@property (weak, nonatomic) IBOutlet UICollectionView *recipesCollectionView;
@property (weak, nonatomic) IBOutlet UITableView *groceryListTableView;
@property (weak, nonatomic) IBOutlet UIView *groceryListView;
@property (weak, nonatomic) IBOutlet UILabel *recipeNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *trashButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteRecipesButton;
@end
