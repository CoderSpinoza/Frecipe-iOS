//
//  FrecipeChangePasswordViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 31..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FrecipeChangePasswordViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *currentPasswordField;
@property (weak, nonatomic) IBOutlet UITextField *differentPasswordField;

@property (weak, nonatomic) IBOutlet UITextField *passwordConfirmationField;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

@end
