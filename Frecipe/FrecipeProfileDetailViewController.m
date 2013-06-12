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
#import <FacebookSDK/FacebookSDK.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface FrecipeProfileDetailViewController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

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

- (void)fetchUsers {
    NSString *path;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];

    if ([self.segueIdentifier isEqualToString:@"Followers"]) {
        path = [NSString stringWithFormat:@"tokens/followers/%@", authentication_token];
    } else {
        path = [NSString stringWithFormat:@"tokens/following/%@", authentication_token];
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSString *path;
    if ([self.segueIdentifier isEqualToString:@"Likes"]) {
        path = [NSString stringWithFormat:@"tokens/likes/%@", authentication_token];
    } else {
        path = [NSString stringWithFormat:@"tokens/liked/%@", authentication_token];
    }
    
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
    if ([provider isEqualToString:@"facebook"]) {
        cell.imageView.image = [UIImage imageNamed:@"default_profile_picture.png"];
        cell.imageView.hidden = YES;
        FBProfilePictureView *fbProfilePictureView = (FBProfilePictureView *)[cell viewWithTag:1];
        fbProfilePictureView.profileID = [user objectForKey:@"uid"];
        
    } else {
        fbProfilePictureView.hidden = YES;
        [cell.imageView setImageWithURL:[user objectForKey:@"profile_picture"] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
    }
    return cell;
}

// table view delegate methods


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
        [recipeImageView setImageWithURL:[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"]];
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
    
    UILabel *likesLabel = (UILabel *)[cell viewWithTag:9];
    likesLabel.text = [NSString stringWithFormat:@"%@ likes", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"likes"]];
    
    UIButton *missingIngredientsButton = (UIButton *)[cell viewWithTag:12];
    if (missingIngredients.count == 0) {
        missingIngredientsButton.selected = YES;
        [missingIngredientsButton setTitle:@"" forState:UIControlStateNormal];
    } else {
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

@end
