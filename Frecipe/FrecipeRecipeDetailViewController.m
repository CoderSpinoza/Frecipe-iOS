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
#import "FrecipeFunctions.h"
#import "FPPopoverController.h"
#import "FrecipeEditDeleteViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <QuartzCore/QuartzCore.h>

@interface FrecipeRecipeDetailViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, FrecipeRatingViewDelegate, UIAlertViewDelegate, UITextFieldDelegate, FPPopoverControllerDelegate> {
    BOOL userIsInTheMiddleOfEditingIngredientsList;
}
@property (strong, nonatomic) NSMutableArray *ingredients;
@property (strong, nonatomic) NSMutableArray *directions;
@property (strong, nonatomic) NSMutableArray *comments;
@property (strong, nonatomic) NSDictionary *user;
@property (strong, nonatomic) NSMutableArray *missingIngredients;
@property (strong, nonatomic) NSMutableArray *selectedIngredients;
@property (strong, nonatomic) NSMutableArray *editMenu;

@property (strong, nonatomic) UIView *blockingView;
@property (nonatomic, assign) CGFloat originalHeight;

@property (strong,nonatomic) FPPopoverController *editDeletePopoverViewController;
@property (strong, nonatomic) FrecipeEditDeleteViewController *editDeleteViewController;

@property (strong, nonatomic) NSString *recipeImageURL;

@end

@implementation FrecipeRecipeDetailViewController
@synthesize selectedIngredients = _selectedIngredients;
@synthesize editMenu = _editMenu;
@synthesize blockingView = _blockingView;

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

- (UIView *)blockingView {
    if (_blockingView == nil) {
        _blockingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, [[UIScreen mainScreen] bounds].size.height)];
        _blockingView.backgroundColor = [UIColor blackColor];
        
        _blockingView.alpha = 0.5;
    }
    return _blockingView;
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
    
    
    self.ratingView.delegate = self;
    self.averageRatingView.delegate = self;
    self.averageRatingView.editable = NO;
    
    self.commentsTableView.delegate = self;
    self.commentsTableView.dataSource = self;
    
    self.commentField.delegate = self;
    
    self.ratingBorderView.layer.cornerRadius = 5.0f;
    [self.ratingBorderView setBasicShadow];
    
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 900);
    
    self.commentsView.layer.cornerRadius = 5.0f;
    self.commentsView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.commentsView.layer.shadowOpacity = 0.75f;
    self.commentsView.layer.shadowRadius = 5.0f;
    
    [self.commentButton setBackgroundImage:[UIImage imageNamed:@"button_background_image.png"] forState:UIControlStateHighlighted];
    
    
    self.recipeMainView.layer.cornerRadius = 2.0f;
    [self.recipeMainView setBasicShadow];
    
    [self.likeButton setImage:[UIImage imageNamed:@"thumb.png"] forState:UIControlStateSelected];
    [self.likeButton setImage:[UIImage imageNamed:@"thumb.png"] forState:UIControlStateHighlighted];
    
    [self addGestureRecognizers];
    [self registerForKeyboardNotification];
    [self setupEditMenu];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchRecipeDetail];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupEditMenu {
    self.editDeleteViewController = [[FrecipeEditDeleteViewController alloc] initWithStyle:UITableViewStylePlain];
    self.editDeletePopoverViewController = [[FPPopoverController alloc] initWithViewController:self.editDeleteViewController];
    self.editDeleteViewController.tableView.delegate = self;
    self.editDeletePopoverViewController.delegate = self;
    self.editDeletePopoverViewController.contentSize = CGSizeMake(120, 128);
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
        self.recipeImageURL = [NSString stringWithFormat:@"%@", [JSON objectForKey:@"recipe_image"]];
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
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSString *provider = [defaults stringForKey:@"provider"];
        if (![provider isEqualToString:@"facebook"]) {
            self.shareButton.enabled = NO;
        }
        [self.nameButton setTitle:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forState:UIControlStateNormal];
        
        [self.likesButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
        
        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"liked"]] isEqualToString:@"1"]) {
            self.likeButton.selected = YES;
        } else {
            self.likeButton.selected = NO;
        }
        self.ingredients = [[NSMutableArray alloc] initWithArray:[JSON objectForKey:@"ingredients"]];
        
        [self.ingredientsTableView reloadData];
        
        NSString *steps = [NSString stringWithFormat: @"%@", [JSON objectForKey:@"steps"]];
        
        if (![steps isEqualToString:@""]) {
            self.directions = [NSMutableArray arrayWithArray:[[NSString stringWithFormat: @"%@",[JSON objectForKey:@"steps"]] componentsSeparatedByString:@"\n"]];
            [self.directionsTableView reloadData];
        }
        
        self.missingIngredients = [NSMutableArray arrayWithArray:[JSON objectForKey:@"missing_ingredients"]];
        
        // rating view
        self.averageRatingView.rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"rating"]] floatValue];
        self.ratingView.rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"user_rating"]] integerValue];
        // adjust table view heights
        self.ingredientsTableView.frame = CGRectMake(self.ingredientsTableView.frame.origin.x, self.ingredientsTableView.frame.origin.y, self.ingredientsTableView.frame.size.width, 44 * self.ingredients.count);
        
        self.addToGroceryListButton.frame = CGRectMake(self.addToGroceryListButton.frame.origin.x, self.ingredientsTableView.frame.origin.y + self.ingredientsTableView.frame.size.height + 5, self.addToGroceryListButton.frame.size.width, self.addToGroceryListButton.frame.size.height);
        
        self.ingredientsView.frame = CGRectMake(self.ingredientsView.frame.origin.x, self.ingredientsView.frame.origin.y, self.ingredientsView.frame.size.width, self.ingredientsTableView.frame.origin.y + self.ingredientsTableView.frame.size.height + self.addToGroceryListButton.frame.size.height + 10);
        
        self.directionsLabel.frame = CGRectMake(self.directionsLabel.frame.origin.x, 5, self.directionsLabel.frame.size.width, self.directionsLabel.frame.size.height);
        
        self.directionsTableView.frame = CGRectMake(self.directionsTableView.frame.origin.x, self.directionsLabel.frame.size.height + 10, self.directionsTableView.frame.size.width, self.directions.count * 44);
        
        if (self.directions.count > 0) {
            self.directionsView.frame = CGRectMake(self.directionsView.frame.origin.x, self.ingredientsView.frame.origin.y + self.ingredientsView.frame.size.height + 20, self.directionsView.frame.size.width, self.directionsLabel.frame.size.height + self.directionsTableView.frame.size.height + 10);
        } else {
            self.directionsView.frame = CGRectMake(self.directionsView.frame.origin.x, self.ingredientsView.frame.origin.y + self.ingredientsView.frame.size.height + 10, self.directionsView.frame.size.width, 50);
        }
        
        
        [self.ingredientsView setBasicShadow];
        [self.directionsView setBasicShadow];
        // comments
        
        self.comments = [NSMutableArray arrayWithArray:[JSON objectForKey:@"comments"]];
        [self.commentsTableView reloadData];
        self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.directionsView.frame.origin.y + self.directionsView.frame.size.height + 10);
        
        if ([self isTall] == NO) {
            self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.scrollView.contentSize.height + 90);
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

        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"message"]] isEqualToString:@"like"]) {
            self.likeButton.selected = YES;
        } else {
            self.likeButton.selected = NO;
        }
        [self.likesButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}

- (IBAction)shareButtonPressed {
    if (FBSession.activeSession.isOpen) {
        [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"] defaultAudience:FBSessionDefaultAudienceOnlyMe completionHandler:^(FBSession *session, NSError *error) {
            
            [FBRequestConnection startForPostOpenGraphObjectWithType:@"website" title:[NSString stringWithFormat:@"%@ has shared a recipe!", [[NSUserDefaults standardUserDefaults] stringForKey:@"name"]]image:self.recipeImageURL url:@"https://itunes.apple.com/us/app/itunes-u/id490217893" description:@"Go to this link to download Frecipe!" objectProperties:nil completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                UIAlertView *alertView;
                if (!error) {
                    alertView = [[UIAlertView alloc] initWithTitle:@"Facebook Share" message:@"Successfully shared a recipe!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                } else {
                    alertView = [[UIAlertView alloc] initWithTitle:@"Facebook share error" message:@"There was an error sharing a recipe on facebook" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                }
                [alertView show];
            }];        
        }];
    }
}

- (IBAction)commentButtonPressed {
    [self.blockingView removeFromSuperview];
    [self.commentsView removeFromSuperview];
    
    [[[[UIApplication sharedApplication] delegate] window] addSubview:self.blockingView];
    [[[[UIApplication sharedApplication] delegate] window] addSubview:self.commentsView];

    if (self.commentsView.alpha == 0) {
        [UIView animateWithDuration:0.3 animations:^{
            self.commentsView.alpha = 1;
            self.commentsView.frame = CGRectMake(0, self.commentsView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
            self.commentsTableView.frame = CGRectMake(self.commentsTableView.frame.origin.x, self.commentsTableView.frame.origin.y, self.commentsTableView.frame.size.width, self.view.frame.size.height * 0.8);
            
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.commentsView.alpha = 0;
            self.commentsView.frame = CGRectMake(0, self.commentsView.frame.origin.y, self.view.frame.size.width, 0);
        }];
    }
}

- (IBAction)commentCloseButtonPressed {
    [self.commentField resignFirstResponder];
    [self.blockingView removeFromSuperview];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.commentsView.alpha = 0;
        self.commentsView.frame = CGRectMake(0, self.commentsView.frame.origin.y, self.view.frame.size.width, 0);
    }];
}
- (IBAction)commentSubmitButtonPressed {
    
    if (self.commentField.text.length > 0) {
        NSString *path = @"comments";
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
        
        NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"recipe_id", @"text", nil];
        NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, self.commentField.text, nil];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        
        FrecipeAPIClient *client = [FrecipeAPIClient client];
        NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            self.comments = [JSON objectForKey:@"comments"];
            [self.commentsTableView reloadData];
            
            if (self.comments.count) {
                [self.commentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.comments.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
            }
            
            [self dismissKeyboard];
            self.commentField.text = @"";
            
            [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"%@", error);
            
            [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        }];
        [operation start];
    }
    
}

- (void)editMenuButtonPressed {
    [self.editDeletePopoverViewController presentPopoverFromPoint:CGPointMake(self.view.frame.size.width- 30, 40)];
}

- (IBAction)commentDeleteButtonPressed:(UIButton *)sender {
    NSIndexPath *indexPath = [self.commentsTableView indexPathForCell:(UITableViewCell *)sender.superview.superview];
    NSDictionary  *comment = [[self.comments objectAtIndex:indexPath.row] objectForKey:@"comment"];
    
    NSString *path = [NSString stringWithFormat:@"comments/%@", [comment objectForKey:@"id"]];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"recipe_id", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"DELETE" path:path parameters:parameters];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = self.commentsView.center;
    [spinner startAnimating];
    [self.commentsView addSubview:spinner];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.comments = [JSON objectForKey:@"comments"];
        [self.commentsTableView reloadData];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [spinner stopAnimating];
        [spinner removeFromSuperview];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [spinner stopAnimating];
        [spinner removeFromSuperview];
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
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, [@(self.ratingView.rating) stringValue], nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        CGFloat rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"rating"]] floatValue];
        
        self.averageRatingView.rating = rating;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    [operation start];
}

- (IBAction)addToGroceryList {
    NSString *path = @"groceries";
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    
    
    NSMutableArray *ingredientsArray = [[NSMutableArray alloc] init];
    NSMutableArray *inFridgeArray = [[NSMutableArray alloc] init];
    for (NSDictionary *ingredient in self.ingredients) {
        [ingredientsArray addObject:[NSString stringWithFormat:@"%@", [ingredient objectForKey:@"name"]]];
        
        if ([self.missingIngredients containsObject:ingredient]) {
            [inFridgeArray addObject:@"1"];
        } else {
            [inFridgeArray addObject:@"0"];
        }
    }
    
    NSLog(@"%@", inFridgeArray);
    
    NSString *groceriesString = [ingredientsArray componentsJoinedByString:@","];
    
    NSString *inFridgeString = [inFridgeArray componentsJoinedByString:@","];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"recipe_id", @"groceries", @"in_fridge", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, groceriesString, inFridgeString, nil];
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
        NSLog(@"%@", self.missingIngredients);
        [self.missingIngredients removeObjectsInArray:self.selectedIngredients];
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Successfully added to Grocery List!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [spinner stopAnimating];
        [spinner removeFromSuperview];
    }];
    [operation start];
}


- (void)goToEditRecipe {
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
        destinationViewController.fromSegue = YES;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.title style:UIBarButtonItemStyleBordered target:destinationViewController action:@selector(popViewControllerFromStack)];
        
        self.navigationItem.backBarButtonItem.image = [UIImage imageNamed:@"back_arrow.png"];
    } else if ([segue.identifier isEqualToString:@"EditRecipe"]) {
        FrecipeAddRecipeViewController *destinationController = segue.destinationViewController;
        
        destinationController.recipeId = self.recipeId;
        destinationController.ingredients = [[NSMutableArray alloc] init];
        destinationController.directions = [[NSMutableArray alloc] init];
        for (NSDictionary *ingredient in self.ingredients) {
            [destinationController.ingredients addObject:[ingredient objectForKey:@"name"]];
        }
        
        [destinationController.ingredients removeObjectAtIndex:destinationController.ingredients.count - 1];
        
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
    
    UITapGestureRecognizer *commentViewGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.commentsView addGestureRecognizer:commentViewGestureRecognizer];
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

- (void)dismissKeyboard {
    [self.commentField resignFirstResponder];
}

// rating view delegate methods
- (void)ratingViewDidRate:(FrecipeRatingView *)ratingView rating:(CGFloat)rating {
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
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Rating" message:[NSString stringWithFormat:@"You gave a rating of %@", [NSNumber numberWithFloat:rating]] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }
    
}

// text field delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.commentField resignFirstResponder];
    return YES;
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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size;
    if ([tableView isEqual:self.commentsTableView]) {
        NSDictionary *comment = [[self.comments objectAtIndex:indexPath.row] objectForKey:@"comment"];
        
        NSString *text = [NSString stringWithFormat:@"%@",[comment objectForKey:@"text"]];
        
        CGSize constraintSize = CGSizeMake(220, MAXFLOAT);
        CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
        
        return 50 + textSize.height;
    } else if ([tableView isEqual:self.directionsTableView]){
        size = [[NSString stringWithFormat:@"%u. %@", indexPath.row + 1, [self.directions objectAtIndex:indexPath.row]] sizeWithFont:[UIFont systemFontOfSize:18.0f] constrainedToSize:CGSizeMake(220.0f, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
        NSInteger lines = round(size.height / 18);
        if (lines < 2) {
            return 44;
        } else {
            return size.height + 16;
        }

    } else {
        return 44;
    }
}
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
    } else if ([tableView isEqual:self.commentsTableView]) {
        return self.comments.count;
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
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
        cell.userInteractionEnabled = NO;
        // enable cell selection for only the last row
    
        
        return cell;
    } else if([tableView isEqual:self.directionsTableView]) {
        static NSString *CellIdentifier = @"DirectionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DirectionCell"];
        }
        
        cell.textLabel.text = [NSString stringWithFormat:@"%u. %@", indexPath.row + 1, [self.directions objectAtIndex:indexPath.row]];
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        return cell;
    } else if ([tableView isEqual:self.commentsTableView]) {
        static NSString *CellIdentifier = @"CommentCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CommentCell"];
        }
        
        NSDictionary *userAndComment = [self.comments objectAtIndex:indexPath.row];
        NSDictionary *user = [userAndComment objectForKey:@"user"];
        NSDictionary *comment = [userAndComment objectForKey:@"comment"];
        FBProfilePictureView *fbProfilePictureView = (FBProfilePictureView *)[cell viewWithTag:1];
        UIImageView *profilePictureView = (UIImageView *)[cell viewWithTag:2];
        if ([[NSString stringWithFormat:@"%@", [user objectForKey:@"provider"]] isEqualToString:@"facebook"]) {
            profilePictureView.hidden = YES;
            fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [user objectForKey:@"uid"]];
        } else {
            fbProfilePictureView.hidden = YES;
            [profilePictureView setImageWithURL:[NSString stringWithFormat:@"%@", [user objectForKey:@"profile_picture"]] placeholderImage:[UIImage imageNamed:@"default_profile_picture"]];
        }
        
        UIButton *nameButton = (UIButton *)[cell viewWithTag:3];
        [nameButton setTitle:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forState:UIControlStateNormal];
        [nameButton sizeToFit];
        
        UITextView *textView = (UITextView *)[cell viewWithTag:4];
        textView.text = [NSString stringWithFormat:@"%@", [comment objectForKey:@"text"]];
        
        CGSize constraintSize = CGSizeMake(280, MAXFLOAT);
        
        CGSize textSize = [textView.text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
        textView.frame = CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, textSize.height + 20);
        
        UILabel *timeLabel = (UILabel *)[cell viewWithTag:5];
        timeLabel.text = [FrecipeFunctions compareWithCurrentDate:[comment objectForKey:@"created_at"]];
        
        [timeLabel sizeToFit];
        UIButton *deleteButton = (UIButton *)[cell viewWithTag:6];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *userId = [NSString stringWithFormat:@"%@", [defaults objectForKey:@"id"]];
        if (![userId isEqualToString:[NSString stringWithFormat:@"%@", [user objectForKey:@"id"]]]) {
            deleteButton.hidden = YES;
        } else {
            
            deleteButton.frame = CGRectMake(timeLabel.frame.origin.x + timeLabel.frame.size.width - 5, deleteButton.frame.origin.y, deleteButton.frame.size.width, deleteButton.frame.size.height);
        }
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
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
    
    if ([tableView isEqual:self.editDeleteViewController.tableView]) {
        [self.editDeletePopoverViewController dismissPopoverAnimated:YES];
        if (indexPath.row == 0) {
            [self goToEditRecipe];
        } else {
            [self deleteRecipe];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
}

// keybaord notification
- (void)registerForKeyboardNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    self.originalHeight = self.commentsTableView.frame.size.height;
    
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    
    [UIView animateWithDuration:0.3 animations:^{
        self.commentsTableView.frame = CGRectMake(self.commentsTableView.frame.origin.x, self.commentsTableView.frame.origin.y, self.commentsTableView.frame.size.width, self.commentsTableView.frame.size.height - (keyboardSize.height - self.view.frame.size.height + self.commentsTableView.frame.origin.y + self.commentsTableView.frame.size.height) - 40);
        
        self.commentField.frame = CGRectMake(self.commentField.frame.origin.x, self.commentField.frame.origin.y - keyboardSize.height + 25, self.commentField.frame.size.width, self.commentField.frame.size.height);
        
        self.commentSubmitButton.frame = CGRectMake(self.commentSubmitButton.frame.origin.x, self.commentSubmitButton.frame.origin.y - keyboardSize.height + 25, self.commentSubmitButton.frame.size.width, self.commentSubmitButton.frame.size.height);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.commentsTableView.frame = CGRectMake(self.commentsTableView.frame.origin.x, self.commentsTableView.frame.origin.y, self.commentsTableView.frame.size.width, self.originalHeight);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.commentField.frame = CGRectMake(self.commentField.frame.origin.x, self.commentField.frame.origin.y + keyboardSize.height - 25, self.commentField.frame.size.width, self.commentField.frame.size.height);
        
        self.commentSubmitButton.frame = CGRectMake(self.commentSubmitButton.frame.origin.x, self.commentSubmitButton.frame.origin.y + keyboardSize.height - 25, self.commentSubmitButton.frame.size.width, self.commentSubmitButton.frame.size.height);
    }];
}

@end
