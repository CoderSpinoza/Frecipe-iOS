//
//  FrecipeStoreViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 8. 14..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>

@interface FrecipeStoreViewController : UIViewController

@property (strong, nonatomic) NSDictionary *store;
@property (weak, nonatomic) IBOutlet GMSMapView *googleMapView;

@end
