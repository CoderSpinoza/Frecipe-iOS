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
@property (strong, nonatomic) NSDictionary *selectedRecipe;
@property (strong, nonatomic) NSDictionary *selectedUser;
- (FrecipeBadgeView *)addNotificationBadge;
- (void)performSegueWithNotification:(NSString *)category Target:(NSDictionary *)target;
@end
