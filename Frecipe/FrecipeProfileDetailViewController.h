//
//  FrecipeProfileDetailViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 30..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FrecipeProfileDetailViewController : UIViewController
@property (strong, nonatomic) NSString *segueIdentifier;
@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) NSMutableArray *users;

@end
