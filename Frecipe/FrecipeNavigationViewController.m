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
    
    // menu setup
    self.menu = [NSArray arrayWithObjects:@"frecipe.png", @"my_fridge.png", @"my_restaurant.png", @"grocery_list.png", @"settings.png", @"logout.png", nil];
    [self.slidingViewController setAnchorRightRevealAmount:200.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    // setting delegates
    self.menuCollectionView.delegate = self;
    self.menuCollectionView.dataSource = self;
    self.notificationsTableView.delegate = self;
    self.notificationsTableView.dataSource = self;
    
    
    // button and shadow setup
    [self.nameButton setBackgroundImage:[UIImage imageNamed:@"button_background_image.png"] forState:UIControlStateHighlighted];
    self.notificationsContainerView.layer.borderColor = [UIColor colorWithRed:0.9 green:0.4 blue:0.4 alpha:0.9].CGColor;
    self.notificationsContainerView.layer.borderWidth = 3;
    self.notificationsContainerView.layer.cornerRadius = 5;
    self.notificationsContainerView.layer.backgroundColor =  [UIColor colorWithRed:0.9 green:0.4 blue:0.4 alpha:0.9].CGColor;
    [self fetchUserInfo];
}

// fetch notifications every time this view appears
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.notificationsContainerView.frame = CGRectMake(self.notificationsContainerView.frame.origin.x, self.notificationsContainerView.frame.origin.y, self.notificationsContainerView.frame.size.width, 0);
    self.notificationsContainerView.alpha = 0;
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
    if (self.notificationsContainerView.frame.size.height == 0) {
        [UIView animateWithDuration:0.5 animations:^{
            self.notificationsContainerView.frame = CGRectMake(self.notificationsContainerView.frame.origin.x, self.notificationsContainerView.frame.origin.y, self.notificationsContainerView.frame.size.width, self.view.frame.size.height - self.notificationsContainerView.frame.origin.y - 30);
            self.notificationsContainerView.alpha = 1;
            
        }];
        self.notificationsTableView.frame = CGRectMake(self.notificationsTableView.frame.origin.x, self.notificationsTableView.frame.origin.y, self.notificationsTableView.frame.size.width, self.notificationsContainerView.frame.origin.y + self.notificationsContainerView.frame.size.height - self.notificationsTableView.frame.origin.y - 55);
        [self checkNotifications];
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

        [self.notificationsTableView reloadData];
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
    [operation start];
    
    
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

// table view delegate and dataSource methods for notification

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat fontSize = 13;
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
    
    CGSize constraintSize = CGSizeMake(184, MAXFLOAT);
    CGSize labelSize = [originalText sizeWithFont:boldFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    return labelSize.height + 20;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"NotificationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // setting attributes
    CGFloat fontSize = 13;
    UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    UIFont *regularFont = [UIFont systemFontOfSize:fontSize];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName, nil];
    NSDictionary *subAttributes = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName, nil];
    
    NSDictionary *notification = [self.notifications objectAtIndex:indexPath.row];
    NSDictionary *source = [notification objectForKey:@"source"];
    NSDictionary *recipe = [notification objectForKey:@"recipe"];
    NSString *category = [NSString stringWithFormat:@"%@", [notification objectForKey:@"category"]];
    
    NSString *sourceName = [NSString stringWithFormat:@"%@ %@", [source objectForKey:@"first_name"], [source objectForKey:@"last_name"]];
    NSString *recipeName;
    NSRange sourceRange = NSMakeRange(0, sourceName.length);
    NSString *originalText;
    if ([category isEqualToString:@"like"]) {
        recipeName = [NSString stringWithFormat:@"%@", [recipe objectForKey:@"name"]];
        originalText = [NSString stringWithFormat:@"%@ liked your recipe %@.", sourceName, recipeName];
    } else if ([category isEqualToString:@"comment"]) {
        recipeName = [NSString stringWithFormat:@"%@", [recipe objectForKey:@"name"]];
        originalText = [NSString stringWithFormat:@"%@ commented on your recipe %@.", sourceName, recipeName];
    } else if ([category isEqualToString:@"follow"]) {
        originalText = [NSString stringWithFormat:@"%@ is now following you!", sourceName];
    } else {
        recipeName = [NSString stringWithFormat:@"%@", [recipe objectForKey:@"name"]];
        originalText = [NSString stringWithFormat:@"%@ uploaded a new recipe %@.", sourceName, recipeName];
    }
    
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:originalText attributes:subAttributes];
    [attributedText setAttributes:attributes range:sourceRange];
    
    if (![category isEqualToString:@"follow"]) {
        NSRange recipeRange = NSMakeRange(originalText.length - recipeName.length - 1, recipeName.length);
        [attributedText setAttributes:attributes range:recipeRange];
    }
    
    cell.textLabel.attributedText = attributedText;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    if ([[NSString stringWithFormat:@"%@", [notification objectForKey:@"seen"]] isEqualToString:@"0"]) {
        UIView *backgroudView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        backgroudView.opaque = YES;
        backgroudView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.95 alpha:0.7];
        cell.backgroundView = backgroudView;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    NSDictionary *notification = [self.notifications objectAtIndex:indexPath.row];
    NSString *category = [NSString stringWithFormat:@"%@", [notification objectForKey:@"category"]];
    if ([category isEqualToString:@"like"] || [category isEqualToString:@"comment"] || [category isEqualToString:@"upload"]) {
        FrecipeNavigationController *navigationController = (FrecipeNavigationController *)self.slidingViewController.topViewController;
        [self.slidingViewController resetTopViewWithAnimations:^{
        } onComplete:^{
        }];
        FrecipeMainViewController *mainViewController = [navigationController.childViewControllers objectAtIndex:0];
        
        [mainViewController performSegueWithNotification:category Target:[notification objectForKey:@"recipe"]];
    } else {
        
    }
}

@end
