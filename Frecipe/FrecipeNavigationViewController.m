//
//  FrecipeNavigationViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeNavigationViewController.h"
#import "ECSlidingViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface FrecipeNavigationViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSArray *menu;

@end

@implementation FrecipeNavigationViewController

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
    self.menu = [NSArray arrayWithObjects:@"frecipe.jpg", @"my_fridge.jpg", @"my_restaurant.jpg", @"grocery_list.jpg", @"settings.jpg", @"logout.jpg", nil];
    [self.slidingViewController setAnchorRightRevealAmount:200.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    self.menuCollectionView.delegate = self;
    self.menuCollectionView.dataSource = self;
    
    [self.notificationButton setBackgroundImage:[UIImage imageNamed:@"bar_red.png"] forState:UIControlStateHighlighted  ];
    [self fetchUserInfo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)menuButtonPressed:(UIButton *)sender {
    UICollectionViewCell *cell = (UICollectionViewCell *)sender.superview.superview;
    
    NSIndexPath *indexPath = [self.menuCollectionView indexPathForCell:cell];
    
    NSString *identifier = [NSString stringWithFormat:@"%@", [self.menu objectAtIndex:indexPath.row]];
    
    if ([identifier isEqualToString:@"logout.jpg"]) {
        UIViewController *newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Login"];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:nil forKey:@"authentication_token"];
        [defaults setObject:nil forKey:@"provider"];
        [defaults setObject: nil forKey:@"uid"];
        [defaults setObject:nil forKey:@"id"];
        [defaults synchronize];
        
        [FBSession.activeSession closeAndClearTokenInformation];
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            self.slidingViewController.topViewController = newTopViewController;
            [self.slidingViewController resetTopView];
            
        }];
    } else {
        UIViewController *newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
        
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            self.slidingViewController.topViewController = newTopViewController;
            [self.slidingViewController resetTopView];
            
        }];
    }
}
- (IBAction)notificationButtonPressed {
}

- (void)fetchUserInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *provider = [defaults stringForKey:@"provider"];
    if ([provider isEqualToString:@"facebook"]) {
        self.profilePictureView.hidden = YES;
        self.fbProfilePictureView.profileID = [defaults stringForKey:@"uid"];
    } else {
        self.fbProfilePictureView.hidden = YES;
        [self.profilePictureView setImageWithURL:[NSString stringWithFormat:@"%@", [defaults stringForKey:@"profile_picture"]]];
    }
    
[self.nameButton setTitle:[defaults stringForKey:@"name"] forState:UIControlStateNormal];
}

// collection view delegate and dataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.menu.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"MenuCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIButton *button = (UIButton *)[cell viewWithTag:1];
    
    
    [button setImage:[UIImage imageNamed:[self.menu objectAtIndex:indexPath.row]] forState:UIControlStateNormal];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = [NSString stringWithFormat:@"%@", [self.menu objectAtIndex:indexPath.row]];
    
    if ([identifier isEqualToString:@"logout.jpg"]) {
        UIViewController *newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Login"];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:nil forKey:@"authentication_token"];
        [defaults setObject:nil forKey:@"provider"];
        [defaults setObject: nil forKey:@"uid"];
        [defaults setObject:nil forKey:@"id"];
        [defaults synchronize];
        
        [FBSession.activeSession closeAndClearTokenInformation];
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            self.slidingViewController.topViewController = newTopViewController;
            [self.slidingViewController resetTopView];
            
        }];
        
    } else {
        UIViewController *newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
        
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            self.slidingViewController.topViewController = newTopViewController;
            [self.slidingViewController resetTopView];
            
        }];
        
    }
}

@end
