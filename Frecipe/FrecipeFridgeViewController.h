//
//  FrecipeFridgeViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrecipeMainViewController.h"
@interface FrecipeFridgeViewController : FrecipeMainViewController

@property (weak, nonatomic) IBOutlet UITableView *ingredientsTableView;
@property (weak, nonatomic) IBOutlet UICollectionView *ingredientsCollectionView;
@end
