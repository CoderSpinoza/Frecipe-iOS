//
//  FrecipeMainViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 6..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FrecipeMainViewController : UIViewController

@property (strong, nonatomic) FrecipeBadgeView *notificationBadge;

- (FrecipeBadgeView *)addNotificationBadge;

@end
