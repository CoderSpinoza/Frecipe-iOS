//
//  FrecipeNavigationViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeNavigationViewController.h"
#import "FrecipeNavigationController.h"
#import "FrecipeAPIClient.h"
#import "ECSlidingViewController.h"
#import "FrecipeViewController.h"
#import "FrecipeFridgeViewController.h"
#import "FrecipeProfileViewController.h"
#import "FrecipeGroceryListViewController.h"
#import "FrecipeSettingsViewController.h"
#import "FrecipeNotificationsViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface FrecipeNavigationViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, FPPopoverControllerDelegate>

@property (strong, nonatomic) NSArray *menu;
@property (strong, nonatomic) NSMutableArray *notifications;
@property (strong, nonatomic) FrecipeNotificationsViewController *notificationsViewController;

@end

@implementation FrecipeNavigationViewController
@synthesize notificationsViewController = _notificationsViewController;

- (FrecipeNotificationsViewController *)notificationsViewController {
    if (_notificationsViewController == nil) {
        _notificationsViewController = [[FrecipeNotificationsViewController alloc] initWithStyle:UITableViewStylePlain];
    }
    return _notificationsViewController;
}

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
    
    // menu setup
    self.menu = [NSArray arrayWithObjects:@"frecipe.png", @"my_fridge.png", @"my_restaurant.png", @"grocery_list.png", @"settings.png", @"logout.png", nil];
    [self.slidingViewController setAnchorRightRevealAmount:200.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    // setting delegates
    self.menuCollectionView.delegate = self;
    self.menuCollectionView.dataSource = self;    
    
    // button and shadow setup
    [self.nameButton setBackgroundImage:[UIImage imageNamed:@"button_background_image.png"] forState:UIControlStateHighlighted];
    [self fetchUserInfo];
    [self setupNotifications];
    
}

// fetch notifications every time this view appears
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchNotifications];
    
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
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

- (void)setupNotifications {
    self.notificationsViewController.tableView.delegate = self;
    self.notificationsPopoverViewController = [[FPPopoverController alloc] initWithViewController:self.notificationsViewController];
    
    self.notificationsPopoverViewController.delegate = self;
    self.notificationsPopoverViewController.arrowDirection = FPPopoverArrowDirectionAny;
}

- (IBAction)setupNotifications:(UIButton *)sender {
    self.notificationsViewController.delegate = self;
    self.notificationsPopoverViewController = [[FPPopoverController alloc] initWithViewController:self.notificationsViewController];
    
    self.notificationsPopoverViewController.arrowDirection = FPPopoverArrowDirectionAny;
    self.notificationsPopoverViewController.contentSize = CGSizeMake(280, self.view.frame.size.height * 0.9);
    [self.notificationsPopoverViewController presentPopoverFromView:self.notificationsBadgeView];
}


- (void)fetchNotifications {
    
    NSString *path = @"notifications/user";
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:authentication_token forKey:@"authentication_token"];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        self.notifications = [NSArray arrayWithArray:[JSON objectForKey:@"notifications"]];
        NSString *unseen = [NSString stringWithFormat:@"%@", [JSON objectForKey:@"unseen_count"]];
        
        self.notificationsBadgeView.text = unseen;
        FrecipeNavigationController *navigationController = (FrecipeNavigationController *)self.slidingViewController.topViewController;
        FrecipeMainViewController *viewController = [navigationController.childViewControllers objectAtIndex:0];
        viewController.notificationBadge.text = unseen;

        self.notificationsViewController.notifications = self.notifications;

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    [operation start];
}

- (void)checkNotifications {
    
    
    NSString *path = @"notifications/check";
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    
    for (NSDictionary *notification in self.notifications) {
        if ([[NSString stringWithFormat:@"%@", [notification objectForKey:@"seen"]] isEqualToString:@"0"]) {
            [ids addObject:[NSString stringWithFormat:@"%@", [notification objectForKey:@"id"]]];
        }
    }
    
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"ids", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, ids, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        FrecipeNavigationController *navigationController = (FrecipeNavigationController *)self.slidingViewController.topViewController;
        FrecipeMainViewController *viewController = [navigationController.childViewControllers objectAtIndex:0];
        self.notificationsBadgeView.text = @"0";
        viewController.notificationBadge.text = @"0";
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
//    [operation start];
}

// pop over delegate methods
- (void)presentedNewPopoverController:(FPPopoverController *)newPopoverController shouldDismissVisiblePopover:(FPPopoverController *)visiblePopoverController {
    [self checkNotifications];
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

// table view delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    NSDictionary *notification = [self.notificationsViewController.notifications objectAtIndex:indexPath.row];
    NSString *category = [NSString stringWithFormat:@"%@", [notification objectForKey:@"category"]];
    
    FrecipeNavigationController *navigationController = (FrecipeNavigationController *)self.slidingViewController.topViewController;
    FrecipeMainViewController *mainViewController = [navigationController.childViewControllers objectAtIndex:0];
    
    [self.notificationsPopoverViewController dismissPopoverAnimated:YES];
    if ([category isEqualToString:@"like"] || [category isEqualToString:@"comment"] || [category isEqualToString:@"upload"]) {
        [self.slidingViewController resetTopViewWithAnimations:^{
        } onComplete:^{
        }];
        
        
        [mainViewController performSegueWithNotification:category Target:[notification objectForKey:@"recipe"]];
    } else {
        [self.slidingViewController resetTopViewWithAnimations:^{
            
        } onComplete:^{
            
        }];
        [mainViewController performSegueWithNotification:category Target:[notification objectForKey:@"source"]];
    }
}

@end
