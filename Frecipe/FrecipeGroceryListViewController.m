//
//  FrecipeGroceryListViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeGroceryListViewController.h"
#import "FrecipeNavigationController.h"
#import "FrecipeAppDelegate.h"
#import "FrecipeAPIClient.h"
#import "FrecipeBadgeView.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface FrecipeGroceryListViewController () <UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    BOOL userIsInTheMiddleOfEditingGroceryList;
    BOOL displayingSpecificRecipe;
}

@property (strong, nonatomic) NSMutableArray *groceryList;
@property (strong, nonatomic) NSMutableArray *selectedGroceryList;
@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) NSIndexPath *displayedRecipeIndexPath;
@end

@implementation FrecipeGroceryListViewController

@synthesize selectedGroceryList = _selectedGroceryList;

- (NSMutableArray *)selectedGroceryList {
    if (_selectedGroceryList == nil) {
        _selectedGroceryList = [[NSMutableArray alloc] init];
    }
    return _selectedGroceryList;
}

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
    self.groceryListTableView.dataSource = self;
    self.groceryListTableView.delegate = self;
    
    self.recipesCollectionView.dataSource = self;
    self.recipesCollectionView.delegate = self;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.view setBackgroundImage:[UIImage imageNamed:@"grocery_list_background.jpg"]];
    
    
    self.groceryListView.layer.cornerRadius = 5.0f;
    
    self.groceryListTableView.layer.borderColor = [[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.8] CGColor];
    self.groceryListTableView.layer.borderWidth = 1.0f;
    
    self.notificationBadge = [self addNotificationBadge];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchGroceryList];
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

- (void)fetchGroceryList {
    NSString *path = @"groceries/list";
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"%@", JSON);
        self.groceryList = [NSMutableArray arrayWithArray:[JSON objectForKey:@"groceries"]];
        self.recipes = [NSMutableArray arrayWithArray:[JSON objectForKey:@"recipes"]];
        
        NSDictionary *all = [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"id", @"All", @"name", @"grocery_list.png", @"recipe_image", nil];
        
        [self.recipes insertObject:all atIndex:0];
        
        if (userIsInTheMiddleOfEditingGroceryList) {
            NSDictionary *addRow = [NSDictionary dictionaryWithObject:@"Add To Grocery List" forKey:@"name"];
            [self.groceryList insertObject:addRow atIndex:0];
        }
        
        NSLog(@"%@", self.recipes);
        self.recipeNameLabel.text = [NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:0] objectForKey:@"name"]];
        [self.groceryListTableView reloadData];
        [self.recipesCollectionView reloadData];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error loading your grocery list. Retry?" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Cancel", nil];
        [alertView show];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        NSLog(@"%@", error);
        
    }];
    [operation start];
}

- (IBAction)addToFridgeButtonPressed:(UIBarButtonItem *)sender {
    NSString *path = @"groceries/fridge";
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:self.selectedGroceryList.count];
    for (NSDictionary *ingredient in self.selectedGroceryList) {
        NSString *ingredientId = [NSString stringWithFormat:@"%@", [ingredient objectForKey:@"id"]];
        [ids addObject:ingredientId];
    }
    
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"ids", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, ids, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSMutableArray *deletedGroceries = [NSArray arrayWithArray:[JSON objectForKey:@"fridge"]];
        
        for (NSDictionary *deletedGrocery in deletedGroceries) {
            if ([self.groceryList containsObject:deletedGrocery]) {
            
                NSInteger rowIndex = [self.groceryList indexOfObject:deletedGrocery];
                 [self.groceryList removeObject:deletedGrocery];
                [self.groceryListTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:rowIndex inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        [self.selectedGroceryList removeAllObjects];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    [operation start];
    
}

- (IBAction)deleteButtonPressed:(UIBarButtonItem *)sender {
    NSString *path = @"groceries/multiple_delete";
    
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:self.selectedGroceryList.count];
    for (id ingredient in self.selectedGroceryList) {
        NSString *ingredientId = [ingredient objectForKey:@"id"];
        [ids insertObject:ingredientId atIndex:0];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"ids", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, ids, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        for (id ingredient in self.selectedGroceryList) {
            [self.groceryList removeObject:ingredient];
        }
        [self.selectedGroceryList removeAllObjects];
        [self.groceryListTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}

- (void)openAddToGroceryListModal {
    [self performSegueWithIdentifier:@"AddToGroceryList" sender:self];
}

// alert view delegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self fetchGroceryList];
    }
}

// table view delegate and dataSource methods

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.row == 0) {
        return NO;
    } else {
        return  YES;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    userIsInTheMiddleOfEditingGroceryList = editing;
    if (editing) {
        NSArray *keys = [NSArray arrayWithObjects:@"name", @"image", nil];
        NSArray *values = [NSArray arrayWithObjects:@"Add to Grocery List", @"plus.png", nil];
        NSDictionary *addRow = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        [self.groceryList insertObject:addRow atIndex:0];
        [self.groceryListTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
//        [self.groceryListTableView reloadData];
        
        [self.groceryListTableView setEditing:YES animated:YES];
        
        self.navigationController.toolbarHidden = NO;
        
    } else {
        [self.groceryList removeObjectAtIndex:0];
        [self.groceryListTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        self.navigationController.toolbarHidden = YES;
        [self.selectedGroceryList removeAllObjects];
        [self.groceryListTableView setEditing:NO animated:YES];
    }
    [super setEditing:editing animated:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (displayingSpecificRecipe) {
        NSDictionary *recipe = [self.recipes objectAtIndex:self.displayedRecipeIndexPath.row];
        return recipe.count;
    } else {
        return self.groceryList.count;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GroceryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [[self.groceryList objectAtIndex:indexPath.row] objectForKey:@"name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (userIsInTheMiddleOfEditingGroceryList) {
        if (indexPath.row == 0) {
            [self openAddToGroceryListModal];
        } else {
            [self.selectedGroceryList addObject:[self.groceryList objectAtIndex:indexPath.row]];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (userIsInTheMiddleOfEditingGroceryList) {
        if (indexPath.row != 0) {
            [self.selectedGroceryList removeObject:[self.groceryList objectAtIndex:indexPath.row]];
        }
    }
}

// collection view delegate and dataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.recipes.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RecipeCell" forIndexPath:indexPath];
    
    
    NSDictionary *recipe = [self.recipes objectAtIndex:indexPath.row];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
    if (indexPath.row == 0) {
        [imageView setImage:[UIImage imageNamed:@"grocery_list.png"]];
        cell.layer.borderColor = [[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.8] CGColor];
        cell.layer.borderWidth = 1.0f;
    } else {
        if (PRODUCTION) {
            [imageView setImageWithURL:[recipe objectForKey:@"recipe_image"] placeholderImage:[UIImage imageNamed:@"default_recipe_image.png"]];
        } else {
            [imageView setImageWithURL:[NSString stringWithFormat:@"http://localhost:5000/%@", [recipe objectForKey:@"recipe_image"]] placeholderImage:[UIImage imageNamed:@"default_recipe_image.png"]];
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    displayingSpecificRecipe = indexPath.row != 0;
    self.navigationItem.rightBarButtonItem.enabled = !displayingSpecificRecipe;
    
    self.recipeNameLabel.text = [NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"name"]];
}


@end
