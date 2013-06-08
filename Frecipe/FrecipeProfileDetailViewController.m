//
//  FrecipeProfileDetailViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 30..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeProfileDetailViewController.h"
#import "FrecipeAPIClient.h"

@interface FrecipeProfileDetailViewController ()

@end

@implementation FrecipeProfileDetailViewController

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
    if ([self.segueIdentifier isEqualToString:@"Followers"] || [self.segueIdentifier isEqualToString:@"Following"]) {
        [self fetchUsers];
    } else if ([self.segueIdentifier isEqualToString:@"Likes"] || [self.segueIdentifier isEqualToString:@"Liked"]) {
        [self fetchRecipes];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchUsers {
    NSString *path;
    if ([self.segueIdentifier isEqualToString:@"Followers"]) {
        path = @"tokens/followers";
    } else {
        path = @"tokens/following";
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:authentication_token, @"authentication_token", nil];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"%@", JSON);
        self.users = [JSON objectForKey:@"users"];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
    
    
}

- (void)fetchRecipes {
    NSString *path;
    if ([self.segueIdentifier isEqualToString:@"Likes"]) {
        path = @"tokens/likes";
    } else {
        path = @"tokens/liked";
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:authentication_token, @"authentication_token", nil];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.recipes = [JSON objectForKey:@"recipes"];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

@end
