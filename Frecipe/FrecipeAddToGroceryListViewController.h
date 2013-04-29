//
//  FrecipeAddToGroceryListViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FrecipeAddToGroceryListViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *groceryField;
@property (weak, nonatomic) IBOutlet UITableView *groceryListTableView;

@end
