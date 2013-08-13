//
//  FrecipeProfileDetailViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 30..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GAITrackedViewController.h>
@interface FrecipeProfileDetailViewController : GAITrackedViewController
@property (strong, nonatomic) NSString *segueIdentifier;
@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) NSMutableArray *users;
@property (strong, nonatomic) NSDictionary *user;
@property (weak, nonatomic) IBOutlet UICollectionView *recipesCollectionView;

@property (weak, nonatomic) IBOutlet UITableView *usersTableView;

@end
