//
//  FrecipeViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeViewController.h"
#import "FrecipeNavigationController.h"
#import "FrecipeAppDelegate.h"
#import "FrecipeRecipeDetailViewController.h"
#import "FrecipeProfileViewController.h"
#import "FrecipeBadgeView.h"
#import "FrecipeSpinnerView.h"
#import "FrecipeFunctions.h"
#import "UIImageView+WebCache.h"
#import "FrecipeLeaderboardViewController.h"
@interface FrecipeViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) NSMutableArray *ingredients;
@property (strong, nonatomic) NSMutableArray *events;
@property (strong, nonatomic) NSMutableArray *recipe_ingredients;

@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSDictionary *selectedRecipe;
@property (strong, nonatomic) NSDictionary *selectedEvent;
@property (strong, nonatomic) NSString *selectedUserId;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) NSMutableArray *userIngredients;

@end

@implementation FrecipeViewController
@synthesize recipes = _recipes;
@synthesize recipe_ingredients = _recipe_ingredients;

- (NSMutableArray *)recipes {
    if (_recipes == nil) {
        _recipes = [[NSMutableArray alloc] init];
    }
    return _recipes;
    
}
- (NSMutableArray *)recipe_ingredients {
    if (_recipe_ingredients == nil) {
        _recipe_ingredients = [[NSMutableArray alloc] init];
    }
    return _recipe_ingredients;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.title = @"Frecipe";
    self.screenName = @"Frecipe";
    self.recipesCollectionView.dataSource = self;
    self.recipesCollectionView.delegate = self;
    [self addRefreshControl];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.selectedUser = nil;
    [self fetchRecipes];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];    
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
//    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
//    self.recipeSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
//    [self.headerView addSubview:self.recipeSearchBar];
//    self.recipesCollectionView.
}

- (void)fetchRecipes {
    NSString *path = @"recipes.json";
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:authentication_token, @"authentication_token", nil];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    
    FrecipeSpinnerView *spinner = [[FrecipeSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    spinner.center = self.view.center;
    [spinner.spinner startAnimating];
    [self.view addSubview:spinner];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        self.ingredients = [NSMutableArray arrayWithArray:[JSON objectForKey:@"ingredients"]];
        [self.recipes removeAllObjects];
        NSMutableArray *recipes = [NSMutableArray arrayWithArray:[JSON objectForKey:@"recipes"]];
        
        self.userIngredients = [NSMutableArray arrayWithArray:[JSON objectForKey:@"ingredient_values"]];
        [recipes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSMutableDictionary *recipe = (NSMutableDictionary *)obj;
            
            NSMutableArray *recipeIngredients = [[[NSString stringWithFormat:@"%@", [recipe objectForKey:@"ingredients_string"]] componentsSeparatedByString:@","] mutableCopy];
            
            NSMutableArray *recipeIngredientValues = [[[NSString stringWithFormat:@"%@", [recipe objectForKey:@"ingredient_values"]] componentsSeparatedByString:@","] mutableCopy];
            
            NSIndexSet *indexSet = [recipeIngredientValues indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [self.userIngredients containsObject:obj];

            }];
            [recipeIngredients removeObjectsAtIndexes:indexSet];
            
            
            
            NSArray *keys = [NSArray arrayWithObjects:@"id", @"name", @"user_id", @"username", @"likes", @"ingredients", @"recipe_image",  nil];
            NSArray *values = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@", [recipe objectForKey:@"recipe_id"]], [NSString stringWithFormat:@"%@", [recipe objectForKey:@"name"]], [NSString stringWithFormat:@"%@", [recipe objectForKey:@"user_id"]], [NSString stringWithFormat:@"%@ %@", [recipe objectForKey:@"first_name"], [recipe objectForKey:@"last_name"]], [NSString stringWithFormat:@"%@", [recipe objectForKey:@"likes_count"]], recipeIngredients, [NSString stringWithFormat:@"%@", [recipe objectForKey:@"recipe_image_file_name"]], nil];
            NSDictionary *recipe2 = [NSDictionary dictionaryWithObjects:values forKeys:keys];
            
            self.events = [NSMutableArray arrayWithArray:[JSON objectForKey:@"events"]];
            [self.recipes addObject:recipe2];
        }];
        
        [self.recipes sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSDictionary *recipe1 = [obj1 objectForKey:@"ingredients"];
            NSDictionary *recipe2 = [obj2 objectForKey:@"ingredients"];
            
            if (recipe1.count > recipe2.count) {
                return (NSComparisonResult)NSOrderedDescending;
            } else if (recipe1.count < recipe2.count) {
                return (NSComparisonResult)NSOrderedAscending;
            } else {
                return (NSComparisonResult)NSOrderedSame;
            }
        }];
        
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Last updated on %@", [FrecipeFunctions currentDate]]];
        
        [self.refreshControl endRefreshing];
        [self.recipesCollectionView reloadData];
        
        [spinner.spinner stopAnimating];
        [spinner removeFromSuperview];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [self.refreshControl endRefreshing];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error loading recipes. Retry?" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Cancel", nil];
        
        [self.refreshControl endRefreshing];
        [spinner.spinner stopAnimating];
        [spinner removeFromSuperview];
        
        [alertView show];
        
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}



- (void)fetchCachedRecipes {
    NSString *path = @"/recipes/possible";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:authentication_token forKey:@"authentication_token"];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    
    FrecipeSpinnerView *spinner = [[FrecipeSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    spinner.center = self.view.center;
    [spinner.spinner startAnimating];
    [self.view addSubview:spinner];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.recipes = [NSMutableArray arrayWithArray:JSON];
        
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Last updated on %@", [FrecipeFunctions currentDate]]];
        
        [spinner removeFromSuperview];
        [self.refreshControl endRefreshing];
        [self.recipesCollectionView reloadData];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        
        [spinner removeFromSuperview];
        [self.refreshControl endRefreshing];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error loading recipes. Retry?" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Cancel", nil];
        
        [alertView show];
    }];
    
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (void)flipCell:(UITapGestureRecognizer *)tapGestureRecognizer {
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Frecipe" action:@"Fip Recipe" label:@"Fip Recipe" value:[NSNumber numberWithInt:1]] build]];
//    [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Frecipe" withAction:@"Flip Recipe" withLabel:@"Flip Recipe" withValue:[NSNumber numberWithInt:1]];
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
    if ([segue.identifier isEqualToString:@"Profile"] || [segue.identifier isEqualToString:@"Profile2"]) {
        FrecipeProfileViewController *destinationViewController = (FrecipeProfileViewController *)segue.destinationViewController;
        if (self.selectedUser == nil) {
            UIButton *button = (UIButton *)sender;
            UICollectionViewCell *cell = (UICollectionViewCell *)button.superview.superview.superview;
            
            destinationViewController.userId = [NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:[self.recipesCollectionView indexPathForCell:cell].row] objectForKey:@"user_id"]];
            
        } else {
            destinationViewController.userId = [NSString stringWithFormat:@"%@", [self.selectedUser objectForKey:@"id"]];
            
        }
        destinationViewController.fromSegue = YES;
        NSLog(@"hihi");
        destinationViewController.navigationItem.leftBarButtonItem = nil;
//        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemBack target:<#(id)#> action:<#(SEL)#>]
//        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStyleBordered target:segue.destinationViewController action:@selector(popViewControllerAnimated:)];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:segue.destinationViewController action:@selector(popViewControllerAnimated:)];
    } else {
        [super prepareForSegue:segue sender:segue];
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

// collection view dataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.recipes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RecipeCell" forIndexPath:indexPath];
    
    UITextView *recipeNameView = (UITextView *)[cell viewWithTag:8];
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:6];
    UIButton *missingIngredientsButton = (UIButton *)[cell viewWithTag:12];
    UIButton *frontNameButton = (UIButton *)[cell viewWithTag:11];
    UILabel *likesLabel = (UILabel *)[cell viewWithTag:9];
    UIView *whiteView = (UIView *)[cell viewWithTag:7];
    
        // setting the image view for the cell using AFNetworking. Does this do caching automatically?
    recipeImageView.alpha = 0;
    if (PRODUCTION) {
        [recipeImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/recipes/%@/%@", [self s3BucketURL],[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"id"], [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"]]] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:6];
            [UIView animateWithDuration:0.2 animations:^{
                recipeImageView.alpha = 1;
            }];
            
        }];
    } else {
        [recipeImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5000/image/recipes/%@/%@",[[self.recipes objectAtIndex:indexPath.row] objectForKey:@"id"], [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"recipe_image"]]] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"]];
        recipeImageView.alpha = 1;
    }
    recipeImageView.frame = CGRectMake(0, 0, 160, 160);
    
    whiteView.hidden = NO;
    recipeNameView.hidden = NO;
    recipeNameView.text = [NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"name"]];
    
    UILabel *recipeNameLabel = (UILabel *)[cell viewWithTag:2];
    recipeNameLabel.text = [NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"name"]];
    
    UIButton *chefNameButton = (UIButton *)[cell viewWithTag:3];
    [chefNameButton setTitle:[NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"username"]] forState:UIControlStateNormal];
    //
    
    // configure the front of the cell. chef name button and missing ingredients and likes on front view
    frontNameButton.hidden = NO;
    [frontNameButton setTitle:[NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"username"]] forState:UIControlStateNormal];
    [frontNameButton sizeToFit];
    frontNameButton.frame = CGRectMake(160 - [frontNameButton.titleLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:13]].width - 7, frontNameButton.frame.origin.y, frontNameButton.frame.size.width, frontNameButton.frame.size.height);
    
    likesLabel.hidden = NO;
    likesLabel.text = [NSString stringWithFormat:@"%@ likes", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"likes"]];
    
    NSArray *missingIngredients = [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"ingredients"];
    
    UITextView *missingIngredientsView = (UITextView *)[cell viewWithTag:4];
    missingIngredientsView.text = [NSString stringWithFormat:@"%u Missing Ingredients: %@", missingIngredients.count, [missingIngredients componentsJoinedByString:@","]];
    
    if (missingIngredients.count == 0) {
        missingIngredientsButton.hidden = YES;
        //        [missingIngredientsButton setTitle:@"" forState:UIControlStateNormal];
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
    // configure the back of the cell. fill all the info.
        return cell;
}

// collection view delegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    self.selectedRecipe = [self.recipes objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"RecipeDetail"sender:self];
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//    
////    NSDictionary *recipe = [self.recipes objectAtIndex:[self rowForItem:indexPath]];
//    CGSize cellSize;
//    if (indexPath.row == 0) {
//        cellSize = CGSizeMake(self.recipesCollectionView.frame.size.width, self.recipesCollectionView.frame.size.width / 2);
//    } else {
//        cellSize = CGSizeMake(self.recipesCollectionView.frame.size.width / 2, self.recipesCollectionView.frame.size.width / 2);
//    }
//    return cellSize;
//}

//- (NSInteger)rowForItem:(NSIndexPath *)indexPath {
//    if (indexPath.row < self.events.count) {
//        return indexPath.row;
//    } else {
//        return indexPath.row - 1;
//    }
//}

// notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self sendDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to register for push notifications.");
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
}

- (void)sendDeviceToken:(NSData *)deviceToken {
    
    NSLog(@"send device token");
    NSString *path = @"tokens/device.json";
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSString *authentication_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"authentication_token"];
    
    NSLog(@"%@", [deviceToken description]);
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:@{@"authentication_token": authentication_token, @"device_token": [deviceToken description]}];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"%@", JSON);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

@end
