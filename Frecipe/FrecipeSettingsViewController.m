//
//  FrecipeSettingsViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 29..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeSettingsViewController.h"
#import "FrecipeNavigationController.h"
#import "FrecipeBadgeView.h"
#import "FrecipeUser.h"
#import "ECSlidingViewController.h"

@interface FrecipeSettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *settings;

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
    self.screenName = @"Settings";
    self.settingsTableView.dataSource = self;
    self.settingsTableView.delegate = self;
    self.notificationBadge = [self addNotificationBadge];
    
    self.settings = [NSArray arrayWithObjects:@"Change Password", @"Send Feedback", @"Connect with Facebook", @"Log out", nil];
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

- (void)connectFacebookWithParameters:(NSDictionary *)parameters {
    NSString *path = @"facebook/connect";
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [[NSUserDefaults standardUserDefaults] setValue:@"facebook" forKey:@"provider"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%@", [parameters objectForKey:@"uid"]] forKey:@"uid"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Facebook Connect Error" message:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"message"]] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }];
    
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

// table view delegate and dataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.settings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingCell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SettingCell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@", [self.settings objectAtIndex:indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0 && indexPath.row
         == 0) {
        [self performSegueWithIdentifier:@"ChangePassword" sender:self];
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        [self performSegueWithIdentifier:@"SendFeedback" sender:self];
    } else if (indexPath.section == 0 && indexPath.row == 2) {
        NSArray *permissions = [[NSArray alloc] initWithObjects:
                                @"email",
                                @"user_likes",
                                nil];
        
        [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            FrecipeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            [delegate sessionStateChanged:session State:status Error:error];
            
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                NSDictionary *paramters = @{@"uid": [NSString stringWithFormat:@"%@", [result objectForKey:@"id"]], @"email": [result objectForKey:@"email"], @"authentication_token": [[NSUserDefaults standardUserDefaults] stringForKey:@"authentication_token"]};
                [self connectFacebookWithParameters:paramters];
                
            }];
        }];
    } else if (indexPath.section == 0 && indexPath.row == 3) {
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
    cell.selected = NO;
}
@end
