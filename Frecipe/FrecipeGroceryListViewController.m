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
    BOOL editingRecipes;
    BOOL displayingSpecificRecipe;
}

@property (strong, nonatomic) NSMutableArray *groceryList;
@property (strong, nonatomic) NSMutableArray *currentGroceryList;
@property (strong, nonatomic) NSMutableArray *currentGroceryDetailList;
@property (strong, nonatomic) NSMutableArray *selectedGroceryList;
@property (strong, nonatomic) NSMutableArray *completedGroceryList;
@property (strong, nonatomic) NSMutableArray *recipes;
@property (strong, nonatomic) NSIndexPath *displayedRecipeIndexPath;
@property (strong, nonatomic) NSDictionary *selectedRecipe;
@property (strong, nonatomic) NSMutableArray *selectedRecipes;

@end

@implementation FrecipeGroceryListViewController

@synthesize selectedGroceryList = _selectedGroceryList;
@synthesize completedGroceryList = _completedGroceryList;
@synthesize selectedRecipes = _selectedRecipes;

- (NSMutableArray *)selectedGroceryList {
    if (_selectedGroceryList == nil) {
        _selectedGroceryList = [[NSMutableArray alloc] init];
    }
    return _selectedGroceryList;
}

- (NSMutableArray *)completedGroceryList {
    if (_completedGroceryList == nil) {
        _completedGroceryList = [[NSMutableArray alloc] init];
    }
    return _completedGroceryList;
}

- (NSMutableArray *)selectedRecipes {
    if (_selectedRecipes == nil) {
        _selectedRecipes = [[NSMutableArray alloc] init];
    }
    return _selectedRecipes;
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
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gogeupleather.jpg"]];
    
    self.groceryListView.layer.cornerRadius = 5.0f;
    self.groceryListView.frame = CGRectMake(self.groceryListView.frame.origin.x, self.groceryListView.frame.origin.y, self.groceryListView.frame.size.width, self.view.frame.size.height - self.groceryListView.frame.origin.y - 54);
    self.groceryListView.layer.masksToBounds = NO;
    
    [self.groceryListView setShadowWithColor:[UIColor grayColor] Radius:2.0f Offset:CGSizeMake(0, 0) Opacity:0.5f];
    
    self.groceryListTableView.layer.borderColor = [[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.8] CGColor];
    self.groceryListTableView.layer.borderWidth = 1.0f;
    
    self.notificationBadge = [self addNotificationBadge];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchGroceryList];
    [self loadGroceryInfo];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveGroceryInfo];
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

- (void)saveGroceryInfo {
    NSData *groceryInfo = [NSKeyedArchiver archivedDataWithRootObject:self.completedGroceryList];
    [groceryInfo writeToURL:[NSURL URLWithString:@"GroceryInfo" relativeToURL:[self documentDirectory]] atomically:YES];
}

- (void)loadGroceryInfo {
    NSData *savedGroceryInfo = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:@"GroceryInfo" relativeToURL:[self documentDirectory]]];
    self.completedGroceryList = [[NSKeyedUnarchiver unarchiveObjectWithData:savedGroceryInfo] mutableCopy];
    NSLog(@"%@", self.completedGroceryList);
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
//        self.recipes = [NSMutableArray arrayWithArray:[JSON objectForKey:@"recipes"]];
//        
//        self.groceryList = [NSMutableArray arrayWithArray:[JSON objectForKey:@"groceries"]];
//        
//        for (NSDictionary *recipe in self.recipes) {
//            NSArray *missing_ingredients = [recipe objectForKey:@"missing_ingredients"];
//            for (NSDictionary *ingredient in missing_ingredients) {
//                if (![self.groceryList containsObject:ingredient]) {
//                    [self.groceryList addObject:ingredient];
//                }
//            }
//        }
//        self.currentGroceryList = self.groceryList;
//        NSDictionary *all = [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"id", @"All Recipes", @"name", @"grocery_list.png", @"recipe_image", self.groceryList, @"missing_ingredients", nil];
//        
//        [self.recipes insertObject:all atIndex:0];
//        
//        self.recipeNameLabel.text = [NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:0] objectForKey:@"name"]];
//        [self.groceryListTableView reloadData];
//        [self.recipesCollectionView reloadData];
        [self processGroceryListInformation:JSON];
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

- (void)deleteSelectedRecipe {
    NSString *groceryRecipeId = [NSString stringWithFormat:@"%@", [self.selectedRecipe objectForKey:@"id"]];
    NSString *path = [NSString stringWithFormat:@"grocery_recipes/%@", groceryRecipeId];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"DELETE" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *groceryListInfo = [JSON objectForKey:@"grocery_list"];
        [self processGroceryListInformation:groceryListInfo];
        
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
    
}

- (void)processGroceryListInformation:(NSDictionary *)groceryListInfo {
    self.recipes = [NSMutableArray arrayWithArray:[groceryListInfo objectForKey:@"recipes"]];
    
    self.groceryList = [NSMutableArray arrayWithArray:[groceryListInfo objectForKey:@"groceries"]];
    
    
    for (NSDictionary *recipe in self.recipes) {
        NSArray *missing_ingredients = [recipe objectForKey:@"missing_ingredients"];
        NSArray *groceries = [recipe objectForKey:@"groceries"];
//        for (NSDictionary *ingredient in missing_ingredients) {
//            if (![self.groceryList containsObject:ingredient]) {
//                [self.groceryList addObject:ingredient];
//            }
//        }
        for (int i = 0; i < missing_ingredients.count; i++) {
            NSDictionary *ingredient = [missing_ingredients objectAtIndex:i];
            NSDictionary *groceryDetail = [groceries objectAtIndex:i];
            if ([[NSString stringWithFormat:@"%@", [groceryDetail objectForKey:@"active"]] isEqualToString:@"1"] && ![self.groceryList containsObject:ingredient]) {
                [self.groceryList addObject:ingredient];
            }
        }
    }
    self.currentGroceryList = self.groceryList;
    NSDictionary *all = [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"id", @"All Recipes", @"name", @"grocery_list.png", @"recipe_image", self.groceryList, @"missing_ingredients", nil];
    
    [self.recipes insertObject:all atIndex:0];
    
    self.recipeNameLabel.text = [NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:0] objectForKey:@"name"]];
    [self.groceryListTableView reloadData];
    [self.recipesCollectionView reloadData];
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

- (IBAction)deleteButtonPressed {
    NSString *path = @"groceries/multiple_delete";
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:self.completedGroceryList.count];
    for (id ingredient in self.completedGroceryList) {
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
        NSLog(@"%@", JSON);
        NSDictionary *groceryListInfo = [JSON objectForKey:@"grocery_list"];
        [self processGroceryListInformation:groceryListInfo];
        [self.completedGroceryList removeAllObjects];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}

- (IBAction)deleteRecipesButtonPressed {
    NSString *path = @"grocery_recipes/multiple_delete";
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:self.selectedRecipes.count];
    for (NSDictionary *recipe in self.selectedRecipes) {
        [ids addObject:[recipe objectForKey:@"id"]];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"ids", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, ids, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"%@", JSON);
        [self processGroceryListInformation:[JSON objectForKey:@"grocery_list"]];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    [operation start];
    
    
}

- (void)checkboxPressed:(UIButton *)sender {
    UITableViewCell *cell = (UITableViewCell *)sender.superview.superview;
    NSIndexPath *indexPath = [self.groceryListTableView indexPathForCell:cell];
    
    if (sender.selected == YES) {
        [self.completedGroceryList removeObject:[self.currentGroceryList objectAtIndex:indexPath.row]];
        sender.selected = NO;
    } else {
        [self.completedGroceryList addObject:[self.currentGroceryList objectAtIndex:indexPath.row]];
        sender.selected = YES;
    }
}

- (IBAction)doneButtonPressed {
    NSString *path = @"groceries/fridge";
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:self.completedGroceryList.count];
    for (NSDictionary *ingredient in self.completedGroceryList) {
        NSString *ingredientId = [NSString stringWithFormat:@"%@", [ingredient objectForKey:@"id"]];
        [ids addObject:ingredientId];
    }
    
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"ids", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, ids, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        NSMutableArray *deletedGroceries = [NSArray arrayWithArray:[JSON objectForKey:@"fridge"]];
//        
//        for (NSDictionary *deletedGrocery in deletedGroceries) {
//            if ([self.currentGroceryList containsObject:deletedGrocery]) {
//                
//                NSInteger rowIndex = [self.currentGroceryList indexOfObject:deletedGrocery];
//                [self.currentGroceryList removeObject:deletedGrocery];
//                [self.groceryListTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:rowIndex inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
//            }
//        }
        NSDictionary *groceryListInfo = [JSON objectForKey:@"grocery_list"];
        [self processGroceryListInformation:groceryListInfo];
        [self.completedGroceryList removeAllObjects];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    [operation start];

    
}


- (IBAction)openAddToGroceryListModal {
    [self performSegueWithIdentifier:@"AddToGroceryList" sender:self];
}

- (IBAction)editButtonPressed:(UIBarButtonItem *)sender {
    if (editingRecipes == NO) {
        editingRecipes = YES;
        sender.title = @"Done";
        [UIView animateWithDuration:0.5 animations:^{
            self.groceryListView.frame = CGRectMake(-250, self.groceryListView.frame.origin.y, self.groceryListView.frame.size.width, self.groceryListView.frame.size.height);
            
            self.recipesCollectionView.frame = CGRectMake(self.recipesCollectionView.frame.origin.x - self.groceryListView.frame.size.width - 10, self.recipesCollectionView.frame.origin.y, self.recipesCollectionView.frame.size.width + self.groceryListView.frame.size.width, self.recipesCollectionView.frame.size.height);
            self.deleteRecipesButton.alpha = 1;
        }];
    } else {
        editingRecipes = NO;
        sender.title = @"Edit";
        [UIView animateWithDuration:0.5 animations:^{
            self.groceryListView.frame = CGRectMake(10, self.groceryListView.frame.origin.y, self.groceryListView.frame.size.width, self.groceryListView.frame.size.height);
            
            self.recipesCollectionView.frame = CGRectMake(self.recipesCollectionView.frame.origin.x + self.groceryListView.frame.size.width + 10, self.recipesCollectionView.frame.origin.y, self.recipesCollectionView.frame.size.width - self.groceryListView.frame.size.width, self.recipesCollectionView.frame.size.height);
            self.deleteRecipesButton.alpha = 0;
            
        }];
        [self.selectedRecipes removeAllObjects];
    }
    [self.recipesCollectionView reloadData];
}

- (void)colorCollectionViewCell:(UICollectionViewCell *)cell {
    [cell setShadowWithColor:[UIColor colorWithRed:0.86 green:0.30 blue:0.27 alpha:0.9] Radius:8.0f Offset:CGSizeMake(0, 0) Opacity:1.0f];
}

- (void)decolorCollectionViewCell:(UICollectionViewCell *)cell {
    [cell setShadowWithColor:[UIColor grayColor] Radius:2.0f Offset:CGSizeMake(0, 0) Opacity:0.5f];
}

// alert view delegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Error"]) {
        if (buttonIndex == 0) {
            [self fetchGroceryList];
        }
    } else {
        if (buttonIndex == 0) {
            [self deleteSelectedRecipe];
        }
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
    return self.currentGroceryList.count;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GroceryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    NSDictionary *currentGrocery = [self.currentGroceryList objectAtIndex:indexPath.row];
    cell.textLabel.text = [currentGrocery objectForKey:@"name"];
    
    cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
    
    cell.imageView.image = [UIImage imageNamed:@"checkbox.png"];
    
    UIButton *button = (UIButton *)[cell viewWithTag:1];
    [button setImage:[UIImage imageNamed:@"checkbox.png"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"checkmark.png"] forState:UIControlStateSelected];
    
    [button addTarget:self action:@selector(checkboxPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.completedGroceryList containsObject:currentGrocery]) {
        button.selected = YES;
        cell.selected = YES;
    } else {
        button.selected = NO;
        cell.selected = NO;
    }
    
    cell.imageView.hidden = YES;
    
    
    NSDictionary *groceryDetail = [self.currentGroceryDetailList objectAtIndex:indexPath.row];
    
    UIView *crossOutView = [cell viewWithTag:2];
    if ([[NSString stringWithFormat:@"%@", [groceryDetail objectForKey:@"active"]] isEqualToString:@"0"]) {
        crossOutView.hidden = NO;
        crossOutView.frame = CGRectMake(crossOutView.frame.origin.x, crossOutView.frame.origin.y, [cell.textLabel.text sizeWithFont:[UIFont systemFontOfSize:15.0f]].width + 50, crossOutView.frame.size.height);
    } else {
        crossOutView.hidden = YES;
    }
    cell.textLabel.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
//    if (userIsInTheMiddleOfEditingGroceryList) {
//        if (indexPath.row == 0) {
//            [self openAddToGroceryListModal];
//        } else {
//            [self.selectedGroceryList addObject:[self.groceryList objectAtIndex:indexPath.row]];
//        }
//    }
    UITableViewCell *cell = [self.groceryListTableView cellForRowAtIndexPath:indexPath];
    UIButton *sender = (UIButton *)[cell viewWithTag:1];
    
    if (![self.completedGroceryList containsObject:[self.currentGroceryList objectAtIndex:indexPath.row]]) {
        [self.completedGroceryList addObject:[self.currentGroceryList objectAtIndex:indexPath.row]];
        sender.selected = YES;
        cell.selected = YES;
    } else {
        [self.completedGroceryList removeObject:[self.currentGroceryList objectAtIndex:indexPath.row]];
        sender.selected = NO;
        cell.selected = NO;
    }
    
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.groceryListTableView cellForRowAtIndexPath:indexPath];
    UIButton *sender = (UIButton *)[cell viewWithTag:1];

    if (![self.completedGroceryList containsObject:[self.currentGroceryList objectAtIndex:indexPath.row]]) {
        [self.completedGroceryList addObject:[self.currentGroceryList objectAtIndex:indexPath.row]];
        sender.selected = YES;
        cell.selected = YES;
    } else {
        [self.completedGroceryList removeObject:[self.currentGroceryList objectAtIndex:indexPath.row]];
        sender.selected = NO;
        cell.selected = NO;
    }

}

// collection view delegate and dataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    self.navigationItem.rightBarButtonItem.enabled = self.recipes.count > 1;
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
//        cell.layer.borderColor = [[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.8] CGColor];
//        cell.layer.borderWidth = 1.0f;
    } else {
        if (PRODUCTION) {
            [imageView setImageWithURL:[recipe objectForKey:@"recipe_image"] placeholderImage:[UIImage imageNamed:@"default_recipe_image.png"]];
        } else {
            [imageView setImageWithURL:[NSString stringWithFormat:@"http://localhost:5000/%@", [recipe objectForKey:@"recipe_image"]] placeholderImage:[UIImage imageNamed:@"default_recipe_image.png"]];
        }
    }
    
    FrecipeBadgeView *deleteView = (FrecipeBadgeView *)[cell viewWithTag:2];
    deleteView.text = @"X";
    UIView *whiteView = [cell viewWithTag:3];
    if (indexPath.row != 0) {
        if (editingRecipes) {
            [UIView animateWithDuration:0.3 animations:^{
                deleteView.alpha = 1;
                [cell startShaking];
            }];
        } else {
            whiteView.alpha = 0;
            deleteView.alpha = 0;
        }
    } else {
        whiteView.alpha = 0;
        deleteView.alpha = 0;
    }
    
    [cell setShadowWithColor:[UIColor grayColor] Radius:2.0f Offset:CGSizeMake(0, 0) Opacity:0.5f];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if (editingRecipes) {
        if (indexPath.row != 0) {
            self.selectedRecipe = [self.recipes objectAtIndex:indexPath.row];
            UIView *view = [cell viewWithTag:3];
            if ([self.selectedRecipes containsObject:self.selectedRecipe]) {
                [self.selectedRecipes removeObject:self.selectedRecipe];
                view.alpha = 0;
                
            } else {
                [self.selectedRecipes addObject:self.selectedRecipe];
                view.alpha = 0.5;
            }
        }
        
    } else {
        displayingSpecificRecipe = indexPath.row != 0;
        self.recipeNameLabel.text = [NSString stringWithFormat:@"%@", [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"name"]];
        self.currentGroceryList = [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"missing_ingredients"];
        
        self.currentGroceryDetailList = [[self.recipes objectAtIndex:indexPath.row] objectForKey:@"groceries"];
        NSLog(@"%@", self.currentGroceryDetailList);
        
        [self colorCollectionViewCell:cell];
        [self.groceryListTableView reloadData];

    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    [self decolorCollectionViewCell:cell];
}


@end
