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
#import "FrecipeRecipeDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface FrecipeProfileViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) NSDictionary *selectedRecipe;

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
    [self fetchUserInfo];
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
    if (tapGestureRecognizer.view.tag == 8) {
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
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    
    NSDictionary *parameters;
    if (self.userId) {
        NSLog(@"segue");
        NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"id", nil];
        NSArray *values = [NSArray arrayWithObjects:authentication_token, self.userId, nil];
        parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    } else {
        NSLog(@"profile");
        parameters = [NSDictionary dictionaryWithObject:authentication_token forKey:@"authentication_token"];
    }

    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height / 2);
    [spinner startAnimating];
    [self.view addSubview:spinner];
    NSLog(@"%@", parameters);
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *user = [JSON objectForKey:@"user"];
        self.title = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
        
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        NSString *provider = [defaults objectForKey:@"provider"];
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
        
        self.recipes = [JSON objectForKey:@"recipes"];
        
        
        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"following"]] isEqualToString:@"You"]) {
            self.followButton.enabled = NO;
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
        
//        self.numOfRecipesView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
//        self.numOfRecipesView.layer.borderWidth = 1;
//        self.numOfFollowersView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
//        self.numOfFollowersView.layer.borderWidth = 1;
//        self.numOfLikesView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
//        self.numOfLikesView.layer.borderWidth = 1;
//        self.mostPopularRecipeView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
//        self.mostPopularRecipeView.layer.borderWidth = 1;
        
        [self.recipesCollectionView reloadData];
        
        
        if (self.recipes.count > 0) {
//            self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.topView.frame.size.height + self.collectionView.frame.size.height * ceil((float) self.recipes.count / 2) + 524 - self.view.frame.size.height);
            
//            self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x, self.collectionView.frame.origin.y, self.collectionView.frame.size.width, self.collectionView.frame.size.height * ceil((float)self.recipes.count / 2));
        }
        
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        NSLog(@"%@", JSON);
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

//- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
//    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RecipeCell" forIndexPath:indexPath];
//    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:1];
//    if (PRODUCTION) {
//        [recipeImageView setImageWithURL:[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
//    } else {
//        [recipeImageView setImageWithURL:[NSString stringWithFormat:@"http://localhost:5000/%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"]] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
//    }
//    
//    UIView *flipView = [cell viewWithTag:3];
//    UITapGestureRecognizer *flipGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCell:)];
//    [flipView addGestureRecognizer:flipGestureRecognizer];
//    //
//    UIView *flipView2 = [cell viewWithTag:6];
//    UITapGestureRecognizer *flipGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCell:)];
//    [flipView2 addGestureRecognizer:flipGestureRecognizer2];
//    
//    UIView *frontView = [cell viewWithTag:4];
//    UIView *backView = [cell viewWithTag:6];
//    FrecipeRecipeCell *recipeCell = (FrecipeRecipeCell *)cell;
//    recipeCell.frontView = frontView;
//    recipeCell.backView = backView;
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        frontView.alpha = 1.0;
//        recipeImageView.alpha = 1.0;
//    }];
//    UITextView *recipeNameVIew = (UITextView *)[cell viewWithTag:3];
//    recipeNameVIew.text = [NSString stringWithFormat:@"%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_name"]];
//    
//    UILabel *recipeNameLabel = (UILabel *)[cell viewWithTag:8];
//    UIButton *chefNameButton = (UIButton *)[cell viewWithTag:9];
//    UITextView *missingIngredientsView = (UITextView *)[cell viewWithTag:10];
//    recipeNameLabel.text = [NSString stringWithFormat:@"%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_name"]];
//    NSArray *missingIngredients = [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"missing_ingredients"];
//    NSDictionary *user = [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"user"];
//    
//    [chefNameButton setTitle:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forState:UIControlStateNormal];
//    
//    NSMutableArray *missingIngredientsStringArray = [[NSMutableArray alloc] init];
//    for (NSDictionary *missIng in missingIngredients) {
//        [missingIngredientsStringArray addObject:[missIng objectForKey:@"name"]];
//    }
//    NSString *missingIngredientsString = [missingIngredientsStringArray componentsJoinedByString:@", "];
//    missingIngredientsView.text = [NSString stringWithFormat:@"%u Missing Ingredients: %@", missingIngredients.count, missingIngredientsString];
//    return cell;
//}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedRecipe = [self.recipes objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"RecipeDetail" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"RecipeDetail"]) {
        FrecipeRecipeDetailViewController *recipeDetailViewController = (FrecipeRecipeDetailViewController *) segue.destinationViewController;
        recipeDetailViewController.recipeId = [self.selectedRecipe objectForKey:@"id"];
    }
}


@end
