//
//  FrecipeNotificationsViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 10..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FrecipeNotificationsViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray *notifications;
@property (strong, nonatomic) UIViewController *delegate;

@end
