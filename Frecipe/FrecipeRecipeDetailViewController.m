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

@interface FrecipeRecipeDetailViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, FrecipeRatingViewDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) NSMutableArray *ingredients;
@property (strong, nonatomic) NSMutableArray *directions;
@property (strong, nonatomic) NSDictionary *user;
@property (strong, nonatomic) NSMutableArray *missingIngredients;
@end

@implementation FrecipeRecipeDetailViewController

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
    
    self.ratingView.delegate = self;
    self.averageRatingView.delegate = self;
    self.averageRatingView.editable = NO;
    
    self.ratingBorderView.layer.cornerRadius = 5.0f;
    self.ratingBorderView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.ratingBorderView.layer.borderWidth = 2.0f;
    
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 900);
    
    
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
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(goToEditRecipe)];
        }
        
        NSDictionary *user = [JSON objectForKey:@"user"];
        self.user = [JSON objectForKey:@"user"];
        [self.nameButton setTitle:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forState:UIControlStateNormal];
        
        [self.likesButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
        self.ingredients = [[NSMutableArray alloc] initWithArray:[JSON objectForKey:@"ingredients"]];
        
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
        [spinner removeFromSuperview];
//        NSLog(@"%f %f", self.ratingView.frame.origin.y, self);
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (error.code == -1011) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Deleted" message:@"This recipe has been deleted" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            [alertView show];
        }
        
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

- (void)rate {
    NSString *path = @"recipes/rate";
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"id", @"rating", nil];
//    NSLog(@"%@ %@ %", authentication_token);
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

- (void)goToEditRecipe {
    [self performSegueWithIdentifier:@"EditRecipe" sender:self];
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
        
    } else {
        return self.directions.count;
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
        
        return cell;
    } else {
        static NSString *CellIdentifier = @"DirectionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DirectionCell"];
        }
        
        cell.textLabel.text = [NSString stringWithFormat:@"%u. %@", indexPath.row + 1, [self.directions objectAtIndex:indexPath.row]];
        return cell;
    }
}

@end
