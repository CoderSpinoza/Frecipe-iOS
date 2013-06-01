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
#import "FrecipeEditProfileViewController.h"
#import "FrecipeProfileDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface FrecipeProfileViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate, UIAlertViewDelegate, FrecipeRatingViewDelegate>

@property (strong, nonatomic) NSDictionary *user;
@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) NSDictionary *selectedRecipe;
@property (strong, nonatomic) NSDictionary *mostPopularRecipe;
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
    
    self.basicInfoView.layer.cornerRadius = 3.0f;
    self.detailInfoView.layer.cornerRadius = 3.0f;
    self.websiteAndAboutView.layer.cornerRadius = 3.0f;
    self.detailInfoView.clipsToBounds = YES;
    
    self.averageRatingView.delegate = self;
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.fromSegue == NO) {
        self.notificationBadge = [self addNotificationBadge];
    }
    [self fetchUserInfo];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [self.notificationBadge removeFromSuperview];
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
        self.user = user;
    
        [self saveUserInfo:self.user Token:nil ProfilePicture:nil];
        
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
        
        self.averageRatingView.rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"rating"]] floatValue];
        self.averageRatingView.editable = NO;
        
        self.recipes = [JSON objectForKey:@"recipes"];
        
        
        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"follow"]] isEqualToString:@"You"]) {
            self.followButton.enabled = NO;
            self.followButton.hidden = YES;
            
            // make a bar button on the left for edit profile
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(segueToEditProfile)];
        }
        [self.followButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"follow"]] forState:UIControlStateNormal];
        
        NSDictionary *followers = [JSON objectForKey:@"followers"];
        NSDictionary *mostPopularRecipe = [JSON objectForKey:@"most"];
        
        self.popularRecipeTitleLabel.text = [NSString stringWithFormat:@"%@'s BEST", [user objectForKey:@"first_name"]];
        
        [self.numOfRecipesButton setTitle:[NSString stringWithFormat:@"%u", self.recipes.count] forState:UIControlStateNormal];
        [self.numOfFollowersButton setTitle:[NSString stringWithFormat:@"%u", followers.count] forState:UIControlStateNormal];
        [self.numOfLikesButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
        
        NSDictionary *following = [JSON objectForKey:@"following"];
        NSDictionary *liked = [JSON objectForKey:@"liked"];
        [self.numOfFollowingButton setTitle:[NSString stringWithFormat:@"%u", following.count] forState:UIControlStateNormal];
        [self.numOfLikedButton setTitle:[NSString stringWithFormat:@"%u", liked.count] forState:UIControlStateNormal];
        
        if ([mostPopularRecipe respondsToSelector:@selector(objectForKey:)]) {
            [self.popularRecipeButton setTitle:[NSString stringWithFormat:@"%@", [mostPopularRecipe objectForKey:@"name"]] forState:UIControlStateNormal];
            self.popularRecipeLikesButton.text = [NSString stringWithFormat:@"%@ likes", [JSON objectForKey:@"mostLikes"]];
            
            self.mostPopularRecipe = mostPopularRecipe;
            [self.popularRecipeButton addTarget:self action:@selector(goToRecipeDetail) forControlEvents:UIControlEventTouchUpInside];
        } else {
            [self.popularRecipeButton setTitle:@"No recipes yet" forState:UIControlStateNormal];
        }
        
        // set website and about view
        self.websiteTextView.text = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"website"]];
        self.aboutTextView.text = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"about"]];
        
        [self.aboutTextView sizeToFit];
        CGFloat height = [self.aboutTextView.text sizeWithFont:[UIFont systemFontOfSize:12.0f] constrainedToSize:CGSizeMake(280.0f, MAXFLOAT)].height;
        if (height < 50) {
            height = 50;
        } else {
            height += 10;
        }
        self.aboutTextView.frame = CGRectMake(self.aboutTextView.frame.origin.x, self.aboutTextView.frame.origin.y, self.aboutTextView.frame.size.width, height);
        self.separatorView.frame = CGRectMake(self.separatorView.frame.origin.x, self.aboutTextView.frame.origin.y + self.aboutTextView.frame.size.height + 5, self.separatorView.frame.size.width, self.separatorView.frame.size.height);
        self.websiteLabel.frame = CGRectMake(self.websiteLabel.frame.origin.x, self.separatorView.frame.origin.y + self.separatorView.frame.size.height, self.websiteLabel.frame.size.width, self.websiteLabel.frame.size.height);
        self.websiteTextView.frame = CGRectMake(self.websiteTextView.frame.origin.x, self.websiteLabel.frame.origin.y + 10, self.websiteTextView.frame.size.width, self.websiteTextView.frame.size.height);
        self.websiteAndAboutView.frame = CGRectMake(self.websiteAndAboutView.frame.origin.x, self.websiteAndAboutView.frame.origin.y, self.websiteAndAboutView.frame.size.width, self.websiteTextView.frame.origin.y + self.websiteTextView.frame.size.height + 10);
        
        self.detailInfoView.frame = CGRectMake(self.detailInfoView.frame.origin.x, self.websiteAndAboutView.frame.origin.y + self.websiteAndAboutView.frame.size.height + 10, self.detailInfoView.frame.size.width, self.detailInfoView.frame.size.height);
        [self.recipesCollectionView reloadData];
        
        
        if (self.recipes.count > 0) {
            self.recipesCollectionView.frame = CGRectMake(self.recipesCollectionView.frame.origin.x, self.detailInfoView.frame.origin.y + self.detailInfoView.frame.size.height + 10, self.recipesCollectionView.frame.size.width, 150 * ceil((float)self.recipes.count / 2));
            [self.recipesCollectionView setBasicShadow];
            if ([self isTall]) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.recipesCollectionView.frame.origin.y + self.recipesCollectionView.frame.size.height + 30);
            } else {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.recipesCollectionView.frame.origin.y + self.recipesCollectionView.frame.size.height + 118);
            }
        }
        
        // set shadows after framing
        [self.basicInfoView setBasicShadow];
        [self.detailInfoView setBasicShadow];
        [self.websiteAndAboutView setBasicShadow];
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Profile load error" message:@"There was an error loading profile. Retry?" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Cancel", nil];
        [alertView show];
        NSLog(@"%@", error);
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

- (void)goToRecipeDetail {
    self.selectedRecipe = self.mostPopularRecipe;
    [self performSegueWithIdentifier:@"RecipeDetail" sender:self];
}

- (void)segueToEditProfile {
    [self performSegueWithIdentifier:@"EditProfile" sender:self];
}

- (void)popViewControllerFromStack {
    [self.navigationController popViewControllerAnimated:YES];
}

// rating view delegate methods

- (void)ratingViewDidRate:(FrecipeRatingView *)ratingView rating:(CGFloat)rating {
    
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
    NSArray *identifiers = [NSArray arrayWithObjects:@"Recipes", @"Followers", @"Likes", @"Following", @"Liked", nil];
    if ([segue.identifier isEqualToString:@"RecipeDetail"]) {
        FrecipeRecipeDetailViewController *recipeDetailViewController = (FrecipeRecipeDetailViewController *) segue.destinationViewController;
        recipeDetailViewController.recipeId = [self.selectedRecipe objectForKey:@"id"];
        
        recipeDetailViewController.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(popViewControllerFromStack)];
    } else if ([segue.identifier isEqualToString:@"Profile"]) {
        FrecipeProfileViewController *profileViewController = (FrecipeProfileViewController *)segue.destinationViewController;
        
        NSDictionary *user = [self.selectedRecipe objectForKey:@"user"];
        profileViewController.userId  = [NSString stringWithFormat:@"%@", [user objectForKey:@"id"]];        
    } else if ([segue.identifier isEqualToString:@"EditProfile"]) {
        FrecipeEditProfileViewController *destinationViewController = (FrecipeEditProfileViewController *)segue.destinationViewController;
        
        if (destinationViewController.view) {
            destinationViewController.profilePictureView.image = self.profilePictureView.image;
            destinationViewController.fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"uid"]];
        }
    } else if ([identifiers containsObject:segue.identifier]) {
        
        FrecipeProfileDetailViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.segueIdentifier = segue.identifier;
        destinationViewController.title = [NSString stringWithFormat:@"%@ %@'s %@", [self.user objectForKey:@"first_name"], [self.user objectForKey:@"last_name"], segue.identifier];
        destinationViewController.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(popViewControllerFromStack)];
        if ([segue.identifier isEqualToString:@"Recipes"]) {
        } else if ([segue.identifier isEqualToString:@"Followers"]) {
            
        } else if ([segue.identifier isEqualToString:@"Likes"]) {
            
        } else if ([segue.identifier isEqualToString:@"Following"]) {
            
        } else if ([segue.identifier isEqualToString:@"Liked"]) {
            
        }
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
    frontNameButton.frame = CGRectMake(cell.frame.size.width - [frontNameButton.titleLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:13]].width - 7, frontNameButton.frame.origin.y, frontNameButton.frame.size.width, frontNameButton.frame.size.height);
    
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
