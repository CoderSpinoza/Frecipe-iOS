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

@interface FrecipeFacebookInviteViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (strong, nonatomic) NSMutableArray *facebookFriends;
@property (strong, nonatomic) NSMutableArray *uids;
@property (strong, nonatomic) NSMutableArray *selectedFriends;
@property (strong, nonatomic) NSArray *alphabets;
@property (strong, nonatomic) NSMutableArray *searchedFriends;
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
    
    self.facebookFriendsTableView.delegate = self;
    self.facebookFriendsTableView.dataSource = self;
    
    self.searchDisplayController.delegate = self;
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchBar.delegate = self;
    
    [self loadFacebookFriends];
    [self loadFacebookUids];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadFacebookUids {
    NSString *path = @"tokens/facebookAccounts";
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        
        
        self.uids = [NSMutableArray arrayWithArray:JSON];
        if (self.facebookFriends) {
            [self.facebookFriendsTableView reloadData];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        
    }];
    [operation start];
}

- (void)loadFacebookFriends {
    
    if (FBSession.activeSession) {
        if (!FBSession.activeSession.isOpen) {
            [FBSession openActiveSessionWithAllowLoginUI:NO];
        }
        
        FBRequest *request = [FBRequest requestForMyFriends];
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            self.facebookFriends = [NSMutableArray arrayWithArray:[result objectForKey:@"data"]];
            NSLog(@"%u", self.facebookFriends.count);
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
            
            NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
            self.facebookFriends = [[self.facebookFriends sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
            NSLog(@"%u", self.facebookFriends.count);
            if (self.uids) {
                [self.facebookFriendsTableView reloadData];
            }
        }];
    }
    
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)inviteButtonPressed:(UIBarButtonItem *)sender {
    NSArray *keys = [NSArray arrayWithObjects:@"message", @"to", nil];
    NSArray *values = [NSArray arrayWithObjects:@"Frecipe Request", [self.selectedFriends componentsJoinedByString:@","], nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil message:nil title:nil parameters:parameters handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
        if (!error) {
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
        }
        
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"first_name beginswith[c] %@", [self.alphabets objectAtIndex:indexPath.section]];
        NSArray *filteredFriends = [self.facebookFriends filteredArrayUsingPredicate:filterPredicate];
        NSDictionary *facebookFriend = [filteredFriends objectAtIndex:indexPath.row];
        
        
        FBProfilePictureView *profilePictureView = (FBProfilePictureView *)[cell viewWithTag:1];
        
        UILabel *nameLabel = (UILabel *)[cell viewWithTag:2];
        
        profilePictureView.profileID = [NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"id"]];
        nameLabel.text = [NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"name"]];
        
        
        if ([self.selectedFriends containsObject:[facebookFriend objectForKey:@"id"]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;

    } else {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [self.facebookFriendsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        }
        
        // Configure the cell...
        
        NSDictionary *facebookFriend = [self.searchedFriends objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [facebookFriend objectForKey:@"first_name"], [facebookFriend objectForKey:@"last_name"]];
        
        cell.imageView.image = [UIImage imageNamed:@"default_profile_picture.png"];
        FBProfilePictureView *profilePictureView = [[FBProfilePictureView alloc] initWithProfileID:[NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"uid"]] pictureCropping:FBProfilePictureCroppingSquare];
        profilePictureView.frame = CGRectMake(0, 0, 44, 44);
        [cell addSubview:profilePictureView];
        cell.imageView.hidden = YES;
        
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        NSDictionary *facebookFriend = [self.facebookFriends objectAtIndex:indexPath.row];
        
        [self.selectedFriends addObject:[NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"id"]]];
    } else {
        
    }
    
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if ([tableView isEqual:self.facebookFriendsTableView]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        NSDictionary *facebookFriend = [self.facebookFriends objectAtIndex:indexPath.row];
        [self.selectedFriends removeObject:[NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"id"]]];
    } else {
        
    }
    
}

@end
