//
//  FrecipeNavigationViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "FPPopoverController.h"
#import "ARCMacros.h"
@interface FrecipeNavigationViewController : GAITrackedViewController

@property (weak, nonatomic) IBOutlet FBProfilePictureView *fbProfilePictureView;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UICollectionView *menuCollectionView;
@property (weak, nonatomic) IBOutlet FrecipeBadgeView *notificationsBadgeView;
@property (strong, nonatomic) FPPopoverController *notificationsPopoverViewController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@end
