//
//  FrecipeAddToGroceryListViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeAddToGroceryListViewController.h"
#import "FrecipeAPIClient.h"

@interface FrecipeAddToGroceryListViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *groceryList;

@end

@implementation FrecipeAddToGroceryListViewController

@synthesize groceryList = _groceryList;

- (NSMutableArray *)groceryList {
    if (_groceryList == nil) {
        _groceryList = [[NSMutableArray alloc] init];
    }
    return _groceryList;
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
    self.groceryField.delegate = self;
    self.groceryListTableView.delegate = self;
    self.groceryListTableView.dataSource = self;
    [self addGestureRecognizers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addButtonPressed {
    NSString *path = @"/groceries";
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    NSString *groceriesString = [self.groceryList componentsJoinedByString:@","];
    
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"groceries", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, groceriesString, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    // add a spinner view
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = self.view.center;
    
    UIView *blockingView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 20, self.view.frame.size.width, self.view.frame.size.height)];
    blockingView.backgroundColor = [UIColor grayColor];
    blockingView.alpha = 0.5;
    [blockingView addSubview:spinner];
    
    [self.view addSubview:blockingView];
    [spinner startAnimating];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [self dismissViewControllerAnimated:YES completion:nil];
        [spinner stopAnimating];
        [blockingView removeFromSuperview];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [spinner stopAnimating];
        [blockingView removeFromSuperview];
    }];
    [operation start];
}

- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)dismissKeyboard {
    [self.groceryField resignFirstResponder];
}

// text field delegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.groceryField]) {
        
        if (![self.groceryList containsObject:textField.text]) {
            [self.groceryList addObject:[textField.text capitalizedString]];
            textField.text = @"";
            [self.groceryListTableView reloadData];
        }
    }
    return YES;
}

// table view delegate methods
// table view methods
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
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"GroceryCell"];
    }
    
    NSString *grocery = [self.groceryList objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%u. %@", indexPath.row + 1, grocery];
    return cell;
}
@end
