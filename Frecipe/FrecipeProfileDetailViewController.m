//
//  FrecipeProfileDetailViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 30..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeProfileDetailViewController.h"
#import "FrecipeAPIClient.h"
#import "FrecipeAppDelegate.h"
#import "FrecipeProfileViewController.h"
#import "FrecipeRecipeDetailViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface FrecipeProfileDetailViewController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (strong, nonatomic) NSDictionary *selectedRecipe;
@property (strong, nonatomic) NSDictionary *selectedUser;

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
        self.recipesCollectionView.hidden = YES;
        self.usersTableView.dataSource = self;
        self.usersTableView.delegate = self;
        
    } else if ([self.segueIdentifier isEqualToString:@"Likes"] || [self.segueIdentifier isEqualToString:@"Liked"]) {
        [self fetchRecipes];
        self.usersTableView.hidden = YES;
        self.recipesCollectionView.dataSource = self;
        self.recipesCollectionView.delegate = self;
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

- (void)fetchUsers {
    NSString *path;

    if ([self.segueIdentifier isEqualToString:@"Followers"]) {
        path = [NSString stringWithFormat:@"tokens/followers/%@", [self.user objectForKey:@"id"]];
    } else {
        path = [NSString stringWithFormat:@"tokens/following/%@", [self.user objectForKey:@"id"]];
    }
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.users = [JSON objectForKey:@"users"];
        [self.usersTableView reloadData];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
    
    
}

- (void)fetchRecipes {
    NSString *path;
    if ([self.segueIdentifier isEqualToString:@"Likes"]) {
        path = [NSString stringWithFormat:@"tokens/likes/%@", [self.user objectForKey:@"id"]];
    } else {
        path = [NSString stringWithFormat:@"tokens/liked/%@", [self.user objectForKey:@"id"]];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:authentication_token, @"authentication_token", nil];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.recipes = [JSON objectForKey:@"recipes"];
        [self.recipesCollectionView reloadData];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (void)segueToProfile:(UIButton *)sender {
    UICollectionViewCell *cell = (UICollectionViewCell *)sender.superview.superview.superview;
    NSDictionary *user = [[self.recipes objectAtIndex:[self.recipesCollectionView indexPathForCell:cell].row] objectForKey:@"user"];
    self.selectedUser = user;
    [self performSegueWithIdentifier:@"Profile" sender:self];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Profile"]) {
        FrecipeProfileViewController *destinationViewController = (FrecipeProfileViewController *)segue.destinationViewController;
        destinationViewController.userId = [NSString stringWithFormat:@"%@", [self.selectedUser objectForKey:@"id"]];
        destinationViewController.navigationItem.leftBarButtonItem = nil;
    } else if ([segue.identifier isEqualToString:@"RecipeDetail"]) {
        FrecipeRecipeDetailViewController *destinationViewCotnroller = (FrecipeRecipeDetailViewController *)segue.destinationViewController;
        destinationViewCotnroller.recipeId = [self.selectedRecipe objectForKey:@"id"];
        destinationViewCotnroller.navigationItem.leftBarButtonItem = nil;
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStyleBordered target:segue.destinationViewController action:@selector(popViewControllerAnimated:)];
}

// table view dataSource methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UserCell"];
    }
    NSDictionary *user = [self.users objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
    
    FBProfilePictureView *fbProfilePictureView = (FBProfilePictureView *)[cell viewWithTag:1];
    NSString *provider = [user objectForKey:@"provider"];
    if ([[NSString stringWithFormat:@"%@", provider] isEqualToString:@"facebook"]) {
        cell.imageView.image = [UIImage imageNamed:@"default_profile_picture.png"];
        cell.imageView.hidden = YES;
        FBProfilePictureView *fbProfilePictureView = (FBProfilePictureView *)[cell viewWithTag:1];
        fbProfilePictureView.profileID = [user objectForKey:@"uid"];
    } else {
        fbProfilePictureView.hidden = YES;
        [cell.imageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [user objectForKey:@"profile_picture"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
    }
    return cell;
}

// table view delegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedUser = [self.users objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    
    [self performSegueWithIdentifier:@"Profile" sender:self];
}

// collection view dataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.recipes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RecipeCell" forIndexPath:indexPath];
    
    // setting the image view for the cell using AFNetworking. Does this do caching automatically?
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:6];
    recipeImageView.image = nil;
    if (PRODUCTION) {
        [recipeImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"]]] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"]];
    } else {
        [recipeImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5000/%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"]]] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"]];
    }
    
    
    // configure the back of the cell. fill all the info.
    UITextView *recipeNameView = (UITextView *)[cell viewWithTag:8];
    recipeNameView.text = [NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_name"]];
    
    UILabel *recipeNameLabel = (UILabel *)[cell viewWithTag:2];
    recipeNameLabel.text = [NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_name"]];
    
    NSDictionary *user = [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"user"];
    UIButton *chefNameButton = (UIButton *)[cell viewWithTag:3];
    [chefNameButton setTitle:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forState:UIControlStateNormal];
    
    NSMutableArray *missingIngredientsStringArray = [[NSMutableArray alloc] init];
    NSArray *missingIngredients = [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"missing_ingredients"];
    for (NSDictionary *missingIngredient in missingIngredients) {
        [missingIngredientsStringArray addObject:[missingIngredient objectForKey:@"name"]];
    }
    NSString *missingIngredientsString = [missingIngredientsStringArray componentsJoinedByString:@","];
    
    UITextView *missingIngredientsView = (UITextView *)[cell viewWithTag:4];
    missingIngredientsView.text = [NSString stringWithFormat:@"%u Missing Ingredients: %@", missingIngredients.count, missingIngredientsString];
    
    // configure the front of the cell. chef name button and missing ingredients and likes on front view
    UIButton *frontNameButton = (UIButton *)[cell viewWithTag:11];
    [frontNameButton setTitle:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forState:UIControlStateNormal];
    [frontNameButton sizeToFit];
    frontNameButton.frame = CGRectMake(160 - [frontNameButton.titleLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:13]].width - 7, frontNameButton.frame.origin.y, frontNameButton.frame.size.width, frontNameButton.frame.size.height);
    
    [frontNameButton addTarget:self action:@selector(segueToProfile:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *likesLabel = (UILabel *)[cell viewWithTag:9];
    likesLabel.text = [NSString stringWithFormat:@"%@ likes", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"likes"]];
    
    UIButton *missingIngredientsButton = (UIButton *)[cell viewWithTag:12];
    if (missingIngredients.count == 0) {
        missingIngredientsButton.hidden = YES;
    } else {
        missingIngredientsButton.hidden = NO;
        missingIngredientsButton.selected = NO;
        [missingIngredientsButton setTitle:[NSString stringWithFormat:@"%u", missingIngredients.count] forState:UIControlStateNormal];
    }
    
    // make back view invisible.
    UIView *backView = [cell viewWithTag:1];
    UIView *frontView = [cell viewWithTag:5];
    frontView.alpha = 1.0;
    backView.alpha = 0;
    
    // adding flip gesture recognizers
    UIView *flipView1 = [cell viewWithTag:12];
    UIView *flipView2 = [cell viewWithTag:1];
    
    if (flipView1.gestureRecognizers.count == 0) {
        UITapGestureRecognizer *flipGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCell:)];
        [flipView1 addGestureRecognizer:flipGestureRecognizer1];
    }
    
    if (flipView2.gestureRecognizers.count == 0) {
        UITapGestureRecognizer *flipGestureRecognizer2 =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCell:)];
        [flipView2 addGestureRecognizer:flipGestureRecognizer2];
    }

    return cell;
}

// collection view delegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedRecipe = [self.recipes objectAtIndex:indexPath.row];
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.selected = NO;
    
    [self performSegueWithIdentifier:@"RecipeDetail" sender:self];
}
@end
