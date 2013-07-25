//
//  FrecipeAddIngredientsViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MLPAutoCompleteTextField/MLPAutoCompleteTextField.h>
#import <MLPAutoCompleteTextField/MLPAutoCompleteTextFieldDataSource.h>
#import <MLPAutoCompleteTextField/MLPAutoCompleteTextFieldDelegate.h>

@interface FrecipeAddIngredientsViewController : UIViewController
@property (weak, nonatomic) IBOutlet MLPAutoCompleteTextField *ingredientField;
@property (weak, nonatomic) IBOutlet UITableView *ingredientsTableView;

@end
