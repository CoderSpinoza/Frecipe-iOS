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

@end

@implementation FrecipeFacebookInviteViewController

@synthesize selectedFriends = _selectedFriends;

- (NSMutableArray *)selectedFriends {
    if (_selectedFriends == nil) {
        _selectedFriends = [[NSMutableArray alloc] init];
    }
    return _selectedFriends;
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
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
            
            NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
            self.facebookFriends = [[self.facebookFriends sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
            
            if (self.uids) {
                [self.facebookFriendsTableView reloadData];
            }
        }];
    }
    
}

@end
