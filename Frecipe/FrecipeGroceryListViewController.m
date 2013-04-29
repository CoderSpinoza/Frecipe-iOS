//
//  FrecipeGroceryListViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeGroceryListViewController.h"
#import "FrecipeNavigationController.h"
#import "FrecipeAPIClient.h"

@interface FrecipeGroceryListViewController () <UITableViewDelegate, UITableViewDataSource> {
    BOOL userIsInTheMiddleOfEditingGroceryList;
}

@property (strong, nonatomic) NSMutableArray *groceryList;
@property (strong, nonatomic) NSMutableArray *selectedGroceryList;

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
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
        
        self.groceryList = [[NSMutableArray alloc] initWithArray:JSON];
        
        if (userIsInTheMiddleOfEditingGroceryList) {
            NSDictionary *addRow = [NSDictionary dictionaryWithObject:@"Add To Grocery List" forKey:@"name"];
            [self.groceryList insertObject:addRow atIndex:0];
        }
        [self.groceryListTableView reloadData];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        
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
    return self.groceryList.count;
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

@end
