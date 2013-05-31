//
//  FrecipeEditProfileViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 24..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
@interface FrecipeEditProfileViewController : UIViewController

@property (strong, nonatomic) NSDictionary *user;
@property (strong, nonatomic) NSString *profilePictureUrl;

@property (weak, nonatomic) IBOutlet FBProfilePictureView *fbProfilePictureView;

@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;

@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;

@property (weak, nonatomic) IBOutlet UITextField *websiteField;
@property (weak, nonatomic) IBOutlet UITextView *aboutTextView;

@property (weak, nonatomic) IBOutlet UIView *basicInfoView;

@property (weak, nonatomic) IBOutlet UIView *websiteView;

@property (weak, nonatomic) IBOutlet UIView *userAboutView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@end
