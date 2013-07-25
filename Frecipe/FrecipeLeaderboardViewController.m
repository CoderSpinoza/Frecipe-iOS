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
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface FrecipeLeaderboardViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate> {
    int myRanking;
    int myFacebookRanking;
}

@property (strong, nonatomic) NSMutableArray *facebookFriends;
@property (strong, nonatomic) NSMutableArray *uids;
@property (strong, nonatomic) NSMutableArray *facebookUsers;
@property (strong, nonatomic) NSMutableArray *totalUsers;
@property (strong, nonatomic) NSDictionary *user;
@end

@implementation FrecipeLeaderboardViewController
@synthesize uids = _uids;

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
    self.friendsLeaderboard.dataSource = self;
    self.friendsLeaderboard.delegate = self;
    self.totalLeaderboard.dataSource = self;
    self.totalLeaderboard.delegate = self;
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *provider = [defaults stringForKey:@"provider"];
    
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
    [self fetchScores];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
        myFacebookRanking = [self.facebookUsers indexOfObject:self.user] + 1;
        
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            self.myRankingLabel.text = [NSString stringWithFormat:@"%i", myFacebookRanking];
        } else {
            self.myRankingLabel.text = [NSString stringWithFormat:@"%i", myRanking];
        }
        
        
        
        self.totalUsers = [[self.totalUsers subarrayWithRange:NSMakeRange(0, 50)] mutableCopy];
        
        if ([provider isEqualToString:@"facebook"]) {
            self.fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"uid"]];
        } else {
            if (PRODUCTION) {
                [self.profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/%@", [self s3BucketURL],[self.user objectForKey:@"id"], [self.user objectForKey:@"profile_picture_file_name"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
            } else {
                [self.profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5000/image/users/%@/%@",[self.user objectForKey:@"id"], [self.user objectForKey:@"profile_picture_file_name"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
            }
        }
        
        [self.friendsLeaderboard reloadData];
        [self.totalLeaderboard reloadData];

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
            cell.contentView.backgroundColor = [UIColor colorWithRed:1.0 green:185.0/255.0 blue:15.0/255.0 alpha:1];
        } else if (indexPath.row == 1) {
            rankingLabel.textColor = [UIColor whiteColor];
            rankingLabel.backgroundColor = [UIColor lightGrayColor];
            cell.contentView.backgroundColor = [UIColor lightGrayColor];
        } else if (indexPath.row == 2) {
            rankingLabel.textColor = [UIColor whiteColor];
            rankingLabel.backgroundColor = [UIColor colorWithRed:166.0/255.0 green:125.0/255.0 blue:61.0/255.0 alpha:1];
            cell.contentView.backgroundColor = [UIColor colorWithRed:166.0/255.0 green:125.0/255.0 blue:61.0/255.0 alpha:1];
        } else {
            rankingLabel.textColor = [UIColor blackColor];
            rankingLabel.backgroundColor = [UIColor whiteColor];
            cell.contentView.backgroundColor = [UIColor whiteColor];
        }

        
        UILabel *nameLabel = (UILabel *)[cell viewWithTag:4];
        nameLabel.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
        nameLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        UILabel *pointLabel = (UILabel *)[cell viewWithTag:5];
        pointLabel.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"points"]];
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
            cell.contentView.backgroundColor = [UIColor colorWithRed:1.0 green:185.0/255.0 blue:15.0/255.0 alpha:1];
        } else if (indexPath.row == 1) {
            rankingLabel.textColor = [UIColor whiteColor];
            rankingLabel.backgroundColor = [UIColor lightGrayColor];
            
            cell.contentView.backgroundColor = [UIColor lightGrayColor];
        } else if (indexPath.row == 2) {
            rankingLabel.textColor = [UIColor whiteColor];
            rankingLabel.backgroundColor = [UIColor colorWithRed:166.0/255.0 green:125.0/255.0 blue:61.0/255.0 alpha:1];
            
            cell.contentView.backgroundColor = [UIColor colorWithRed:166.0/255.0 green:125.0/255.0 blue:61.0/255.0 alpha:1];
        } else {
            rankingLabel.textColor = [UIColor blackColor];
            rankingLabel.backgroundColor = [UIColor whiteColor];
            cell.contentView.backgroundColor = [UIColor whiteColor];
        }
        
        nameLabel.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
        nameLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        UILabel *pointLabel = (UILabel *)[cell viewWithTag:5];
        pointLabel.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"points"]];
        return cell;
    }
    
}

// table view delegate methods




@end
