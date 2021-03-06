//
//  FrecipeMainViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 6..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeMainViewController.h"
#import "FrecipeAPIClient.h"
#import "FrecipeRecipeDetailViewController.h"
#import "FrecipeProfileViewController.h"
#import "FrecipeLeaderboardViewController.h"

@interface FrecipeMainViewController ()
@property (strong, nonatomic) NSString *commentId;

@end

@implementation FrecipeMainViewController

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
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.commentId = nil;
    self.notificationBadge = [self addNotificationBadge];
    [self fetchNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.notificationBadge removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (FrecipeBadgeView *)addNotificationBadge {
    FrecipeBadgeView *badgeView = [FrecipeBadgeView customBadgeWithString:@"0"];
    badgeView.frame = CGRectMake(25, badgeView.frame.origin.y, badgeView.frame.size.width, badgeView.frame.size.height);
    [self.navigationController.navigationBar addSubview:badgeView];
    return badgeView;
}

- (void)fetchNotifications {
    NSString *path = @"notifications/user";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:authentication_token forKey:@"authentication_token"];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSString *unseen = [NSString stringWithFormat:@"%@", [JSON objectForKey:@"unseen_count"]];
        
        self.notificationBadge.text = unseen;
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    [operation start];
}

- (void)performSegueWithNotification:(NSString *)category Target:(NSDictionary *)target CommentId:(NSString *)commentId{
    
    if ([category isEqualToString:@"like"]) {
        self.selectedRecipe = target;
        [self performSegueWithIdentifier:@"RecipeDetail" sender:self];
    } else if ([category isEqualToString:@"comment"]) {
        self.selectedRecipe = target;
        self.commentId = commentId;
        [self performSegueWithIdentifier:@"RecipeDetail" sender:self];
    } else if ([category isEqualToString:@"follow"]) {
        self.selectedUser = target;
        [self performSegueWithIdentifier:@"Profile2" sender:self];
    } else {
        self.selectedRecipe = target;
        [self performSegueWithIdentifier:@"RecipeDetail" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {    
    if ([segue.identifier isEqualToString:@"RecipeDetail"]) {
        FrecipeRecipeDetailViewController *recipeDetailViewController = (FrecipeRecipeDetailViewController *) segue.destinationViewController;
        
        recipeDetailViewController.commentId = self.commentId;
        recipeDetailViewController.recipeId = [self.selectedRecipe objectForKey:@"id"];
         recipeDetailViewController.navigationItem.leftBarButtonItem = nil;
    } else if ([segue.identifier isEqualToString:@"Profile"] || [segue.identifier isEqualToString:@"Profile2"]) {
        FrecipeProfileViewController *destinationViewController = (FrecipeProfileViewController *)segue.destinationViewController;
        destinationViewController.userId = [NSString stringWithFormat:@"%@", [self.selectedUser objectForKey:@"id"]];
        destinationViewController.fromSegue = YES;
        
        destinationViewController.navigationItem.leftBarButtonItem = nil;
    } else if ([segue.identifier isEqualToString:@"Leaderboard"]) {
        FrecipeLeaderboardViewController *destinationController = segue.destinationViewController;
        destinationController.fromFrecipe = YES;
        destinationController.navigationItem.leftBarButtonItem = nil;
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:segue.destinationViewController action:@selector(popViewControllerAnimated:)];
//    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(popViewControllerAnimated:)];
}


@end
