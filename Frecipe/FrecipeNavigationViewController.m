//
//  FrecipeNavigationViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeNavigationViewController.h"
#import "FrecipeNavigationController.h"

#import "ECSlidingViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface FrecipeNavigationViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *menu;
@property (strong, nonatomic) NSMutableArray *notifications;

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
    self.menu = [NSArray arrayWithObjects:@"frecipe.png", @"my_fridge.png", @"my_restaurant.png", @"grocery_list.png", @"settings.png", @"logout.png", nil];
    [self.slidingViewController setAnchorRightRevealAmount:200.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    self.menuCollectionView.delegate = self;
    self.menuCollectionView.dataSource = self;
    
    [self.nameButton setBackgroundImage:[UIImage imageNamed:@"button_background_image.png"] forState:UIControlStateHighlighted];
    
//    self.notificationsTableView.delegate = self;
//    self.notificationsTableView.dataSource = self;
    self.notificationsContainerView.layer.borderColor = [UIColor colorWithRed:0.9 green:0.4 blue:0.4 alpha:0.9].CGColor;
    self.notificationsContainerView.layer.borderWidth = 3;
    self.notificationsContainerView.layer.cornerRadius = 5;
    self.notificationsContainerView.layer.backgroundColor =  [UIColor colorWithRed:0.9 green:0.4 blue:0.4 alpha:0.9].CGColor;
    [self fetchUserInfo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    FrecipeNavigationController *navigationController = (FrecipeNavigationController *)self.slidingViewController.topViewController;
    NSLog(@"%@", [navigationController.childViewControllers objectAtIndex:0]);
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
    
    if ([identifier isEqualToString:@"logout.png"]) {
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
    
    if (self.notificationsContainerView.frame.size.height == 0) {
        [UIView animateWithDuration:0.5 animations:^{
            self.notificationsContainerView.frame = CGRectMake(self.notificationsContainerView.frame.origin.x, self.notificationsContainerView.frame.origin.y, self.notificationsContainerView.frame.size.width, self.view.frame.size.height - self.notificationsContainerView.frame.origin.y - 30);
            self.notificationsContainerView.alpha = 1;
            
        }];
        self.notificationsTableView.frame = CGRectMake(self.notificationsTableView.frame.origin.x, self.notificationsTableView.frame.origin.y, self.notificationsTableView.frame.size.width, self.notificationsContainerView.frame.origin.y + self.notificationsContainerView.frame.size.height - self.notificationsTableView.frame.origin.y - 55);
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            self.notificationsContainerView.frame = CGRectMake(self.notificationsContainerView.frame.origin.x, self.notificationsContainerView.frame.origin.y, self.notificationsContainerView.frame.size.width, 0);
            self.notificationsContainerView.alpha = 0;
        }];
    }
}

- (void)fetchUserInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *provider = [defaults stringForKey:@"provider"];
    if ([provider isEqualToString:@"facebook"]) {
        self.profilePictureView.hidden = YES;
        self.fbProfilePictureView.profileID = [defaults stringForKey:@"uid"];
    } else {
        self.fbProfilePictureView.hidden = YES;
        self.profilePictureView.hidden = NO;
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
    [button setBackgroundImage:[UIImage imageNamed:@"button_background_image.png"] forState:UIControlStateHighlighted];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = [NSString stringWithFormat:@"%@", [self.menu objectAtIndex:indexPath.row]];
    
    if ([identifier isEqualToString:@"logout.png"]) {
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

// table view delegate and dataSource methods


@end
