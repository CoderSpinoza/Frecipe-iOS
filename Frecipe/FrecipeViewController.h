//
//  FrecipeViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrecipeMainViewController.h"
@interface FrecipeViewController : FrecipeMainViewController

@property (weak, nonatomic) IBOutlet UICollectionView *recipesCollectionView;
@end
