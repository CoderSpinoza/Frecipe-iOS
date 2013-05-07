//
//  FrecipeProfileViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeProfileViewController.h"
#import "FrecipeNavigationController.h"
#import "FrecipeAPIClient.h"
#import "FrecipeAppDelegate.h"
#import "FrecipeRecipeDetailViewController.h"
#import "FrecipeBadgeView.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface FrecipeProfileViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate, UIAlertViewDelegate, FrecipeRatingViewDelegate>

@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) NSDictionary *selectedRecipe;
//@property (strong, nonatomic) FrecipeRatingView *averageRatingView;


@end

@implementation FrecipeProfileViewController

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
    
    self.recipesCollectionView.dataSource = self;
    self.recipesCollectionView.delegate = self;
    
//    FrecipeRatingView *ratingView = (FrecipeRatingView *)[self.view viewWithTag:1];
//    ratingView.delegate = self;
    self.averageRatingView.delegate = self;
    [self fetchUserInfo];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.fromSegue == NO) {
        self.notificationBadge = [self addNotificationBadge];
    }
    
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

- (IBAction)revealMenu:(UIBarButtonItem *)sender {
    FrecipeNavigationController *navigationController = (FrecipeNavigationController *)self.navigationController;
    [navigationController revealMenu];
}

- (void)flipCell:(UITapGestureRecognizer *)tapGestureRecognizer {
    UITableViewCell *cell;
    
    UIView *view1;
    UIView *view2;
    if (tapGestureRecognizer.view.tag == 7) {
        cell = (UITableViewCell *)tapGestureRecognizer.view.superview.superview.superview;
        
        view1 = [cell viewWithTag:1];
        view2 = [cell viewWithTag:5];
        
    } else {
        cell = (UITableViewCell *)tapGestureRecognizer.view.superview.superview;
        view1 = [cell viewWithTag:5];
        view2 = [cell viewWithTag:1];
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        view1.alpha = 1.0;
        view2.alpha = 0;
    } completion:^(BOOL finished) {
    }];
}

//- (void)addAverageRatingView {
//    self.averageRatingView = [[FrecipeRatingView alloc] initWithFrame:CGRectMake(79, 50, 140, 16)];
//    self.averageRatingView.delegate = self;
//    [self.view addSubview:self.averageRatingView];
//}

- (void)fetchUserInfo {
    NSString *path = @"tokens/profile";
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    
    NSDictionary *parameters;
    if (self.userId) {
        NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"id", nil];
        NSArray *values = [NSArray arrayWithObjects:authentication_token, self.userId, nil];
        parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    } else {
        parameters = [NSDictionary dictionaryWithObject:authentication_token forKey:@"authentication_token"];
    }

    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height / 2);
    [spinner startAnimating];
    [self.view addSubview:spinner];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *user = [JSON objectForKey:@"user"];
        self.title = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
        
        NSString *provider = [NSString stringWithFormat:@"%@", [[JSON objectForKey:@"user"] objectForKey:@"provider"]];
        if ([provider isEqualToString:@"facebook"]) {
            self.profilePictureView.hidden = YES;
            self.fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [[JSON objectForKey:@"user"] objectForKey:@"uid"]];
        } else {
            self.fbProfilePictureView.hidden = YES;
            [self.profilePictureView setImageWithURL:[JSON objectForKey:@"profile_image"]];
            self.profilePictureView.alpha = 0;
            [UIView animateWithDuration:0.5 animations:^{
                self.profilePictureView.alpha = 1;
            }];
            
        }
        
        self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
        
        self.averageRatingView.rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"rating"]] integerValue];
        self.averageRatingView.editable = NO;
        
        self.recipes = [JSON objectForKey:@"recipes"];
        
        
        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"following"]] isEqualToString:@"You"]) {
            self.followButton.enabled = NO;
            self.followButton.hidden = YES;
        }
        [self.followButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"following"]] forState:UIControlStateNormal];
        
        NSDictionary *followers = [JSON objectForKey:@"followers"];
        NSDictionary *mostPopularRecipe = [JSON objectForKey:@"most"];
        self.numOfRecipesTitleLabel.text = [NSString stringWithFormat:@"%@'s RECIPES", [user objectForKey:@"first_name"]];
        
        self.numOfFollowersTitleLabel.text = @"FOLLOWERS";
        self.numOfLikesTitleLabel.text = @"TOTAL # of LIKES";
        self.popularRecipeTitleLabel.text = [NSString stringWithFormat:@"%@'s BEST", [user objectForKey:@"first_name"]];
        
        [self.numOfRecipesButton setTitle:[NSString stringWithFormat:@"%u", self.recipes.count] forState:UIControlStateNormal];
        [self.numOfFollowersButton setTitle:[NSString stringWithFormat:@"%u", followers.count] forState:UIControlStateNormal];
        [self.numOfLikesButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
        
        if ([mostPopularRecipe respondsToSelector:@selector(objectForKey:)]) {
//            self.popularRecipeTitleLabel.text = [NSString stringWithFormat:@"%@", [mostPopularRecipe objectForKey:@"name"]];
            
            [self.popularRecipeButton setTitle:[NSString stringWithFormat:@" %@ (%@ likes)", [mostPopularRecipe objectForKey:@"name"], [JSON objectForKey:@"mostLikes"]] forState:UIControlStateNormal];
            
        } else {
            [self.popularRecipeButton setTitle:@"No recipes yet" forState:UIControlStateNormal];
            
        }
        
        [self.recipesCollectionView reloadData];
        
        
        if (self.recipes.count > 0) {
            self.recipesCollectionView.frame = CGRectMake(self.recipesCollectionView.frame.origin.x, self.recipesCollectionView.frame.origin.y, self.recipesCollectionView.frame.size.width, 160 * ceil((float)self.recipes.count / 2));
            
            if ([UIScreen mainScreen].bounds.size.height == 480) {
                NSLog(@"3.5");
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.recipesCollectionView.frame.origin.y + self.recipesCollectionView.frame.size.height + 108);
            } else {
                NSLog(@"4.0");
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.recipesCollectionView.frame.origin.y + self.recipesCollectionView.frame.size.height);
            }
            
        }
        
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Profile load error" message:@"There was an error loading profile. Retry?" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Cancel", nil];
        [alertView show];
        
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}

- (void)showFacebookFriendPicker {
    [self performSegueWithIdentifier:@"FacebookInvites" sender:self];
}

- (IBAction)inviteButtonPressed {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"How to Invite?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Contacts",nil];
    [actionSheet showInView:self.view];
}
- (IBAction)followButtonPressed:(UIButton *)sender {
    NSString *path = @"follows";
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"followId", nil];
    NSArray *values  = [NSArray arrayWithObjects:authentication_token, self.userId, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [self.followButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"message"]] forState:UIControlStateNormal];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    [operation start];
}

- (void)popViewControllerFromStack {
    [self.navigationController popViewControllerAnimated:YES];
}

// rating view delegate methods

- (void)ratingViewDidRate:(FrecipeRatingView *)ratingView rating:(NSInteger)rating {
    
}


// action sheet delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet.title isEqualToString:@"How to Invite?"]) {
        if (buttonIndex == 0) {
            [self showFacebookFriendPicker];
            
        } else if (buttonIndex == 1) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Facebook Invite" message:@"This feature is coming soon!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            [alertView show];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"RecipeDetail"]) {
        FrecipeRecipeDetailViewController *recipeDetailViewController = (FrecipeRecipeDetailViewController *) segue.destinationViewController;
        recipeDetailViewController.recipeId = [self.selectedRecipe objectForKey:@"id"];
    } else if ([segue.identifier isEqualToString:@"Profile"]) {
        FrecipeProfileViewController *profileViewController = (FrecipeProfileViewController *)segue.destinationViewController;
        
        NSDictionary *user = [self.selectedRecipe objectForKey:@"user"];
        profileViewController.userId  = [NSString stringWithFormat:@"%@", [user objectForKey:@"id"]];        
    }
}

// alert view delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Profile load error"]) {
        if (buttonIndex == 0) {
            [self fetchUserInfo];
        }
    }
}

// collection view methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.recipes.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RecipeCell" forIndexPath:indexPath];
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:6];
    if (PRODUCTION) {
        [recipeImageView setImageWithURL:[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    } else {
        [recipeImageView setImageWithURL:[NSString stringWithFormat:@"http://localhost:5000/%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"]] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    }
    
    UIView *flipView = [cell viewWithTag:1];
    UITapGestureRecognizer *flipGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCell:)];
    [flipView addGestureRecognizer:flipGestureRecognizer];
    //
    UIView *flipView2 = [cell viewWithTag:7];
    UITapGestureRecognizer *flipGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCell:)];
    [flipView2 addGestureRecognizer:flipGestureRecognizer2];
    
    UITextView *recipeNameView = (UITextView *)[cell viewWithTag:8];
    recipeNameView.text = [NSString stringWithFormat:@"%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_name"]];
    
    UILabel *recipeNameLabel = (UILabel *)[cell viewWithTag:2];
    UIButton *chefNameButton = (UIButton *)[cell viewWithTag:3];
    UITextView *missingIngredientsView = (UITextView *)[cell viewWithTag:4];
    recipeNameLabel.text = [NSString stringWithFormat:@"%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_name"]];
    NSArray *missingIngredients = [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"missing_ingredients"];
    NSDictionary *user = [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"user"];
    
    [chefNameButton setTitle:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forState:UIControlStateNormal];
    
    NSMutableArray *missingIngredientsStringArray = [[NSMutableArray alloc] init];
    for (NSDictionary *missIng in missingIngredients) {
        [missingIngredientsStringArray addObject:[missIng objectForKey:@"name"]];
    }
    NSString *missingIngredientsString = [missingIngredientsStringArray componentsJoinedByString:@", "];
    missingIngredientsView.text = [NSString stringWithFormat:@"%u Missing Ingredients: %@", missingIngredients.count, missingIngredientsString];
    
    // chef name button, missing ingredients, and likes on front view
    
    UIButton *frontNameButton = (UIButton *)[cell viewWithTag:11];
    [frontNameButton setTitle:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forState:UIControlStateNormal];
    [frontNameButton sizeToFit];
    frontNameButton.frame = CGRectMake(160 - [frontNameButton.titleLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:13]].width - 7, frontNameButton.frame.origin.y, frontNameButton.frame.size.width, frontNameButton.frame.size.height);
    
    UILabel *likesLabel = (UILabel *)[cell viewWithTag:9];
    likesLabel.text = [NSString stringWithFormat:@"%@ likes", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"likes"]];
    
    UIButton *missingIngredientsButton = (UIButton *)[cell viewWithTag:12];
    [missingIngredientsButton setTitle:[NSString stringWithFormat:@"%u", missingIngredients.count] forState:UIControlStateNormal];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedRecipe = [self.recipes objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"RecipeDetail" sender:self];
}

@end
