//
//  iPadInitViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 16..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "iPadInitViewController.h"

@interface iPadInitViewController ()

@end

@implementation iPadInitViewController

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
    NSLog(@"hi");
    self.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"frecipe.png"];
    NSLog(@"done");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
