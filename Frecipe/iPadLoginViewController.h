//
//  iPadLoginViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 13..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iPadLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *frecipeLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *loginWithFacebookButton;
@property (weak, nonatomic) IBOutlet UILabel *orLabel;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@end
