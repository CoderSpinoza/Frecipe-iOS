//
//  FrecipeAddIngredientsViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FrecipeAddIngredientsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *ingredientField;
@property (weak, nonatomic) IBOutlet UITableView *ingredientsTableView;

@end
