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
#import "FrecipeAppDelegate.h"
#import "FrecipeUser.h"
#import <UIImageView+WebCache.h>

@interface FrecipeNavigationViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, FPPopoverControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (strong, nonatomic) NSArray *menu;
@property (strong, nonatomic) NSMutableArray *notifications;
@property (strong, nonatomic) FrecipeNotificationsViewController *notificationsViewController;

@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) NSMutableArray *users;

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
    self.menu = [NSArray arrayWithObjects:@"frecipe.png", @"my_fridge.png", @"my_restaurant.png", @"grocery_list.png", @"leaderboard.png", @"settings.png", nil];
    [self.slidingViewController setAnchorRightRevealAmount:200.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    // setting delegates
    self.menuCollectionView.delegate = self;
    self.menuCollectionView.dataSource = self;
    
    
    // wire up a search display controller
    self.searchBar.delegate = self;
    self.searchDisplayController.delegate = self;
    
    // button and shadow setup
    [self.nameButton setBackgroundImage:[UIImage imageNamed:@"button_background_image.png"] forState:UIControlStateHighlighted];
    [self fetchUserInfo];
    [self setupNotifications];
    if (!FBSession.activeSession.isOpen) {
        [FBSession openActiveSessionWithReadPermissions:[NSArray arrayWithObjects:@"email", nil]allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            if (!error) {
            } else {
                NSLog(@"%@", error);
            }
        }];
    }
}

// fetch notifications every time this view appears
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self reloadProfilePicture];
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
    
    UIViewController *newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        self.slidingViewController.topViewController = newTopViewController;
        [self.slidingViewController resetTopView];
        
    }];
}

- (IBAction)logoutButtonPressed {
    [FrecipeUser clearUserInfo];
    
    [FBSession.activeSession closeAndClearTokenInformation];
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        FrecipeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [UIView transitionWithView:delegate.window duration:0.7 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
            BOOL oldState = [UIView areAnimationsEnabled];
            [UIView setAnimationsEnabled:NO];
            delegate.window.rootViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Login"];
            [UIView setAnimationsEnabled:oldState];
        } completion:nil];
    }];
}

- (IBAction)notificationButtonPressed {
}

- (void)reloadProfilePicture {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *profilePictureUrl = [defaults stringForKey:@"profile_picture"];
    [self.profilePictureView setImageWithURL:[NSURL URLWithString:profilePictureUrl]];
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
        [self.profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [defaults stringForKey:@"profile_picture"]]]];
    }
[self.nameButton setTitle:[defaults stringForKey:@"name"] forState:UIControlStateNormal];
}

- (void)setupNotifications {
    self.notificationsViewController.tableView.delegate = self;
    self.notificationsViewController.delegate = self;
    self.notificationsPopoverViewController = [[FPPopoverController alloc] initWithViewController:self.notificationsViewController];
    self.notificationsPopoverViewController.delegate = self;
    self.notificationsPopoverViewController.arrowDirection = FPPopoverArrowDirectionAny;
    self.notificationsPopoverViewController.contentSize = CGSizeMake(280, self.view.frame.size.height * 0.9);
}

- (IBAction)setupNotifications:(UIButton *)sender {
    
    [self.notificationsPopoverViewController presentPopoverFromView:self.notificationsBadgeView];
    [self checkNotifications];
}


- (void)fetchNotifications {
    
    NSString *path = @"notifications/user";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    
    if (authentication_token == nil) {
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:authentication_token forKey:@"authentication_token"];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        self.notifications = [NSMutableArray arrayWithArray:[JSON objectForKey:@"notifications"]];
        NSString *unseen = [NSString stringWithFormat:@"%@", [JSON objectForKey:@"unseen_count"]];
        
        self.notificationsBadgeView.text = unseen;
        FrecipeNavigationController *navigationController = (FrecipeNavigationController *)self.slidingViewController.topViewController;
        FrecipeMainViewController *viewController = [navigationController.childViewControllers objectAtIndex:0];
        viewController.notificationBadge.text = unseen;

        self.notificationsViewController.notifications = self.notifications;
        
        [self.notificationsViewController.tableView reloadData];

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (void)checkNotifications {
    NSString *path = @"notifications/check";
    
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
        
        self.notificationsBadgeView.text = @"0";
        if (navigationController.childViewControllers.count > 0) {
            FrecipeMainViewController *viewController = [navigationController.childViewControllers objectAtIndex:0];
            viewController.notificationBadge.text = @"0";
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (void)querySearchString:(NSString *)searchString {
    NSString *path = @"tokens/search";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"search",nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, searchString, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.recipes = [JSON objectForKey:@"recipes"];
        self.users = [JSON objectForKey:@"users"];
        
        [self.searchDisplayController.searchResultsTableView reloadData];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

// search bar and display delegate methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    
    [self.slidingViewController anchorTopViewTo:ECRight animations:^{
    } onComplete:^{
        if (self.slidingViewController.anchorRightRevealAmount == 200.f) {
            self.searchBar.frame = CGRectMake(0, 0, 200.0f, 44.0f);
        }
    }];
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.slidingViewController.anchorRightRevealAmount = 200.0f;
    [self.slidingViewController anchorTopViewTo:ECRight animations:^{
        
    } onComplete:^{
        self.searchBar.frame = CGRectMake(0, 0, 200.0f, 44.0f);
    }];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    if (![searchString isEqualToString:@""]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(querySearchString:) withObject:searchString afterDelay:0.5];
        
        [self.slidingViewController setAnchorRightRevealAmount:320.f];

    } else {
        [self.slidingViewController setAnchorRightRevealAmount:200.f];

    }
    
    return YES;
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

// table view dataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.recipes.count;
    } else {
        return self.users.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Recipes";
    } else {
        return @"Chefs";
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    if (indexPath.section == 0) {
        
        NSDictionary *recipe = [self.recipes objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [recipe objectForKey:@"name"]];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 43, 43)];
        [imageView setImageWithURL:[NSURL URLWithString:[recipe objectForKey:@"recipe_image"]] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"]];
        cell.imageView.image = [UIImage imageNamed:@"default_recipe_picture.png"];
        
        [cell addSubview:imageView];
        cell.imageView.hidden = YES;
    } else {
        NSDictionary *user = [self.users objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
        
        
        NSString *provider = [NSString stringWithFormat:@"%@", [user objectForKey:@"provider"]];
        
        if ([provider isEqualToString:@"facebook"]) {
            cell.imageView.image = [UIImage imageNamed:@"default_profile_picture.png"];
            FBProfilePictureView *fbProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:[NSString stringWithFormat:@"%@", [user objectForKey:@"uid"]] pictureCropping:FBProfilePictureCroppingSquare];
            fbProfilePictureView.frame = CGRectMake(0, 0, 43, 43);
            fbProfilePictureView.tag = 1;
            [cell addSubview:fbProfilePictureView];
            
        } else {
            cell.imageView.image = [UIImage imageNamed:@"default_profile_picture.png"];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 43, 43)];
            [imageView setImageWithURL:[NSURL URLWithString:[user objectForKey:@"profile_picture"]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
            FBProfilePictureView *previousView = (FBProfilePictureView *)[cell viewWithTag:1];
            [previousView removeFromSuperview];
            [cell addSubview:imageView];
        }
        
    }
    return cell;
}

// table view delegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat fontSize = 14;
    UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    
    NSDictionary *notification = [self.notifications objectAtIndex:indexPath.row];
    NSDictionary *source = [notification objectForKey:@"source"];
    NSDictionary *recipe = [notification objectForKey:@"recipe"];
    NSString *category = [NSString stringWithFormat:@"%@", [notification objectForKey:@"category"]];
    
    NSString *sourceName = [NSString stringWithFormat:@"%@ %@", [source objectForKey:@"first_name"], [source objectForKey:@"last_name"]];
    NSString *originalText;
    if ([category isEqualToString:@"like"]) {
        originalText = [NSString stringWithFormat:@"%@ liked your recipe %@.", sourceName, [recipe objectForKey:@"name"]];
    } else if ([category isEqualToString:@"comment"]) {
        originalText = [NSString stringWithFormat:@"%@ commented on your recipe %@.", sourceName, [recipe objectForKey:@"name"]];
    } else if ([category isEqualToString:@"follow"]) {
        originalText = [NSString stringWithFormat:@"%@ is now following you!", sourceName];
    } else {
        originalText = [NSString stringWithFormat:@"%@ uploaded a new recipe %@.", sourceName, [recipe objectForKey:@"name"]];
    }
    
    CGSize constraintSize = CGSizeMake(200, MAXFLOAT);
    CGSize labelSize = [originalText sizeWithFont:boldFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];    
    if (labelSize.height > 40) {
        return labelSize.height+10;
    } else {
        return 44;
    }
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    [self.searchBar resignFirstResponder];
    FrecipeNavigationController *navigationController = (FrecipeNavigationController *)self.slidingViewController.topViewController;
    FrecipeMainViewController *mainViewController = [navigationController.childViewControllers objectAtIndex:0];
    
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        
        [self.slidingViewController resetTopViewWithAnimations:^{
        } onComplete:^{
        }];
        if (indexPath.section == 0) {
            
            [mainViewController performSegueWithNotification:@"like" Target:[self.recipes objectAtIndex:indexPath.row]];
        } else {
            [mainViewController performSegueWithNotification:@"follow" Target:[self.users objectAtIndex:indexPath.row]];
        }
    } else {
        
        NSDictionary *notification = [self.notificationsViewController.notifications objectAtIndex:indexPath.row];
        NSString *category = [NSString stringWithFormat:@"%@", [notification objectForKey:@"category"]];
        
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
}

@end
