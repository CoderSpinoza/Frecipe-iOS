//
//  FrecipeViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FrecipeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UICollectionView *recipesCollectionView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@end
