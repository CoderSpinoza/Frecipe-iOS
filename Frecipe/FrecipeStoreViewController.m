//
//  FrecipeStoreViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 8. 14..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeStoreViewController.h"

@interface FrecipeStoreViewController ()

@end

@implementation FrecipeStoreViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"%@", [self.store objectForKey:@"name"]];
	// Do any additional setup after loading the view.
//    self.googleMapView.myLocationEnabled = YES;
    
    self.googleMapView.camera = [GMSCameraPosition cameraWithLatitude:[[NSString stringWithFormat:@"%@", [self.store objectForKey:@"latitude"]] floatValue] longitude:[[NSString stringWithFormat:@"%@", [self.store objectForKey:@"longitude"]] floatValue] zoom:15];
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake([[NSString stringWithFormat:@"%@", [self.store objectForKey:@"latitude"]] floatValue], [[NSString stringWithFormat:@"%@", [self.store objectForKey:@"longitude"]] floatValue]);
    marker.title = self.title;
    marker.snippet = [self.store objectForKey:@"address"];
    marker.map = self.googleMapView;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
