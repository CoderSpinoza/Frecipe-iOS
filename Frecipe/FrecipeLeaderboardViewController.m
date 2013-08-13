//
//  FrecipeLeaderboardViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 7. 13..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeLeaderboardViewController.h"
#import "FrecipeNavigationController.h"
#import "FrecipeUser.h"
#import "FrecipeProfileViewController.h"
#import "FrecipeEventDetailViewController.h"
#import "FrecipeFunctions.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface FrecipeLeaderboardViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, FPPopoverControllerDelegate> {
    int myRanking;
    int myFacebookRanking;
}

@property (strong, nonatomic) NSMutableArray *facebookFriends;
@property (strong, nonatomic) NSMutableArray *uids;
@property (strong, nonatomic) NSMutableArray *facebookUsers;
@property (strong, nonatomic) NSMutableArray *totalUsers;
@property (strong, nonatomic) NSDictionary *user;
@property (strong, nonatomic) NSDictionary *selectedUser;
@property (strong, nonatomic) NSDictionary *event;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) FrecipeEventDetailViewController *eventDetailViewController;

@end

@implementation FrecipeLeaderboardViewController
@synthesize uids = _uids;
@synthesize eventDetailViewController = _eventDetailViewController;

- (FrecipeEventDetailViewController *)eventDetailViewController {
    if (_eventDetailViewController == nil) {
        _eventDetailViewController = [[FrecipeEventDetailViewController alloc] init];
    }
    return _eventDetailViewController;
}

- (NSMutableArray *)uids {
    if (_uids == nil) {
        _uids = [[NSMutableArray alloc] init];
    }
    return _uids;
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
    self.trackedViewName = @"Leaderboard";
    self.friendsLeaderboard.dataSource = self;
    self.friendsLeaderboard.delegate = self;
    self.totalLeaderboard.dataSource = self;
    self.totalLeaderboard.delegate = self;
    
    self.segmentedControl.enabled = NO;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *provider = [defaults stringForKey:@"provider"];
    
    [[NSUserDefaults standardUserDefaults]synchronize];
    if ([provider isEqualToString:@"facebook"]) {
        self.facebookHideView.hidden = YES;
        self.segmentedControl.selectedSegmentIndex = 0;
        self.friendsLeaderboard.hidden = NO;
        self.totalLeaderboard.hidden = YES;
    } else {
        self.facebookHideView.hidden = YES;
        self.segmentedControl.selectedSegmentIndex = 1;
        self.friendsLeaderboard.hidden = YES;
        self.totalLeaderboard.hidden = NO;
    }
    
//    self.myRankingView.layer.borderColor = [[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.9] CGColor];
    self.myRankingView.backgroundColor = [UIColor colorWithRed:0.7f green:0.7f blue:0.7f alpha:0.9f];

    self.myRankingView.layer.borderWidth = 1.0f;

    [self fetchScores];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.eventPopoverController dismissPopoverAnimated:YES];
}

- (void)fetchScores {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *provider = [defaults stringForKey:@"provider"];
    
    if ([provider isEqualToString:@"facebook"]) {
        [self fetchFriendScores];
    } else {
        [self fetchAllScores];
    }
}

- (void)showEventPopup {
    self.eventDetailViewController.event = self.event;
    
    self.eventPopoverController = [[FPPopoverController alloc] initWithViewController:self.eventDetailViewController delegate:self];
    self.eventPopoverController.delegate = self;
    self.eventPopoverController.arrowDirection = FPPopoverArrowDirectionAny;
    self.eventPopoverController.contentSize = CGSizeMake(320, self.view.frame.size.height);
    
    [self.eventPopoverController presentPopoverFromPoint:CGPointMake(280, 20)];
}

- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(advanceTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)advanceTimer {
    NSDate *currentDate = [NSDate date];
    NSDate *eventDate = [FrecipeFunctions dateWithString:[NSString stringWithFormat:@"%@", [self.event objectForKey:@"deadline"]]];
    
    NSTimeInterval interval = [eventDate timeIntervalSinceDate:currentDate];
    
    
    NSString *timerString = [FrecipeFunctions compareWithCurrentDateForTimer:interval];
    self.eventDetailViewController.deadlineLabel.text = [NSString stringWithFormat:@"Time Left: %@", timerString];
}

- (void)fetchFriendScores {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uid = [defaults stringForKey:@"uid"];
    if (FBSession.activeSession) {
        if (!FBSession.activeSession.isOpen) {
            [FBSession openActiveSessionWithReadPermissions:[NSArray arrayWithObject:@"email"] allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                FBRequest *request = [FBRequest requestForMyFriends];
                [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    self.facebookFriends = [NSMutableArray arrayWithArray:[result objectForKey:@"data"]];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
                    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
                    self.facebookFriends = [[self.facebookFriends sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
                    
                    [self.facebookFriends enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        [self.uids addObject:[NSString stringWithFormat:@"%@", [obj objectForKey:@"id"]]];
                    }];
                    
                    [self.uids addObject:uid];
                    
                    [self fetchAllScores];
                }];
            }];
        } else {
            FBRequest *request = [FBRequest requestForMyFriends];
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                self.facebookFriends = [NSMutableArray arrayWithArray:[result objectForKey:@"data"]];
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
                self.facebookFriends = [[self.facebookFriends sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
                [self.facebookFriends enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [self.uids addObject:[NSString stringWithFormat:@"%@", [obj objectForKey:@"id"]]];
                }];
                
                [self.uids addObject:uid];
                [self fetchAllScores];
            }];
            
        }
    }

}

- (void)fetchAllScores {
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSString *path = @"rankings";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSDictionary *parameters = @{@"authentication_token": authentication_token};
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.totalUsers = [NSArray arrayWithArray:[JSON objectForKey:@"users"]];
        self.user = [NSDictionary dictionaryWithDictionary:[JSON objectForKey:@"user"]];
        self.event = [NSDictionary dictionaryWithDictionary:[JSON objectForKey:@"event"]];
        
        [self startTimer];
        if (self.event) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Event" style:UIBarButtonItemStyleBordered target:self action:@selector(showEventPopup)];
            if (self.fromFrecipe) {
                if ([self.navigationController.visibleViewController isEqual:self]) {
                    [self showEventPopup];
                }                
            }
        }
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"points" ascending:NO];
        NSSortDescriptor *sortDescriptor2 = [NSSortDescriptor sortDescriptorWithKey:@"first_name" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, sortDescriptor2, nil];
        
        
        self.totalUsers = [[self.totalUsers sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
    
        
        self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", [self.user objectForKey:@"first_name"], [self.user objectForKey:@"last_name"]];
        self.pointLabel.text = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"points"]];
        
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *provider = [defaults stringForKey:@"provider"];
        if ([provider isEqualToString:@"facebook"]) {
            [self.totalUsers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([[NSString stringWithFormat:@"%@", [obj objectForKey:@"provider"]] isEqualToString:@"facebook"]) {
                    [self.facebookUsers addObject:obj];
                }
            }];
        }
        
        self.facebookUsers = [[self.totalUsers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"uid IN %@", self.uids]] mutableCopy];
        
        myRanking = [self.totalUsers indexOfObject:self.user] + 1;
        
        if (self.facebookFriends) {
            myFacebookRanking = [self.facebookUsers indexOfObject:self.user] + 1;
        } else {
            myFacebookRanking = 1;
        }
        
        
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            self.myRankingLabel.text = [NSString stringWithFormat:@"%i", myFacebookRanking];
        } else {
            self.myRankingLabel.text = [NSString stringWithFormat:@"%i", myRanking];
        }
        
        
        
        if (self.totalUsers.count > 50) {
            self.totalUsers = [[self.totalUsers subarrayWithRange:NSMakeRange(0, 50)] mutableCopy];
        }
        
        if ([provider isEqualToString:@"facebook"]) {
            self.fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"uid"]];
        } else {
            if (PRODUCTION) {
                [self.profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/%@", [self s3BucketURL],[self.user objectForKey:@"id"], [self.user objectForKey:@"profile_picture_file_name"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
            } else {
                [self.profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5000/image/users/%@/%@",[self.user objectForKey:@"id"], [self.user objectForKey:@"profile_picture_file_name"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
            }
        }
        
        
        self.myRankingLabel.textColor = [UIColor whiteColor];
        self.myRankingLabel.layer.cornerRadius = 18.0f;
        self.myRankingLabel.frame = CGRectMake(4, 15, 36, 36);
        if ([self.myRankingLabel.text isEqualToString:@"1"]) {
            self.myRankingLabel.backgroundColor = [UIColor colorWithRed:1.0 green:185.0/255.0 blue:15.0/255.0 alpha:1];
        } else if ([self.myRankingLabel.text isEqualToString:@"2"]) {
        
            self.myRankingLabel.backgroundColor = [UIColor lightGrayColor];
        } else if ([self.myRankingLabel.text isEqualToString:@"3"]) {
            self.myRankingLabel.backgroundColor = [UIColor colorWithRed:166.0/255.0 green:125.0/255.0 blue:61.0/255.0 alpha:1];
        } else {
            self.myRankingLabel.frame = CGRectMake(0, 11, 44, 44);
            self.myRankingLabel.layer.cornerRadius = 0;
            self.myRankingLabel.textColor = [UIColor blackColor];
        }
        
        [self.friendsLeaderboard reloadData];
        [self.totalLeaderboard reloadData];

        self.segmentedControl.enabled = YES;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error loading leaderboard. Retry?" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Cancel", nil];
        
        [alertView show];
    }];
    
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    
    [queue addOperation:operation];
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

- (IBAction)segmentControlPressed:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.friendsLeaderboard.hidden = NO;
        self.totalLeaderboard.hidden = YES;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *provider = [defaults stringForKey:@"provider"];
        if ([provider isEqualToString:@"facebook"]) {
            self.facebookHideView.hidden = YES;
        } else {
            self.facebookHideView.hidden = NO;
        }
        self.myRankingLabel.text = [NSString stringWithFormat:@"%i", myFacebookRanking];
    } else {
        self.friendsLeaderboard.hidden = YES;
        self.facebookHideView.hidden = YES;
        self.totalLeaderboard.hidden = NO;
        self.myRankingLabel.text = [NSString stringWithFormat:@"%i", myRanking];
    }
}

- (IBAction)connectWithFacebookButtonPressed {
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
    
}

- (void)connectFacebookWithParameters:(NSDictionary *)parameters {
    NSString *path = @"facebook/connect";
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [[NSUserDefaults standardUserDefaults] setValue:@"facebook" forKey:@"provider"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%@", [parameters objectForKey:@"uid"]] forKey:@"uid"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self fetchScores];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Facebook Connect Error" message:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"message"]] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }];
    
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}


// alert view delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self fetchScores];
    }
}


// table view dataSource methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isEqual:self.friendsLeaderboard]) {
        return self.facebookUsers.count;
    } else {
        return self.totalUsers.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.friendsLeaderboard]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell" forIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FriendCell"];
        }
        NSDictionary *user = [self.facebookUsers objectAtIndex:indexPath.row];
        NSString *provider = [NSString stringWithFormat:@"%@", [user objectForKey:@"provider"]];
        
        UIImageView *profilePictureView = (UIImageView *)[cell viewWithTag:2];
        FBProfilePictureView *fbProfilePictureView = (FBProfilePictureView *)[cell viewWithTag:3];
        if ([provider isEqualToString:@"facebook"]) {
            profilePictureView.hidden = YES;
            fbProfilePictureView.hidden = NO;
            fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [user objectForKey:@"uid"]];
        } else {
            profilePictureView.hidden = NO;
            fbProfilePictureView.hidden = YES;
            if (PRODUCTION) {
                [profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/%@", [self s3BucketURL],[user objectForKey:@"id"], [user objectForKey:@"profile_picture_file_name"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
            } else {
                [profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5000/image/users/%@/%@",[user objectForKey:@"id"], [user objectForKey:@"profile_picture_file_name"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
            }
        }
        
        UILabel *rankingLabel = (UILabel *)[cell viewWithTag:1];
        rankingLabel.text = [NSString stringWithFormat:@"%i", indexPath.row + 1];
        rankingLabel.font = [UIFont boldSystemFontOfSize:15.0];
        if (indexPath.row == 0) {
            rankingLabel.textColor = [UIColor whiteColor];
            rankingLabel.backgroundColor = [UIColor colorWithRed:1.0 green:185.0/255.0 blue:15.0/255.0 alpha:1];
            rankingLabel.layer.cornerRadius = 18.0f;
            rankingLabel.frame = CGRectMake(4, 10, 36, 36);
//            cell.contentView.backgroundColor = [UIColor colorWithRed:1.0 green:185.0/255.0 blue:15.0/255.0 alpha:1];
        } else if (indexPath.row == 1) {
            rankingLabel.textColor = [UIColor whiteColor];
            rankingLabel.backgroundColor = [UIColor lightGrayColor];
            rankingLabel.layer.cornerRadius = 18.0f;
            rankingLabel.frame = CGRectMake(4, 10, 36, 36);
//            cell.contentView.backgroundColor = [UIColor lightGrayColor];
        } else if (indexPath.row == 2) {
            rankingLabel.textColor = [UIColor whiteColor];
            rankingLabel.backgroundColor = [UIColor colorWithRed:166.0/255.0 green:125.0/255.0 blue:61.0/255.0 alpha:1];
            rankingLabel.layer.cornerRadius = 18.0f;
            rankingLabel.frame = CGRectMake(4, 10, 36, 36);
//            cell.contentView.backgroundColor = [UIColor colorWithRed:166.0/255.0 green:125.0/255.0 blue:61.0/255.0 alpha:1];
        } else {
            rankingLabel.textColor = [UIColor blackColor];
            rankingLabel.backgroundColor = [UIColor clearColor];
            rankingLabel.layer.cornerRadius = 0;
            rankingLabel.frame = CGRectMake(0, 6, 44, 44);
//            cell.contentView.backgroundColor = [UIColor whiteColor];
        }

        
        UILabel *nameLabel = (UILabel *)[cell viewWithTag:4];
        nameLabel.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
        nameLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        UILabel *pointLabel = (UILabel *)[cell viewWithTag:5];
        pointLabel.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"points"]];
        
        
        if ([user isEqual:self.user]) {
            cell.contentView.backgroundColor = self.myRankingView.backgroundColor;
        } else {
            cell.contentView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
        }
        return cell;
        
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TotalCell" forIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TotalCell"];
        }
        
        
        NSDictionary *user = [self.totalUsers objectAtIndex:indexPath.row];
        NSString *provider = [NSString stringWithFormat:@"%@", [user objectForKey:@"provider"]];
        
        UIImageView *profilePictureView = (UIImageView *)[cell viewWithTag:2];
        FBProfilePictureView *fbProfilePictureView = (FBProfilePictureView *)[cell viewWithTag:3];
        if ([provider isEqualToString:@"facebook"]) {
            profilePictureView.hidden = YES;
            fbProfilePictureView.hidden = NO;
            fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [user objectForKey:@"uid"]];
        } else {
            fbProfilePictureView.hidden = YES;
            profilePictureView.hidden = NO;
            if (PRODUCTION) {
                [profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/%@", [self s3BucketURL],[user objectForKey:@"id"], [user objectForKey:@"profile_picture_file_name"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
            } else {
                [profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5000/image/users/%@/%@",[user objectForKey:@"id"], [user objectForKey:@"profile_picture_file_name"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
            }
        }
        
        UILabel *rankingLabel = (UILabel *)[cell viewWithTag:1];
        rankingLabel.text = [NSString stringWithFormat:@"%i", indexPath.row + 1];
        UILabel *nameLabel = (UILabel *)[cell viewWithTag:4];
        rankingLabel.font = [UIFont boldSystemFontOfSize:15];
        if (indexPath.row == 0) {
            rankingLabel.textColor = [UIColor whiteColor];
            rankingLabel.backgroundColor = [UIColor colorWithRed:1.0 green:185.0/255.0 blue:15.0/255.0 alpha:1];
            rankingLabel.layer.cornerRadius = 18.0f;
            rankingLabel.frame = CGRectMake(4, 10, 36, 36);
//            cell.contentView.backgroundColor = [UIColor colorWithRed:1.0 green:185.0/255.0 blue:15.0/255.0 alpha:1];
        } else if (indexPath.row == 1) {
            rankingLabel.textColor = [UIColor whiteColor];
            rankingLabel.backgroundColor = [UIColor lightGrayColor];
            rankingLabel.layer.cornerRadius = 18.0f;
            rankingLabel.frame = CGRectMake(4, 10, 36, 36);
            
//            cell.contentView.backgroundColor = [UIColor lightGrayColor];
        } else if (indexPath.row == 2) {
            rankingLabel.textColor = [UIColor whiteColor];
            rankingLabel.backgroundColor = [UIColor colorWithRed:166.0/255.0 green:125.0/255.0 blue:61.0/255.0 alpha:1];
            rankingLabel.layer.cornerRadius = 18.0f;
            rankingLabel.frame = CGRectMake(4, 10, 36, 36);
//            cell.contentView.backgroundColor = [UIColor colorWithRed:166.0/255.0 green:125.0/255.0 blue:61.0/255.0 alpha:1];
        } else {
            rankingLabel.layer.cornerRadius = 0;
            rankingLabel.textColor = [UIColor blackColor];
            rankingLabel.backgroundColor = [UIColor clearColor];
            rankingLabel.frame = CGRectMake(0, 6, 44, 44);
//            cell.contentView.backgroundColor = [UIColor whiteColor];
        }
        
        nameLabel.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
        nameLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        UILabel *pointLabel = (UILabel *)[cell viewWithTag:5];
        pointLabel.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"points"]];
        
        if ([user isEqual:self.user]) {
            cell.contentView.backgroundColor = self.myRankingView.backgroundColor;
        } else {
            cell.contentView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
        }
        
        return cell;
    }
    
}

// table view delegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.friendsLeaderboard]) {
        self.selectedUser = [self.facebookUsers objectAtIndex:indexPath.row];
    } else if ([tableView isEqual:self.totalLeaderboard]) {
        self.selectedUser = [self.totalUsers objectAtIndex:indexPath.row];
    }
    
    [self performSegueWithIdentifier:@"Profile" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Profile"]) {
        FrecipeProfileViewController *destinationController = segue.destinationViewController;
        destinationController.userId = [NSString stringWithFormat:@"%@", [self.selectedUser objectForKey:@"id"]];
        destinationController.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStyleBordered target:segue.destinationViewController action:@selector(popViewControllerAnimated:)];
    }
}



@end
