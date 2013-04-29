//
//  FrecipeAddIngredientsViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeAddIngredientsViewController.h"
#import "FrecipeAPIClient.h"

@interface FrecipeAddIngredientsViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *ingredients;
@end

@implementation FrecipeAddIngredientsViewController

@synthesize ingredients = _ingredients;

- (NSMutableArray *)ingredients {
    if (_ingredients == nil) {
        _ingredients = [[NSMutableArray alloc] init];
    }
    return _ingredients;
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
    self.ingredientField.delegate = self;
    self.ingredientsTableView.delegate = self;
    self.ingredientsTableView.dataSource = self;
    
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
    NSString *path = @"/user_ingredients";
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    
    NSString *ingredientsString = [self.ingredients componentsJoinedByString:@","];
    
    NSArray *keys = [NSArray arrayWithObjects:@"id", @"ingredients", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, ingredientsString, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height);
    [self.view addSubview:spinner];
    [spinner startAnimating];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [spinner stopAnimating];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [spinner stopAnimating];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        
    }];
    [operation start];
}

- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)dismissKeyboard {
    [self.ingredientField resignFirstResponder];
}

// text field delegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ([textField isEqual:self.ingredientField]) {
        if (![self.ingredients containsObject:textField.text]) {
            [self.ingredients addObject:[textField.text capitalizedString]];
            [self.ingredientsTableView reloadData];
            self.ingredientField.text = @"";
        }
        
    }
    return YES;
}
// table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.ingredients.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"IngredientCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"IngredientCell"];
    }
    
    NSString *ingredient = [self.ingredients objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%u. %@", indexPath.row + 1, ingredient];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([tableView isEqual:self.ingredientsTableView]) {
            [self.ingredients removeObjectAtIndex:indexPath.row];
            [self.ingredientsTableView reloadData];
        }
    }
}

@end
