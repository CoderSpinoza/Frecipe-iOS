//
//  FrecipeRecipeDetailViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeRecipeDetailViewController.h"
#import "FrecipeAPIClient.h"
#import "FrecipeAppDelegate.h"
#import "FrecipeProfileViewController.h"
#import "FrecipeAddRecipeViewController.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import <QuartzCore/QuartzCore.h>

@interface FrecipeRecipeDetailViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, FrecipeRatingViewDelegate, UIAlertViewDelegate> {
    BOOL userIsInTheMiddleOfEditingIngredientsList;
}
@property (strong, nonatomic) NSMutableArray *ingredients;
@property (strong, nonatomic) NSMutableArray *directions;
@property (strong, nonatomic) NSDictionary *user;
@property (strong, nonatomic) NSMutableArray *missingIngredients;
@property (strong, nonatomic) NSMutableArray *selectedIngredients;
@property (strong, nonatomic) NSMutableArray *editMenu;
@end

@implementation FrecipeRecipeDetailViewController
@synthesize selectedIngredients = _selectedIngredients;
@synthesize editMenu = _editMenu;

- (NSMutableArray *)selectedIngredients {
    if (_selectedIngredients == nil) {
        _selectedIngredients = [[NSMutableArray alloc] init];
    }
    return _selectedIngredients;
}

- (NSMutableArray *)editMenu {
    if (_editMenu == nil) {
        _editMenu = [[NSMutableArray alloc] initWithObjects:@"Edit", @"Delete", nil];
    }
    return _editMenu;
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
    self.ingredientsTableView.dataSource = self;
    self.directionsTableView.dataSource = self;
    self.ingredientsTableView.delegate = self;
    self.directionsTableView.delegate = self;
    
    self.editMenuTableView.delegate = self;
    self.editMenuTableView.dataSource = self;
    
    self.ratingView.delegate = self;
    self.averageRatingView.delegate = self;
    self.averageRatingView.editable = NO;
    
    self.ratingBorderView.layer.cornerRadius = 5.0f;
    self.ratingBorderView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.ratingBorderView.layer.borderWidth = 2.0f;
    
    self.editMenuTableView.layer.cornerRadius = 5.0f;
    self.editMenuView.layer.cornerRadius = 5.0f;
    self.editMenuView.layer.borderWidth = 3.0f;
    self.editMenuView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.editMenuView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.editMenuView.layer.shadowOpacity = 0.75f;
    self.editMenuView.layer.shadowRadius = 5.0f;
    
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 900);
    
    [self addGestureRecognizers];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchRecipeDetail];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchRecipeDetail {
    NSString *path = @"recipes/detail";
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"id", @"authentication_token", nil];
    NSArray *values = [NSArray arrayWithObjects:self.recipeId, authentication_token, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = self.view.center;
    [self.view addSubview:spinner];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.title = [[JSON objectForKey:@"recipe"] objectForKey:@"name"];
        if (PRODUCTION) {
            [self.recipeImageView setImageWithURL:[JSON objectForKey:@"recipe_image"] placeholderImage:[UIImage imageNamed:@"iTunesArtwork.png"]];
        } else {
            [self.recipeImageView setImageWithURL:[NSString stringWithFormat:@"http://localhost:5000/%@",[JSON objectForKey:@"recipe_image"]] placeholderImage:[UIImage imageNamed:@"iTunesArtwork.png"]];
        }
        
        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"isOwner"]] isEqualToString:@"1"]) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editMenuButtonPressed)];
        }
        
        NSDictionary *user = [JSON objectForKey:@"user"];
        self.user = [JSON objectForKey:@"user"];
        [self.nameButton setTitle:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forState:UIControlStateNormal];
        
        [self.likesButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
        self.ingredients = [[NSMutableArray alloc] initWithArray:[JSON objectForKey:@"ingredients"]];
        
        [self.ingredients addObject:[NSDictionary dictionaryWithObject:@"Add to Grocery List" forKey:@"name"]];
        
        [self.ingredientsTableView reloadData];
        
        NSString *steps = [NSString stringWithFormat: @"%@", [JSON objectForKey:@"steps"]];
        
        if (![steps isEqualToString:@""]) {
            self.directions = [NSMutableArray arrayWithArray:[[NSString stringWithFormat: @"%@",[JSON objectForKey:@"steps"]] componentsSeparatedByString:@"\n"]];
            [self.directionsTableView reloadData];
        }
        
        self.missingIngredients = [JSON objectForKey:@"missing_ingredients"];
        
        
        
        // rating view
        self.averageRatingView.rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"rating"]] integerValue];
        self.ratingView.rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"user_rating"]] integerValue];
        // adjust table view heights
        self.ingredientsTableView.frame = CGRectMake(self.ingredientsTableView.frame.origin.x, self.ingredientsTableView.frame.origin.y, self.ingredientsTableView.frame.size.width, 44 * self.ingredients.count);
        
        self.directionsLabel.frame = CGRectMake(self.directionsLabel.frame.origin.x, self.ingredientsTableView.frame.origin.y + self.ingredientsTableView.frame.size.height + 20, self.directionsLabel.frame.size.width, self.directionsLabel.frame.size.height);
        
        self.directionsTableView.frame = CGRectMake(self.directionsTableView.frame.origin.x, self.directionsLabel.frame.origin.y + self.directionsLabel.frame.size.height + 20, self.directionsTableView.frame.size.width, self.directions.count * 44);
        
        self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.directionsTableView.frame.origin.y + self.directionsTableView.frame.size.height + 20);
        
        if ([self isTall] == NO) {
            self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.scrollView.contentSize.height + 80);
        }
        [spinner removeFromSuperview];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        [spinner removeFromSuperview];
        
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}

- (IBAction)likeButtonPressed {
    NSString *path = @"likes";
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"id", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        self.likesLabel.text = [NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]];
        [self.likesButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}

- (void)editMenuButtonPressed {
    self.editMenuView.frame = CGRectMake(self.editMenuView.frame.origin.x, self.scrollView.contentOffset.y + 15, self.editMenuView.frame.size.width, self.editMenuView.frame.size.height);
    if (self.editMenuView.alpha == 0) {
        [UIView animateWithDuration:0.5 animations:^{
            self.editMenuView.alpha = 1;
        }];
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            self.editMenuView.alpha = 0;
        }];
    }

}

- (void)rate {
    NSString *path = @"recipes/rate";
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"id", @"rating", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, [@(self.ratingView.rating) stringValue], nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSInteger rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"rating"]] integerValue];
        
        self.averageRatingView.rating = rating;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    [operation start];
}

- (void)addToGroceryList {
    
    if (self.selectedIngredients.count > 0) {
        NSString *path = @"groceries";
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
        
        
        NSMutableArray *ingredientsArray = [[NSMutableArray alloc] init];
        for (NSDictionary *ingredient in self.selectedIngredients) {
            [ingredientsArray addObject:[NSString stringWithFormat:@"%@", [ingredient objectForKey:@"name"]]];
        }
        NSString *groceriesString = [ingredientsArray componentsJoinedByString:@","];
        
        NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"groceries", nil];
        NSArray *values = [NSArray arrayWithObjects:authentication_token, groceriesString, nil];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        
        FrecipeAPIClient *client = [FrecipeAPIClient client];
        NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
        
        // add a spinner view
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.center = self.view.center;
        [spinner startAnimating];
        [self.view addSubview:spinner];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
            
            [self.missingIngredients removeObjectsInArray:self.selectedIngredients];
            [spinner stopAnimating];
            [spinner removeFromSuperview];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"%@", error);
            [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
            [spinner stopAnimating];
            [spinner removeFromSuperview];
        }];
        [operation start];
    }
    
}

- (void)goToEditRecipe {
    [UIView animateWithDuration:0.5 animations:^{
        self.editMenuView.alpha = 0;
    }];
    [self.editMenuTableView reloadData];
    [self performSegueWithIdentifier:@"EditRecipe" sender:self];
}

- (void)deleteRecipe {
    NSString *path = [NSString stringWithFormat:@"recipes/%@", self.recipeId];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"id", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"DELETE" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    [operation start];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Profile"]) {
        FrecipeProfileViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.userId = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"id"]];
        destinationViewController.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.title style:UIBarButtonItemStyleBordered target:destinationViewController action:@selector(popViewControllerFromStack)];
    } else if ([segue.identifier isEqualToString:@"EditRecipe"]) {
        FrecipeAddRecipeViewController *destinationController = segue.destinationViewController;
        
        destinationController.recipeId = self.recipeId;
        destinationController.ingredients = [[NSMutableArray alloc] init];
        destinationController.directions = [[NSMutableArray alloc] init];
        for (NSDictionary *ingredient in self.ingredients) {
            [destinationController.ingredients addObject:[ingredient objectForKey:@"name"]];
        }
        
        for (NSDictionary *step in self.directions) {
            [destinationController.directions addObject:step];
        }
        
        destinationController.editing = @"1";
        
        if (destinationController.view) {
            destinationController.navigationBar.topItem.title = self.title;
            destinationController.recipeNameField.text = self.title;
            [destinationController.recipeImageButton setImage:self.recipeImageView.image forState:UIControlStateNormal];
        }
    }
}

- (void)addGestureRecognizers {
    UITapGestureRecognizer *ratingGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideRatingView)];
    [self.averageRatingView addGestureRecognizer:ratingGestureRecognizer];
}

- (void)showOrHideRatingView {
    if (self.ratingBorderView.alpha == 0) {
        [UIView animateWithDuration:0.5 animations:^{
            self.ratingBorderView.alpha = 1;
        }];
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            self.ratingBorderView.alpha = 0;
        }];
    }
}

// rating view delegate methods
- (void)ratingViewDidRate:(FrecipeRatingView *)ratingView rating:(NSInteger)rating {
    if ([ratingView isEqual:self.averageRatingView]) {
        
        if (self.ratingBorderView.alpha == 0) {
            [UIView animateWithDuration:0.5 animations:^{
                self.ratingBorderView.alpha = 1;
            }];
        } else {
            [UIView animateWithDuration:0.5 animations:^{
                self.ratingBorderView.alpha = 0;
            }];
        }
    } else {
        [self rate];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Rating" message:[NSString stringWithFormat:@"You gave a rating of %d", rating] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }
    
}

// alert view delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Rating"]) {
        [UIView animateWithDuration:0.5 animations:^{
//            self.ratingBorderView.frame = CGRectMake(self.ratingBorderView.frame.origin.x, self.ratingBorderView.frame.origin.y, self.ratingBorderView.frame.size.width, 0);
            self.ratingBorderView.alpha = 0;
        }];
    }
}

// table view delegate methods

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if ([tableView isEqual:self.ingredientsTableView]) {
        if ([self.missingIngredients containsObject:[self.ingredients objectAtIndex:indexPath.row]]) {
            return YES;
        } else {
            return  NO;
        }
    } else {
        return  NO;
    }
    
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    userIsInTheMiddleOfEditingIngredientsList = editing;
    if (editing) {
        [self.ingredients replaceObjectAtIndex:self.ingredients.count - 1 withObject:[NSDictionary dictionaryWithObject:@"Confirm" forKey:@"name"]];
        [self.ingredientsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.ingredients.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.ingredientsTableView setEditing:YES animated:YES];
        
    } else {

        [self.ingredients replaceObjectAtIndex:self.ingredients.count - 1 withObject:[NSDictionary dictionaryWithObject:@"Add to Grocery List" forKey:@"name"]];
        [self.ingredientsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.ingredients.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.ingredientsTableView setEditing:NO animated:YES];
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
    
    if ([tableView isEqual:self.ingredientsTableView]) {
        return self.ingredients.count;
        
    } else if ([tableView isEqual:self.directionsTableView]){
        return self.directions.count;
    } else {
        return self.editMenu.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([tableView isEqual:self.ingredientsTableView]) {
        static NSString *CellIdentifier = @"IngredientCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"IngredientCell"];
        }
        NSDictionary *ingredient = [self.ingredients objectAtIndex:indexPath.row];
                
        if (indexPath.row != self.ingredients.count - 1) {
            cell.textLabel.text = [NSString stringWithFormat:@"%u. %@", indexPath.row + 1, [ingredient objectForKey:@"name"]];

            if (![self.missingIngredients containsObject:ingredient]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
                label.text = @"Missing";
                label.textColor = [UIColor redColor];
                label.textAlignment = NSTextAlignmentRight;
                label.font = [label.font fontWithSize:10];
                cell.accessoryView = label;
                
            }
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"%@", [ingredient objectForKey:@"name"]];
        }
        
        return cell;
    } else if([tableView isEqual:self.directionsTableView]) {
        static NSString *CellIdentifier = @"DirectionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DirectionCell"];
        }
        
        cell.textLabel.text = [NSString stringWithFormat:@"%u. %@", indexPath.row + 1, [self.directions objectAtIndex:indexPath.row]];
        return cell;
    } else {
        static NSString *CellIdentifier = @"MenuCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MenuCell"];
        }
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [self.editMenu objectAtIndex:indexPath.row]];
        return cell;

    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([tableView isEqual:self.ingredientsTableView]) {
        if (indexPath.row == self.ingredients.count - 1) {
            if (userIsInTheMiddleOfEditingIngredientsList == NO) {
                [self setEditing:YES animated:YES];
            } else {
                
                [self addToGroceryList];
                [self.selectedIngredients removeAllObjects];
                [self setEditing:NO animated:YES];
            }
            
        } else {
            if (userIsInTheMiddleOfEditingIngredientsList == YES) {
                if ([self.missingIngredients containsObject:[self.ingredients objectAtIndex:indexPath.row]]) {
                    if (![self.selectedIngredients containsObject:[self.ingredients objectAtIndex:indexPath.row]]) {
                        [self.selectedIngredients addObject:[self.ingredients objectAtIndex:indexPath.row]];
                    }
                }
            }
        }

    } else if ([tableView isEqual:self.editMenuTableView]) {
        if (indexPath.row == 0) {
            [self goToEditRecipe];
        } else {
            [self deleteRecipe];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (userIsInTheMiddleOfEditingIngredientsList == YES && [self.selectedIngredients containsObject:[self.ingredients objectAtIndex:indexPath.row]]) {
        [self.selectedIngredients removeObject:[self.ingredients objectAtIndex:indexPath.row]];
    }
}

@end
