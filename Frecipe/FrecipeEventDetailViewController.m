//
//  FrecipeEventDetailViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 7. 26..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeEventDetailViewController.h"
#import "FrecipeFunctions.h"
#import <UIImageView+AFNetworking.h>

@interface FrecipeEventDetailViewController ()

@end

@implementation FrecipeEventDetailViewController

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
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Event picture
    
    self.title = [NSString stringWithFormat:@"%@", [self.event objectForKey:@"name"]];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 280, 140)];
    
    [imageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/events/%@/%@", [self s3BucketURL], [self.event objectForKey:@"id"], [self.event objectForKey:@"photo_file_name"]]]];
    
    UITextView *descriptionTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 160, 280, 140)];
    descriptionTextView.editable = NO;
    
    descriptionTextView.text = [self.event objectForKey:@"description"];
    
    
    self.deadlineLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 310, 280, 20)];
    self.deadlineLabel.font = [UIFont boldSystemFontOfSize:15.0f];
//    
//    self.deadlineLabel.text = [NSString stringWithFormat:@"Deadline: %@", [FrecipeFunctions compareWithCurrentDate:[self.event objectForKey:@"deadline"]]];
    [self.view addSubview:imageView];
    [self.view addSubview:descriptionTextView];
    [self.view addSubview:self.deadlineLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
