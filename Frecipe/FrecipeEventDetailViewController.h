//
//  FrecipeEventDetailViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 7. 26..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FrecipeEventDetailViewController : UIViewController

@property (strong, nonatomic) NSDictionary *event;
@property (strong, nonatomic) UILabel *deadlineLabel;
@end
