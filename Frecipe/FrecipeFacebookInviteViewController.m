//
//  FrecipeFacebookInviteViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 29..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeFacebookInviteViewController.h"
#import "FrecipeAppDelegate.h"
#import "FrecipeAPIClient.h"
#import <QuartzCore/QuartzCore.h>
#import <FacebookSDK/FacebookSDK.h>
#import <GAI.h>
@interface FrecipeFacebookInviteViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (strong, nonatomic) NSMutableArray *facebookFriends;
@property (strong, nonatomic) NSMutableArray *uids;
@property (strong, nonatomic) NSMutableArray *selectedFriends;
@property (strong, nonatomic) NSArray *alphabets;
@property (strong, nonatomic) NSMutableArray *searchedFriends;
@property (strong, nonatomic) NSMutableArray *invitedFriends;

@end

@implementation FrecipeFacebookInviteViewController

@synthesize selectedFriends = _selectedFriends;
@synthesize alphabets = _alphabets;
@synthesize searchedFriends = _searchedFriends;

- (NSMutableArray *)selectedFriends {
    if (_selectedFriends == nil) {
        _selectedFriends = [[NSMutableArray alloc] init];
    }
    return _selectedFriends;
}

- (NSArray *)alphabets {
    if (_alphabets == nil) {
        _alphabets = [[NSArray alloc] initWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z",  nil];
    }
    return _alphabets;
}

- (NSArray *)searchedFriends {
    if (_searchedFriends == nil) {
        _searchedFriends = [[NSMutableArray alloc] init];
    }
    return _searchedFriends;
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
    
    self.trackedViewName = @"Find Friends";
    self.facebookFriendsTableView.delegate = self;
    self.facebookFriendsTableView.dataSource = self;
    
    self.searchDisplayController.delegate = self;
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchBar.delegate = self;
    
    [self loadFacebookFriends];
    [self loadFacebookUids];
    [self loadInvitedPeople];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadFacebookUids {
    NSString *path = @"tokens/facebookAccounts";
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        self.uids = [NSMutableArray arrayWithArray:JSON];
        if (self.facebookFriends && self.invitedFriends) {
            [self.facebookFriendsTableView reloadData];
        }
        NSLog(@"%@", self.uids);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (void)loadInvitedPeople {
    NSString *path = @"facebook/invited";
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSDictionary *parameters = @{@"authentication_token": [[NSUserDefaults standardUserDefaults] stringForKey:@"authentication_token"]};
    
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.invitedFriends = [JSON objectForKey:@"invites"];
        NSLog(@"%@", self.invitedFriends);
        if (self.facebookFriends && self.uids) {
            [self.facebookFriendsTableView reloadData];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", [error localizedDescription]);
    }];
    
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (void)loadFacebookFriends {
    
    if (FBSession.activeSession) {
        if (!FBSession.activeSession.isOpen) {
            [FBSession openActiveSessionWithReadPermissions:[NSArray arrayWithObject:@"email"] allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                FBRequest *request = [FBRequest requestForMyFriends];
                [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    self.facebookFriends = [NSMutableArray arrayWithArray:[result objectForKey:@"data"]];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
                    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
                    self.facebookFriends = [[self.facebookFriends sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
                    if (self.uids && self.invitedFriends) {
                        [self.facebookFriendsTableView reloadData];
                    }
                    
                    
                }];
            }];
        } else {
            FBRequest *request = [FBRequest requestForMyFriends];
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                self.facebookFriends = [NSMutableArray arrayWithArray:[result objectForKey:@"data"]];
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
                self.facebookFriends = [[self.facebookFriends sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
                if (self.uids) {
                    [self.facebookFriendsTableView reloadData];
                }
            }];

        }
    }
    
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)inviteButtonPressed:(UIBarButtonItem *)sender {
    
    NSString *path = @"facebook/invite";
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSDictionary *parameters = @{@"authentication_token": [[NSUserDefaults standardUserDefaults] stringForKey:@"authentication_token"], @"uids": self.selectedFriends};
    
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"%@", JSON);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", [error localizedDescription]);
    }];
    
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
    
    NSArray *keys = [NSArray arrayWithObjects:@"message", @"to", nil];
    NSArray *values = [NSArray arrayWithObjects:@"Frecipe Request", [self.selectedFriends componentsJoinedByString:@","], nil];
    
    NSDictionary *facebookParameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil message:nil title:nil parameters:facebookParameters handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
        if (!error) {
            [[[GAI sharedInstance] defaultTracker] sendSocial:@"Facebook" withAction:@"Invite" withTarget:nil];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
        }
    }];
}

// search bar and display delegate and dataSource methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self.searchedFriends removeAllObjects];
    
    NSPredicate *firstNameFilterPredicate = [NSPredicate predicateWithFormat:@"first_name beginswith[c] %@", searchString];

    NSPredicate *lastNameFilterPredicate = [NSPredicate predicateWithFormat:@"last_name beginswith[cd] %@", searchString];
    
    NSArray *firstNameArray = [self.facebookFriends filteredArrayUsingPredicate:firstNameFilterPredicate];
    NSArray *lastNameArray = [self.facebookFriends filteredArrayUsingPredicate:lastNameFilterPredicate];
    
    [self.searchedFriends addObjectsFromArray:firstNameArray];
    [self.searchedFriends addObjectsFromArray:lastNameArray];
    return YES;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
}

// table view delegate and dataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        return self.alphabets.count;
    } else {
        return 1;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"first_name beginswith[c] %@", [self.alphabets objectAtIndex:section]];
        NSArray *filteredFriends = [self.facebookFriends filteredArrayUsingPredicate:filterPredicate];
        return filteredFriends.count;
    } else {
        return self.searchedFriends.count;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        return self.alphabets;
    } else {
        return nil;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        return index;
    } else {
        return 1;
    }
    
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        return [NSString stringWithFormat:@"%@", [self.alphabets objectAtIndex:section]];
    } else {
        return nil;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        static NSString *CellIdentifier = @"FriendCell";
        UITableViewCell *cell = [self.facebookFriendsTableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FriendCell"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"first_name beginswith[c] %@", [self.alphabets objectAtIndex:indexPath.section]];
        NSArray *filteredFriends = [self.facebookFriends filteredArrayUsingPredicate:filterPredicate];
        NSDictionary *facebookFriend = [filteredFriends objectAtIndex:indexPath.row];
        
        cell.imageView.image = [UIImage imageNamed:@"default_profile_picture.png"];
        
        FBProfilePictureView *profilePictureView = [[FBProfilePictureView alloc] initWithProfileID:[NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"id"]] pictureCropping:FBProfilePictureCroppingSquare];
        
        profilePictureView.frame = CGRectMake(0, 0, 44, 44);
        [cell addSubview:profilePictureView];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"name"]];
        
        
        if ([self.selectedFriends containsObject:[facebookFriend objectForKey:@"id"]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        if([self.uids containsObject:[facebookFriend objectForKey:@"id"]]) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
            label.text = @"Frecipe Member";
            label.textColor = [UIColor greenColor];
            label.textAlignment = NSTextAlignmentRight;
            label.font = [label.font fontWithSize:10];
            cell.accessoryView = label;
        } else {
            cell.accessoryView = nil;
        }
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        return cell;

    } else {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [self.facebookFriendsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        }
        
        // Configure the cell...
        
        NSDictionary *facebookFriend = [self.searchedFriends objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"name"]];
        cell.imageView.image = [UIImage imageNamed:@"default_profile_picture.png"];
        
        if ([self.selectedFriends containsObject:[facebookFriend objectForKey:@"id"]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

        if([self.uids containsObject:[facebookFriend objectForKey:@"id"]]) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
            label.text = @"Frecipe Member";
            label.textColor = [UIColor greenColor];
            label.textAlignment = NSTextAlignmentRight;
            label.font = [label.font fontWithSize:10];
            cell.accessoryView = label;
        } else if ([self.invitedFriends containsObject:[facebookFriend objectForKey:@"id"]]) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
            label.text = @"Already Invited";
            label.textColor = [UIColor blueColor];
            label.textAlignment = NSTextAlignmentRight;
            label.font = [label.font fontWithSize:10];
            cell.accessoryView = label;

        }else {
            cell.accessoryView = nil;
        }
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        FBProfilePictureView *profilePictureView = [[FBProfilePictureView alloc] initWithProfileID:[NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"id"]] pictureCropping:FBProfilePictureCroppingSquare];
        profilePictureView.frame = CGRectMake(0, 0, 44, 44);
        [cell addSubview:profilePictureView];
        
        return cell;
    }
}

- (NSIndexPath *)indexPathForFriend:(NSDictionary *)friend {
    NSInteger section = [self.alphabets indexOfObject:[[NSString stringWithFormat:@"%@", [friend objectForKey:@"name"]] substringToIndex:1]];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"name beginswith[c] %@", [self.alphabets objectAtIndex:section]];
    NSArray *filteredFriends = [self.facebookFriends filteredArrayUsingPredicate:filterPredicate];
    NSInteger row = [filteredFriends indexOfObject:friend];
    
    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (NSDictionary *)friendForIndexPath:(NSIndexPath *)indexpath {
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"name beginsWith[c] %@", [self.alphabets objectAtIndex:indexpath.section]];
    NSArray *filteredFriends = [self.facebookFriends filteredArrayUsingPredicate:filterPredicate];
    return [filteredFriends objectAtIndex:indexpath.row];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"first_name beginswith[c] %@", [self.alphabets objectAtIndex:indexPath.section]];
        NSArray *filteredFriends = [self.facebookFriends filteredArrayUsingPredicate:filterPredicate];
        NSDictionary *facebookFriend = [filteredFriends objectAtIndex:indexPath.row];
        
        if ([self.uids containsObject:[facebookFriend objectForKey:@"id"]] || [self.invitedFriends containsObject:[facebookFriend objectForKey:@"id"]]) {
            NSLog(@"%@", facebookFriend);
            return nil;
        } else {
            return indexPath;
        }
    } else {
        NSDictionary *facebookFriend = [self.searchedFriends objectAtIndex:indexPath.row];
        if ([self.uids containsObject:[facebookFriend objectForKey:@"id"]] || [self.invitedFriends containsObject:[facebookFriend objectForKey:@"id"]]) {
            return nil;
        } else {
            return indexPath;
        }
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
            NSDictionary *facebookFriend = [self friendForIndexPath:indexPath];
        
        [self.selectedFriends addObject:[NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"id"]]];
    } else {
        
        NSDictionary *selectedFriend = [self.searchedFriends objectAtIndex:indexPath.row];

        [self.searchDisplayController setActive:NO animated:YES];

        NSIndexPath *scrollIndexPath = [self indexPathForFriend:selectedFriend];
        UITableViewCell *toBeUncheckedCell = [self.facebookFriendsTableView cellForRowAtIndexPath:scrollIndexPath];
        if ([self.selectedFriends containsObject:[NSString stringWithFormat:@"%@", [selectedFriend objectForKey:@"id"]]]) {
            [self.selectedFriends removeObject:[NSString stringWithFormat:@"%@", [selectedFriend objectForKey:@"id"]]];
            toBeUncheckedCell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            UITableViewCell *cell = [self.facebookFriendsTableView cellForRowAtIndexPath:indexPath];
            cell.selected = YES;
            [self.selectedFriends addObject:[NSString stringWithFormat:@"%@", [selectedFriend objectForKey:@"id"]]];
            toBeUncheckedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        [self.facebookFriendsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:scrollIndexPath.row inSection:scrollIndexPath.section] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        NSDictionary *facebookFriend = [self friendForIndexPath:indexPath];
        [self.selectedFriends removeObject:[NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"id"]]];
    } else {
        
    }
    
}

@end
