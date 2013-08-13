//
//  FrecipeLeaderboardViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 7. 13..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeMainViewController.h"
#import <FPPopoverController.h>

@interface FrecipeLeaderboardViewController : FrecipeMainViewController

@property (weak, nonatomic) IBOutlet UITableView *friendsLeaderboard;
@property (weak, nonatomic) IBOutlet UITableView *totalLeaderboard;
@property (weak, nonatomic) IBOutlet UIView *facebookHideView;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *fbProfilePictureView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *pointLabel;
@property (weak, nonatomic) IBOutlet UILabel *myRankingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIView *myRankingView;

@property (assign, nonatomic) BOOL fromFrecipe;

@property (strong, nonatomic) FPPopoverController *eventPopoverController;

@end
