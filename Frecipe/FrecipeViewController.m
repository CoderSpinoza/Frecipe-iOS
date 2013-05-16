//
//  FrecipeViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeViewController.h"
#import "FrecipeNavigationController.h"
#import "FrecipeAPIClient.h"
#import "FrecipeAppDelegate.h"
#import "FrecipeRecipeDetailViewController.h"
#import "FrecipeProfileViewController.h"
#import "FrecipeBadgeView.h"
#import "FrecipeFunctions.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface FrecipeViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate>

@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSDictionary *selectedRecipe;
@property (strong, nonatomic) NSString *selectedUserId;
@property (strong, nonatomic) NSMutableArray *facebookFriendsIds;
@property (strong, nonatomic) NSMutableArray *facebookFriends;
@property (nonatomic, assign) BOOL alreadyLoaded;

@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UISearchBar *recipeSearchBar;


@end

@implementation FrecipeViewController

@synthesize facebookFriendsIds = _facebookFriendsIds;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"frecipe_name.png"]];
    
    self.recipesCollectionView.dataSource = self;
    self.recipesCollectionView.delegate = self;
    
    [self addRefreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchRecipes];
    [self fetchFacebookFriends];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.selectedRecipe = nil;
    self.selectedUser = nil;
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

- (void)setupHeaderView {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.recipeSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    
    [self.headerView addSubview:self.recipeSearchBar];
//    self.recipesCollectionView.
}


- (void)fetchRecipes {
    NSString *path = @"/recipes/possible";
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:authentication_token forKey:@"authentication_token"];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.center = self.view.center;
    [spinner startAnimating];
    [self.view addSubview:spinner];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.recipes = JSON;
        
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Last updated on %@", [FrecipeFunctions currentDate]]];
        
        
        if (self.facebookFriends) {
            [self.recipesCollectionView reloadData];
            self.alreadyLoaded = YES;
        }
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        [self.refreshControl endRefreshing];
        
    
        
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        [self.refreshControl endRefreshing];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error loading recipes. Retry?" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Cancel", nil];
        
        [alertView show];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}

- (void)fetchFacebookFriends {
    if (!FBSession.activeSession.isOpen) {
        [FBSession openActiveSessionWithAllowLoginUI:NO];
    }
    
    FBRequest *request = [FBRequest requestForMyFriends];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        self.facebookFriends = [NSMutableArray arrayWithArray:[result objectForKey:@"data"]];
        for (NSDictionary *facebookFriend in self.facebookFriends) {
            [self.facebookFriendsIds addObject:[NSString stringWithFormat:@"%@", [facebookFriend objectForKey:@"id"]]];
        }
        if (self.recipes) {
            [self.recipesCollectionView reloadData];
        }
    }];
}

- (void)flipCell:(UITapGestureRecognizer *)tapGestureRecognizer {
    UITableViewCell *cell;

    UIView *view1;
    UIView *view2;
    if (tapGestureRecognizer.view.tag == 10) {
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

- (void)addRefreshControl {
    // pull to refresh
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(fetchRecipes) forControlEvents:UIControlEventValueChanged];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull down to refresh recipes!"];
    [self.recipesCollectionView addSubview:refreshControl];
    self.refreshControl = refreshControl;
    self.recipesCollectionView.alwaysBounceVertical = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"RecipeDetail"]) {
        FrecipeRecipeDetailViewController *recipeDetailViewController = (FrecipeRecipeDetailViewController *) segue.destinationViewController;
        
        recipeDetailViewController.navigationItem.leftBarButtonItem = nil;
        recipeDetailViewController.recipeId = [self.selectedRecipe objectForKey:@"id"];
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStyleBordered target:segue.destinationViewController action:@selector(popViewControllerAnimated:)];
    } else if ([segue.identifier isEqualToString:@"Profile"] || [segue.identifier isEqualToString:@"Profile2"]) {
        FrecipeProfileViewController *destinationViewController = (FrecipeProfileViewController *)segue.destinationViewController;
        destinationViewController.navigationItem.leftBarButtonItem = nil;
        if (self.selectedUser == nil) {
            UIButton *button = (UIButton *)sender;
            UICollectionViewCell *cell = (UICollectionViewCell *)button.superview.superview.superview;
            NSDictionary *user = [[self.recipes objectAtIndex:[self.recipesCollectionView indexPathForCell:cell].row] objectForKey:@"user"];
            self.selectedUser = user;
        }
        destinationViewController.userId = [NSString stringWithFormat:@"%@", [self.selectedUser objectForKey:@"id"]];
        destinationViewController.fromSegue = YES;
        
        destinationViewController.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStyleBordered target:segue.destinationViewController action:@selector(popViewControllerAnimated:)];
    }
}

// alert view delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Error"]) {
        if (buttonIndex == 0) {
            [self fetchRecipes];
        }
    }
}

// collection view delegate methods

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"SearchBarHeader" forIndexPath:indexPath];
    return view;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.recipes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RecipeCell" forIndexPath:indexPath];
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:6];
    
    if (PRODUCTION) {
        [recipeImageView setImageWithURL:[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"] placeholderImage:[UIImage imageNamed:@"bar_red.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:6];
            
            if (self.alreadyLoaded == NO) {
                recipeImageView.alpha = 0;
                [UIView animateWithDuration:0.5 animations:^{
                    recipeImageView.alpha = 1;
                }];
            }
         
        }];
    } else {
        [recipeImageView setImageWithURL:[NSString stringWithFormat:@"http://localhost:5000/%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"]] placeholderImage:[UIImage imageNamed:@"bar_red.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:6];
            
            if (self.alreadyLoaded == NO) {
                recipeImageView.alpha = 0;
                [UIView animateWithDuration:0.5 animations:^{
                    recipeImageView.alpha = 1;
                }];
            }
        }];
    }
    
    UIView *flipView1 = [cell viewWithTag:10];
    UIView *flipView2 = [cell viewWithTag:1];
    
    UITapGestureRecognizer *flipGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCell:)];
    UITapGestureRecognizer *flipGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCell:)];
    
    [flipView1 addGestureRecognizer:flipGestureRecognizer1];
    [flipView2 addGestureRecognizer:flipGestureRecognizer2];
    
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
    
    UIView *backView = [cell viewWithTag:1];
    UIView *frontView = [cell viewWithTag:5];
    frontView.alpha = 1.0;
    backView.alpha = 0;
    
    // chef name button and missing ingredients and likes on front view
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
