//
//  iPadViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 13..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "iPadViewController.h"
#import "iPadNavigationController.h"

@interface iPadViewController ()

@end

@implementation iPadViewController

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
    iPadNavigationController *navigationController = (iPadNavigationController *)self.navigationController;
    
    [navigationController revealMenu];
}
@end
