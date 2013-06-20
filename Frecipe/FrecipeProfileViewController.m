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
#import <UIImageView+WebCache.h>

@interface FrecipeProfileViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate, UIAlertViewDelegate, FrecipeRatingViewDelegate, UIScrollViewDelegate> {
    int shownRecipes;
}

@property (strong, nonatomic) NSDictionary *user;
@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) NSDictionary *selectedRecipe;
@property (strong, nonatomic) NSDictionary *mostPopularRecipe;
@property (strong, nonatomic) NSMutableArray *ingredients;

@end

@implementation FrecipeProfileViewController

@synthesize recipes = _recipes;

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
    self.scrollView.delegate = self;
    
    
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
    if (tapGestureRecognizer.view.tag == 12) {
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

- (void)fetchUserInfo {
    NSString *path = @"tokens/profile";
    
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

    FrecipeSpinnerView *spinnerView = [[FrecipeSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [spinnerView.spinner startAnimating];
    spinnerView.center = self.view.center;
    [self.view addSubview:spinnerView];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *user = [JSON objectForKey:@"user"];
        self.user = user;
        self.title = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
        
        NSString *provider = [NSString stringWithFormat:@"%@", [[JSON objectForKey:@"user"] objectForKey:@"provider"]];
        if ([provider isEqualToString:@"facebook"]) {
            self.profilePictureView.hidden = YES;
            self.fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [[JSON objectForKey:@"user"] objectForKey:@"uid"]];
        } else {
            self.inviteButton.enabled = NO;
            self.fbProfilePictureView.hidden = YES;
            if (PRODUCTION) {
                [self.profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"profile_image"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
                
            } else {
                [self.profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5000/%@", [JSON objectForKey:@"profile_image"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
            }
            
//            self.profilePictureView.alpha = 0;
//            [UIView animateWithDuration:0.5 animations:^{
//                self.profilePictureView.alpha = 1;
//            }];
        }
        
        self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
        
        self.averageRatingView.rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"rating"]] floatValue];
        self.averageRatingView.editable = NO;        
        
        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"follow"]] isEqualToString:@"You"]) {
            self.followButton.enabled = NO;
            self.followButton.hidden = YES;
            
            // make a bar button on the left for edit profile
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(segueToEditProfile)];
        }
        
        [self.followButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"follow"]] forState:UIControlStateNormal];
        
        NSDictionary *followers = [JSON objectForKey:@"followers"];
        NSArray *mostPopularRecipe = [NSArray arrayWithArray:[JSON objectForKey:@"most"]];
        self.popularRecipeTitleLabel.text = [NSString stringWithFormat:@"%@'s BEST", [user objectForKey:@"first_name"]];
        
        NSMutableArray *recipes = [NSMutableArray arrayWithArray:[JSON objectForKey:@"recipes"]];
        [self.numOfRecipesButton setTitle:[NSString stringWithFormat:@"%u", recipes.count] forState:UIControlStateNormal];
        [self.numOfFollowersButton setTitle:[NSString stringWithFormat:@"%u", followers.count] forState:UIControlStateNormal];
        [self.numOfLikesButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
        
        NSDictionary *following = [JSON objectForKey:@"following"];
        NSDictionary *liked = [JSON objectForKey:@"liked"];
        [self.numOfFollowingButton setTitle:[NSString stringWithFormat:@"%u", following.count] forState:UIControlStateNormal];
        [self.numOfLikedButton setTitle:[NSString stringWithFormat:@"%u", liked.count] forState:UIControlStateNormal];
        
        if (mostPopularRecipe.count > 0) {
            NSDictionary *popularRecipe = [mostPopularRecipe objectAtIndex:0];
            [self.popularRecipeButton setTitle:[NSString stringWithFormat:@"%@", [popularRecipe objectForKey:@"name"]] forState:UIControlStateNormal];
            self.popularRecipeLikesButton.text = [NSString stringWithFormat:@"%@ likes", [popularRecipe objectForKey:@"likes_count"]];
            
            self.mostPopularRecipe = popularRecipe;
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
        
        
        // recipes
        self.ingredients = [NSMutableArray arrayWithArray:[JSON objectForKey:@"ingredients"]];
        
        self.recipes = [[NSMutableArray alloc] initWithCapacity:recipes.count];
        [recipes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSMutableDictionary *recipe = (NSMutableDictionary *)obj;
            
            NSMutableArray *recipeIngredients = [[[NSString stringWithFormat:@"%@", [recipe objectForKey:@"ingredients_string"]] componentsSeparatedByString:@","] mutableCopy];
            [recipeIngredients removeObjectsInArray:self.ingredients];
            
            NSArray *keys = [NSArray arrayWithObjects:@"id", @"name", @"user_id", @"username", @"likes", @"ingredients", @"recipe_image",  nil];
            NSArray *values = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@", [recipe objectForKey:@"recipe_id"]], [NSString stringWithFormat:@"%@", [recipe objectForKey:@"name"]], [NSString stringWithFormat:@"%@", [recipe objectForKey:@"user_id"]], [NSString stringWithFormat:@"%@ %@", [recipe objectForKey:@"first_name"], [recipe objectForKey:@"last_name"]], [NSString stringWithFormat:@"%@", [recipe objectForKey:@"likes_count"]], recipeIngredients, [NSString stringWithFormat:@"%@", [recipe objectForKey:@"recipe_image_file_name"]], nil];
            NSDictionary *recipe2 = [NSDictionary dictionaryWithObjects:values forKeys:keys];
            
            [self.recipes addObject:recipe2];
        }];
        [self.recipesCollectionView reloadData];
        
        //ceil((float)self.recipes.count / 2
        if (self.recipes.count > 0) {
            self.recipesCollectionView.frame = CGRectMake(self.recipesCollectionView.frame.origin.x, self.detailInfoView.frame.origin.y + self.detailInfoView.frame.size.height + 10, self.recipesCollectionView.frame.size.width, 150 * MIN(ceil((float)self.recipes.count / 2), 3));
            shownRecipes = 2;
            [self.recipesCollectionView setBasicShadow];
            if ([self isTall]) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.recipesCollectionView.frame.origin.y + self.recipesCollectionView.frame.size.height + 30);
            } else {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.recipesCollectionView.frame.origin.y + self.recipesCollectionView.frame.size.height + 118);
            }
        } else {
            self.recipesCollectionView.hidden = YES;
        }
        
        // set shadows after framing
        [self.basicInfoView setBasicShadow];
        [self.detailInfoView setBasicShadow];
        [self.websiteAndAboutView setBasicShadow];
        
        [spinnerView.spinner stopAnimating];
        [spinnerView removeFromSuperview];

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

        [spinnerView.spinner stopAnimating];
        [spinnerView removeFromSuperview];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Profile load error" message:@"There was an error loading profile. Retry?" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Cancel", nil];
        [alertView show];
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (void)showFacebookFriendPicker {
    [self performSegueWithIdentifier:@"FacebookInvites" sender:self];
}

- (IBAction)recipesButtonPressed {
    
    CGPoint point;
    if (self.recipes.count > 0) {
        if (self.recipes.count > 4) {
            point = CGPointMake(0, self.recipesCollectionView.frame.origin.y - 20);
        } else {
            point = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
        }
        [UIView animateWithDuration:0.5 animations:^{
            self.scrollView.contentOffset = point;
        }];
    }
}

- (IBAction)inviteButtonPressed {
    [self showFacebookFriendPicker];
}
- (IBAction)followButtonPressed:(UIButton *)sender {
    NSString *path = @"follows";
    
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
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
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
            NSLog(@"done");
            destinationViewController.fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"uid"]];            
        }
    } else if ([segue.identifier isEqualToString:@"Profile2"] ) {
        FrecipeProfileViewController *destinationViewController = (FrecipeProfileViewController *)segue.destinationViewController;
        destinationViewController.userId = [NSString stringWithFormat:@"%@", [self.selectedUser objectForKey:@"id"]];
        destinationViewController.fromSegue = YES;
        
        destinationViewController.navigationItem.leftBarButtonItem = nil;

        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(popViewControllerFromStack)];
    } else if ([identifiers containsObject:segue.identifier]) {
        
        FrecipeProfileDetailViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.segueIdentifier = segue.identifier;
        destinationViewController.user = self.user;
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
    recipeImageView.image = nil;
    if (PRODUCTION) {
        [recipeImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/recipes/%@/%@",[self s3BucketURL], [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"id"], [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"]]] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    } else {
        [recipeImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5000/image/recipes/%@/%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"id"], [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"]]] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    }
    

    UITextView *recipeNameView = (UITextView *)[cell viewWithTag:8];
    recipeNameView.text = [NSString stringWithFormat:@"%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"name"]];
    UILabel *recipeNameLabel = (UILabel *)[cell viewWithTag:2];
    recipeNameLabel.text = [NSString stringWithFormat:@"%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_name"]];
    
    UIButton *chefNameButton = (UIButton *)[cell viewWithTag:3];
    [chefNameButton setTitle:[NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"name"]] forState:UIControlStateNormal];
    
    // chef name button, missing ingredients, and likes on front view
    
    UIButton *frontNameButton = (UIButton *)[cell viewWithTag:11];
    [frontNameButton setTitle:[NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"name"]] forState:UIControlStateNormal];
    [frontNameButton sizeToFit];
    frontNameButton.frame = CGRectMake(cell.frame.size.width - [frontNameButton.titleLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:13]].width - 7, frontNameButton.frame.origin.y, frontNameButton.frame.size.width, frontNameButton.frame.size.height);
    
    UILabel *likesLabel = (UILabel *)[cell viewWithTag:9];
    likesLabel.text = [NSString stringWithFormat:@"%@ likes", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"likes"]];
    
    UITextView *missingIngredientsView = (UITextView *)[cell viewWithTag:4];
    UIButton *missingIngredientsButton = (UIButton *)[cell viewWithTag:12];
    NSArray *missingIngredients = [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"ingredients"];
    missingIngredientsView.text = [NSString stringWithFormat:@"%u Missing Ingredients: %@", missingIngredients.count, [missingIngredients componentsJoinedByString:@","]];
    
    if (missingIngredients.count == 0) {
        missingIngredientsButton.hidden = YES;
    } else {
        missingIngredientsButton.hidden = NO;
        missingIngredientsButton.selected = NO;
        [missingIngredientsButton setTitle:[NSString stringWithFormat:@"%u", missingIngredients.count] forState:UIControlStateNormal];
    }
    
    // add a gesture recognizer when there isn't one.
    UIView *flipView = [cell viewWithTag:1];
    if (flipView.gestureRecognizers.count == 0) {
        UITapGestureRecognizer *flipGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCell:)];
        [flipView addGestureRecognizer:flipGestureRecognizer];
    }
    UIView *flipView2 = [cell viewWithTag:12];
    if (flipView2.gestureRecognizers.count == 0) {
        UITapGestureRecognizer *flipGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCell:)];
        [flipView2 addGestureRecognizer:flipGestureRecognizer2];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedRecipe = [self.recipes objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"RecipeDetail" sender:self];
}

// scroll view delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.scrollView]) {
        if (scrollView.contentOffset.y + self.view.frame.size.height + 10 > scrollView.contentSize.height && scrollView.contentSize.height < self.recipesCollectionView.frame.origin.y + 150 * ceil((float)self.recipes.count / 2) + 10) {
            
            scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, self.view.frame.size.height + scrollView.contentOffset.y + 30);
            self.recipesCollectionView.frame = CGRectMake(self.recipesCollectionView.frame.origin.x, self.recipesCollectionView.frame.origin.y, self.recipesCollectionView.frame.size.width, self.scrollView.contentSize.height - self.recipesCollectionView.frame.origin.y - 10);
        }
    }
}

@end
