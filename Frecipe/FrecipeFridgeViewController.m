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
#import "FrecipeAppDelegate.h"
#import "FrecipeFunctions.h"
#import "UIButton+WebCache.h"

@interface FrecipeFridgeViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    BOOL userIsInTheMiddleOfEditingIngredientsList;
}

@property (strong, nonatomic) UIRefreshControl *tableViewRefreshControl;
@property (strong, nonatomic) UIRefreshControl *collectionViewRefreshControl;
@property (strong, nonatomic) NSMutableArray *ingredients;
@property (strong, nonatomic) NSMutableArray *selectedIngredients;
@property (strong, nonatomic) AFNetworkActivityIndicatorManager *currentManager;

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
    
    self.screenName = @"Fridge";
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.ingredientsTableView.delegate = self;
    self.ingredientsTableView.dataSource = self;
    
    self.ingredientsCollectionView.delegate = self;
    self.ingredientsCollectionView.dataSource = self;
    self.ingredientsCollectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"fridge_background.png"]];
    self.ingredientsCollectionView.allowsMultipleSelection = YES;
    self.notificationBadge = [self addNotificationBadge];
    [self addRefreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem.enabled = NO;
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

- (void)addRefreshControl {
    UIRefreshControl *tableViewRefreshControl = [[UIRefreshControl alloc] init];
    [tableViewRefreshControl addTarget:self action:@selector(fetchIngredients) forControlEvents:UIControlEventValueChanged];
    tableViewRefreshControl.tintColor = [UIColor grayColor];
    
    UIRefreshControl *collectionViewRefreshControl = [[UIRefreshControl alloc] init];
    [collectionViewRefreshControl addTarget:self action:@selector(fetchIngredients) forControlEvents:UIControlEventValueChanged];
    collectionViewRefreshControl.tintColor = [UIColor grayColor];
    
    collectionViewRefreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull down to Refresh!"];
    
    tableViewRefreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull down to Refresh!"];
    
    [self.ingredientsTableView addSubview:tableViewRefreshControl];
    [self.ingredientsCollectionView addSubview:collectionViewRefreshControl];
    self.ingredientsTableView.alwaysBounceVertical = YES;
    self.ingredientsCollectionView.alwaysBounceVertical = YES;
    self.tableViewRefreshControl = tableViewRefreshControl;
    self.collectionViewRefreshControl = collectionViewRefreshControl;
    
    // this code is used to insert a background for refresh view
//    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(self.ingredientsCollectionView.bounds.origin.x, - self.ingredientsCollectionView.frame.size.height, self.ingredientsCollectionView.bounds.size.width, self.ingredientsCollectionView.bounds.size.height)];
//    backgroundView.backgroundColor = [UIColor blackColor];
//    [self.ingredientsCollectionView insertSubview:backgroundView atIndex:0];
}

- (void)fetchIngredients {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSString *path = [NSString stringWithFormat:@"user_ingredients/%@", authentication_token];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:nil];
    
    // insert a spinner view
    FrecipeSpinnerView *spinnerView = [[FrecipeSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    spinnerView.center = self.view.center;
    [spinnerView.spinner startAnimating];
    [self.view addSubview:spinnerView];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.ingredients = [NSMutableArray arrayWithArray:JSON];
        if (userIsInTheMiddleOfEditingIngredientsList) {
            NSArray *keys = [NSArray arrayWithObjects:@"name", @"image", nil];
            NSArray *values = [NSArray arrayWithObjects:@"Add Ingredients", [NSString stringWithFormat:@"%@/ingredients/plus.png", [self s3BucketURL]], nil];
            NSDictionary *addRow = [NSDictionary dictionaryWithObjects:values forKeys:keys];
            [self.ingredients insertObject:addRow atIndex:0];
        }
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
                
        if (self.tableViewRefreshControl.isRefreshing) {
            [self.tableViewRefreshControl endRefreshing];
            self.tableViewRefreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Last updated on %@", [FrecipeFunctions currentDate]]];
            self.collectionViewRefreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Last updated on %@", [FrecipeFunctions currentDate]]];
        }
        
        if (self.collectionViewRefreshControl.isRefreshing) {
            self.tableViewRefreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Last updated on %@", [FrecipeFunctions currentDate]]];
            self.collectionViewRefreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Last updated on %@", [FrecipeFunctions currentDate]]];
            [self.collectionViewRefreshControl endRefreshing];
        }
        
        [self.ingredientsTableView reloadData];
        [self.ingredientsCollectionView reloadData];
        [spinnerView.spinner stopAnimating];
        [spinnerView removeFromSuperview];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error loading your fridge info. Retry?" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"Cancel", nil];
        [alertView show];
        NSLog(@"%@", error);
        
        [self.tableViewRefreshControl endRefreshing];
        [self.collectionViewRefreshControl endRefreshing];
        
        [spinnerView.spinner stopAnimating];
        [spinnerView removeFromSuperview];
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (IBAction)deleteButtonPressed:(UIBarButtonItem *)sender {
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Fridge" action:@"Delete" label:@"Delete" value:[NSNumber numberWithInt:1]] build]];
//    [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Fridge" withAction:@"Delete" withLabel:@"Delete" withValue:[NSNumber numberWithInt:1]];
    
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
    
    self.deleteButton.enabled = NO;
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        for (id ingredient in self.selectedIngredients) {
            [self.ingredients removeObject:ingredient];
        }
        [self.selectedIngredients removeAllObjects];
        [self.ingredientsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.ingredientsCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        self.deleteButton.enabled = YES;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        self.deleteButton.enabled = YES;
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (IBAction)segmentedControlPressed:(UISegmentedControl *)sender {
    
    if (sender.selectedSegmentIndex == 0) {
        
        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Fridge" action:@"Collection" label:@"Collection" value:[NSNumber numberWithInt:1]] build]];
//        [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Fridge" withAction:@"Collection" withLabel:@"Collection" withValue:[NSNumber numberWithInt:1]];
        self.ingredientsCollectionView.hidden = NO;
        self.ingredientsTableView.hidden = YES;
    } else {
        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Fridge" action:@"List" label:@"List" value:[NSNumber numberWithInt:1]] build]];
//        [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Fridge" withAction:@"List" withLabel:@"List" withValue:[NSNumber numberWithInt:1]];
        self.ingredientsCollectionView.hidden = YES;
        self.ingredientsTableView.hidden = NO;
    }
}

- (void)openAddIngredientsModal {
    [self performSegueWithIdentifier:@"AddIngredients" sender:self];
}

- (void)openAddIngredientsActionSheet {
    [self openAddIngredientsModal];
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
        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Fridge" action:@"Edit" label:@"Edit" value:[NSNumber numberWithInt:1]] build]];
//        [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Fridge" withAction:@"Edit" withLabel:@"Edit" withValue:[NSNumber numberWithInt:1]];
        NSArray *keys = [NSArray arrayWithObjects:@"name", @"image", nil];
        NSArray *values = [NSArray arrayWithObjects:@"Add Ingredients", [NSString stringWithFormat:@"%@/ingredients/plus.png", [self s3BucketURL]], nil];
        NSDictionary *addRow = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        [self.ingredients insertObject:addRow atIndex:0];
        [self.ingredientsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.ingredientsCollectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]];
        
        self.navigationController.toolbarHidden = NO;
        [self.ingredientsTableView setEditing:YES animated:YES];
        
    } else {
        for (int i = 0; i < self.ingredients.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            
            [self.ingredientsCollectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            UICollectionViewCell *cell = [self.ingredientsCollectionView cellForItemAtIndexPath:indexPath];
            UIView *coverView = [cell viewWithTag:4];
            coverView.hidden = YES;
        }

        [self.ingredients removeObjectAtIndex:0];
        [self.ingredientsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.ingredientsCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]];
        
        self.navigationController.toolbarHidden = YES;
        
        [self.selectedIngredients removeAllObjects];
        [self.ingredientsTableView setEditing:NO animated:YES];

            }
    [super setEditing:editing animated:animated];
}

// table view delegate and dataSource methods

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

// collection view delegate and dataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.ingredients.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FridgeCell" forIndexPath:indexPath];
    
    NSDictionary *ingredient = [self.ingredients objectAtIndex:indexPath.row];
    
    NSString *url;
    
    if (PRODUCTION || [[NSString stringWithFormat:@"%@", [ingredient objectForKey:@"image"]] isEqualToString:[NSString stringWithFormat:@"%@/ingredients/default_ingredient_image.png", [self s3BucketURL]]]) {
        url = [NSString stringWithFormat:@"%@", [ingredient objectForKey:@"image"]];
    } else {
        url = [NSString stringWithFormat:@"http://localhost:5000/%@", [ingredient objectForKey:@"image"]];
    }
    UIButton *imageButton = (UIButton *)[cell viewWithTag:1];
    [imageButton setBackgroundImageWithURL:[NSURL URLWithString:url] forState:UIControlStateNormal];
    
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:2];
    nameLabel.text = [NSString stringWithFormat:@"%@", [ingredient objectForKey:@"name"]];
    
    [cell setShadowWithColor:[UIColor blackColor] Radius:1.0f Offset:CGSizeMake(1.0f, 1.0f) Opacity:0.4f];
    
    UIView *coverView = [cell viewWithTag:4];
    coverView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
    if ([self.selectedIngredients containsObject:ingredient]) {
        
        coverView.hidden = NO;
    } else {
        coverView.hidden = YES;
    }
    if (userIsInTheMiddleOfEditingIngredientsList && indexPath.row == 0) {
        nameLabel.text = @"Add";
    }
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [self.ingredientsCollectionView cellForItemAtIndexPath:indexPath];
    if (userIsInTheMiddleOfEditingIngredientsList) {
        if (indexPath.row == 0) {
            [self openAddIngredientsActionSheet];
            cell.selected = NO;
        } else {
            [self.selectedIngredients addObject:[self.ingredients objectAtIndex:indexPath.row]];
            UIView *coverView = [cell viewWithTag:4];
            coverView.hidden = NO;
        }
    } else {
        cell.selected = NO;
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (userIsInTheMiddleOfEditingIngredientsList) {
        UICollectionViewCell *cell = [self.ingredientsCollectionView cellForItemAtIndexPath:indexPath];
        if (indexPath.row != 0) {
            [self.selectedIngredients removeObject:[self.ingredients objectAtIndex:indexPath.row]];
            UIView *coverView = [cell viewWithTag:4];
            coverView.hidden = YES;
        } else {
            cell.selected = NO;
        }
    } 
}
@end
