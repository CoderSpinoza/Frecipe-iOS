//
//  FrecipeAddToGroceryListViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeAddToGroceryListViewController.h"
#import "FrecipeAPIClient.h"

@interface FrecipeAddToGroceryListViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate> {
    CGFloat originalHeight;

}

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
    [self registerForKeyboardNotification];
    
    self.screenName = @"Add to Grocery List";
    NSLog(@"%f", self.groceryListTableView.frame.origin.x );
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addButtonPressed:(UIBarButtonItem *)sender {
    NSString *path = @"groceries";
    
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
    
    NSLog(@"%@", parameters);
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [spinner stopAnimating];
        [blockingView removeFromSuperview];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [spinner stopAnimating];
        [blockingView removeFromSuperview];
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
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
        
        if (![self.groceryList containsObject:textField.text] && ![textField.text isEqualToString:@""]) {
            [self.groceryList addObject:[textField.text capitalizedString]];
            textField.text = @"";
            [self.groceryListTableView reloadData];
            if (self.groceryList.count > 0) {
                [self.groceryListTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.groceryList.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([tableView isEqual:self.groceryListTableView]) {
            [self.groceryList removeObjectAtIndex:indexPath.row];
            [self.groceryListTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

// keyboard notification methods

- (void)registerForKeyboardNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    originalHeight = self.groceryListTableView.frame.size.height;
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [UIView animateWithDuration:0.3 animations:^{
        self.groceryListTableView.frame = CGRectMake(self.groceryListTableView.frame.origin.x, self.groceryListTableView.frame.origin.y, self.groceryListTableView.frame.size.width, self.groceryListTableView.frame.size.height - (keyboardSize.height - self.view.frame.size.height + self.groceryListTableView.frame.origin.y + self.groceryListTableView.frame.size.height));
        
        
        if (self.groceryList.count > 0) {
            [self.groceryListTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.groceryList.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.groceryListTableView.frame = CGRectMake(self.groceryListTableView.frame.origin.x, self.groceryListTableView.frame.origin.y, self.groceryListTableView.frame.size.width, originalHeight);
}
@end
