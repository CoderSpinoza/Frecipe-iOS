//
//  FrecipeSettingsViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 29..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeSettingsViewController.h"
#import "FrecipeNavigationController.h"

@interface FrecipeSettingsViewController ()

@end

@implementation FrecipeSettingsViewController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)revealMenu:(UIBarButtonItem *)sender {
    FrecipeNavigationController *navigationController = (FrecipeNavigationController *)self.navigationController;
    [navigationController revealMenu];
}
@end
