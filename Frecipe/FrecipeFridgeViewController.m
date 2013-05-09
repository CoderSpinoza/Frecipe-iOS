//
//  FrecipeFridgeViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeFridgeViewController.h"
#import "FrecipeNavigationController.h"
#import "FrecipeBadgeView.h"
#import "FrecipeAPIClient.h"

@interface FrecipeFridgeViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate> {
    BOOL userIsInTheMiddleOfEditingIngredientsList;
}

@property (strong, nonatomic) NSMutableArray *ingredients;
@property (strong, nonatomic) NSMutableArray *selectedIngredients;


@end

@implementation FrecipeFridgeViewController

@synthesize selectedIngredients = _selectedIngredients;

- (NSMutableArray *)selectedIngredients {
    if (_selectedIngredients == nil) {
        _selectedIngredients = [[NSMutableArray alloc] init];
    }
    return _selectedIngredients;
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
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.ingredientsTableView.delegate = self;
    self.ingredientsTableView.dataSource = self;
    self.notificationBadge = [self addNotificationBadge];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchIngredients];
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

- (void)fetchIngredients {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSString *path = [NSString stringWithFormat:@"user_ingredients/%@", authentication_token];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.ingredients = [NSMutableArray arrayWithArray:JSON];
        if (userIsInTheMiddleOfEditingIngredientsList) {
            NSDictionary *addRow = [NSDictionary dictionaryWithObject:@"Add Ingredients" forKey:@"name"];
            [self.ingredients insertObject:addRow atIndex:0];
        }
        [self.ingredientsTableView reloadData];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error loading your fridge info. Retry?" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Cancel", nil];
        [alertView show];
        
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}

- (IBAction)deleteButtonPressed:(UIBarButtonItem *)sender {
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:self.selectedIngredients.count];
    for (id ingredient in self.selectedIngredients) {
        NSString *ingredientId = [ingredient objectForKey:@"id"];
        [ids insertObject:ingredientId atIndex:0];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"ids", nil];
    
    NSArray *values = [NSArray arrayWithObjects:authentication_token, ids, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSString *path = @"user_ingredients/multiple_delete";
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        for (id ingredient in self.selectedIngredients) {
            [self.ingredients removeObject:ingredient];
        }
        [self.selectedIngredients removeAllObjects];
        [self.ingredientsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    [operation start];
}

- (void)openAddIngredientsModal {
    [self performSegueWithIdentifier:@"AddIngredients" sender:self];
}

- (void)openAddIngredientsActionSheet {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"How to add ingredients?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Receipt", @"Manually", nil];
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)openImagePickerController {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Recipe Recognition" message:@"Receipt Recognition Feature is Coming Soon!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
    [alertView show];
}

// alert view delegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self fetchIngredients];
    }
}

// action sheet delegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self openImagePickerController];
    } else if (buttonIndex == 1) {
        [self openAddIngredientsModal];
    } else {
        [self.ingredientsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    userIsInTheMiddleOfEditingIngredientsList = editing;
    if (editing) {
        NSArray *keys = [NSArray arrayWithObjects:@"name", nil];
        NSArray *values = [NSArray arrayWithObjects:@"Add Ingredients", nil];
        NSDictionary *addRow = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        [self.ingredients insertObject:addRow atIndex:0];
        [self.ingredientsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        self.navigationController.toolbarHidden = NO;
        [self.ingredientsTableView setEditing:YES animated:YES];
        
    } else {
        [self.ingredients removeObjectAtIndex:0];
        [self.ingredientsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        self.navigationController.toolbarHidden = YES;
        [self.selectedIngredients removeAllObjects];
        [self.ingredientsTableView setEditing:NO animated:YES];
    }
    [super setEditing:editing animated:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.ingredients.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"IngredientCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", [[self.ingredients objectAtIndex:indexPath.row] objectForKey:@"name"]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (userIsInTheMiddleOfEditingIngredientsList) {
        if (indexPath.row == 0) {
            [self openAddIngredientsActionSheet];
        } else {
            [self.selectedIngredients addObject:[self.ingredients objectAtIndex:indexPath.row]];
        }
    }
    
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (userIsInTheMiddleOfEditingIngredientsList) {
        if (indexPath.row != 0) {
            [self.selectedIngredients removeObject:[self.ingredients objectAtIndex:indexPath.row]];
        }
    }
}
@end
