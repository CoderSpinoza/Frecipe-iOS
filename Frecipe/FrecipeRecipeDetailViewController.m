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
#import "FrecipeCommentsViewController.h"
#import <GAI.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <QuartzCore/QuartzCore.h>

@interface FrecipeRecipeDetailViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, FrecipeRatingViewDelegate, UIAlertViewDelegate, UITextFieldDelegate, FPPopoverControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    BOOL userIsInTheMiddleOfEditingIngredientsList;
    BOOL userHasUploadedAPhoto;
    BOOL isCommentsOpen;
}

@property (strong, nonatomic) NSMutableArray *ingredients;
@property (strong, nonatomic) NSMutableArray *userIngredients;

@property (strong, nonatomic) NSMutableArray *directions;
@property (strong, nonatomic) NSMutableArray *comments;
@property (strong, nonatomic) NSDictionary *user;
@property (strong, nonatomic) NSMutableArray *missingIngredients;
@property (strong, nonatomic) NSMutableArray *selectedIngredients;
@property (strong, nonatomic) NSMutableArray *editMenu;

@property (strong, nonatomic) UIView *blockingView;
@property (nonatomic, assign) CGFloat originalHeight;

@property (strong, nonatomic) NSString *recipeImageURL;

@property (strong, nonatomic) NSMutableArray *masteredImages;

@property (strong, nonatomic) UIImage *masteredImage;

@property (strong, nonatomic) NSIndexPath *selectedCommentIndexPath;


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
    
    self.trackedViewName = @"Recipe Detail";
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
    
    
    self.commentsView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bottom_bar.png"]];
    self.commentsTableView.backgroundColor = [UIColor clearColor];   
    
    self.recipeMainView.layer.cornerRadius = 2.0f;
    [self.recipeMainView setBasicShadow];
    
    self.bottomBar.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"bottom_bar.png"]];
    [self addGestureRecognizers];
    [self setupEditMenu];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchRecipeDetail];
    [self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeForKeyboardNotifications];
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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"id", @"authentication_token", nil];
    NSArray *values = [NSArray arrayWithObjects:self.recipeId, authentication_token, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:parameters];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = self.view.center;
    [self.view addSubview:spinner];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        self.title = [NSString stringWithFormat:@"%@", [[JSON objectForKey:@"recipe"] objectForKey:@"name"]];
        self.recipeImageURL = [NSString stringWithFormat:@"%@", [JSON objectForKey:@"recipe_image"]];
        if (PRODUCTION) {
            [self.recipeImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"recipe_image"]]] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"]];
        } else {
            [self.recipeImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5000/%@",[JSON objectForKey:@"recipe_image"]]] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"]];
        }
        
        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"isOwner"]] isEqualToString:@"1"]) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editMenuButtonPressed)];
        }
        
        self.user = [JSON objectForKey:@"user"];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSString *provider = [defaults stringForKey:@"provider"];
        if (![provider isEqualToString:@"facebook"]) {
            self.shareButton.enabled = NO;
        }
        [self.nameButton setTitle:[NSString stringWithFormat:@"%@ %@", [self.user objectForKey:@"first_name"], [self.user objectForKey:@"last_name"]] forState:UIControlStateNormal];
        
        [self.likesButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
        
        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"liked"]] isEqualToString:@"1"]) {
            self.likeButton.selected = YES;
        } else {
            self.likeButton.selected = NO;
        }
        
        
        
        // new buttons
        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"liked"]] isEqualToString:@"1"]) {
            self.heartButton.selected = YES;
        } else {
            self.heartButton.selected = NO;
        }
        
        [self.heartButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
        
        self.ingredients = [[NSMutableArray alloc] initWithArray:[JSON objectForKey:@"ingredients"]];
        
        [self.ingredientsTableView reloadData];
        
        NSString *steps = [NSString stringWithFormat: @"%@", [JSON objectForKey:@"steps"]];
        
        if (![steps isEqualToString:@""]) {
            self.directions = [NSMutableArray arrayWithArray:[[NSString stringWithFormat: @"%@",[JSON objectForKey:@"steps"]] componentsSeparatedByString:@"\n"]];
            [self.directionsTableView reloadData];
        }
        
        self.missingIngredients = [NSMutableArray arrayWithArray:[JSON objectForKey:@"missing_ingredients"]];
        
        self.userIngredients = [NSMutableArray arrayWithArray:[JSON objectForKey:@"user_ingredients"]];
        
        
        NSIndexSet *indexSet = [self.missingIngredients indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [self.userIngredients containsObject:[obj objectForKey:@"value"]];
        }];
        [self.missingIngredients removeObjectsAtIndexes:indexSet];
        // rating view
        self.averageRatingView.rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"rating"]] floatValue];
        self.ratingView.rating = [[NSString stringWithFormat:@"%@", [JSON objectForKey:@"user_rating"]] integerValue];
        // adjust table view heights
        self.ingredientsTableView.frame = CGRectMake(self.ingredientsTableView.frame.origin.x, self.ingredientsTableView.frame.origin.y, self.ingredientsTableView.frame.size.width, 44 * self.ingredients.count);
        
        self.addToGroceryListButton.frame = CGRectMake(self.addToGroceryListButton.frame.origin.x, self.ingredientsTableView.frame.origin.y + self.ingredientsTableView.frame.size.height + 5, self.addToGroceryListButton.frame.size.width, self.addToGroceryListButton.frame.size.height);
        
        self.ingredientsView.frame = CGRectMake(self.ingredientsView.frame.origin.x, self.ingredientsView.frame.origin.y, self.ingredientsView.frame.size.width, self.ingredientsTableView.frame.origin.y + self.ingredientsTableView.frame.size.height + self.addToGroceryListButton.frame.size.height + 10);
        
        self.directionsLabel.frame = CGRectMake(self.directionsLabel.frame.origin.x, 5, self.directionsLabel.frame.size.width, self.directionsLabel.frame.size.height);
        
        
        CGFloat totalHeight = 0;
        
        for (int i = 0; i < self.directions.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            CGFloat currentHeight = [self tableView:self.directionsTableView heightForRowAtIndexPath:indexPath];
            totalHeight += currentHeight;
            
        }
        self.directionsTableView.frame = CGRectMake(self.directionsTableView.frame.origin.x, self.directionsLabel.frame.size.height + 10, self.directionsTableView.frame.size.width, totalHeight);
        
        if (self.directions.count > 0) {
            self.directionsView.frame = CGRectMake(self.directionsView.frame.origin.x, self.ingredientsView.frame.origin.y + self.ingredientsView.frame.size.height + 20, self.directionsView.frame.size.width, self.directionsLabel.frame.size.height + self.directionsTableView.frame.size.height + 10);
        } else {
            self.directionsView.frame = CGRectMake(self.directionsView.frame.origin.x, self.ingredientsView.frame.origin.y + self.ingredientsView.frame.size.height + 10, self.directionsView.frame.size.width, 50);
        }
        
        [self.ingredientsView setBasicShadow];
        [self.directionsView setBasicShadow];
        // comments
        
        self.comments = [NSMutableArray arrayWithArray:[JSON objectForKey:@"comments"]];
        
        if (self.comments.count > 0) {
            self.beTheFirstToCommentLabel.hidden = YES;
        }
        
        [self.commentsTableView reloadData];
        
        if (self.commentId) {
            [self commentButtonPressed];
            [self.commentsTableView scrollToRowAtIndexPath:self.selectedCommentIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        
        if (self.comments.count > 0) {
            
            [self.commentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.comments.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
         [self.commentNewButton setTitle:[NSString stringWithFormat:@"%i", self.comments.count] forState:UIControlStateNormal];

        self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.directionsView.frame.origin.y + self.directionsView.frame.size.height + 54);
        
        
        if ([self isTall] == NO) {
            self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.scrollView.contentSize.height + 90);
        }
        [spinner removeFromSuperview];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [spinner removeFromSuperview];
        if (response.statusCode == 404) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Recipe Error" message:@"The recipe was deleted or could not be found" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            [alertView show];
        }
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];    
}   

- (IBAction)likeButtonPressed {
    [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Recipe Detail" withAction:@"Like" withLabel:@"Like" withValue:[NSNumber numberWithInt:1]];
    if (self.heartButton.selected == NO) {
        self.heartButton.selected = YES;
    } else {
        self.heartButton.selected = NO;
    }
    
    NSString *path = @"likes";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"id", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

//        if ([[NSString stringWithFormat:@"%@", [JSON objectForKey:@"message"]] isEqualToString:@"like"]) {
//            self.likeButton.selected = YES;
//        } else {
//            self.likeButton.selected = NO;
//        }
        
        [self.heartButton setTitle:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"likes"]] forState:UIControlStateNormal];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (IBAction)masterButtonPressed {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"How to upload photo?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Photo Library", nil];
    [actionSheet showInView:self.view];
}

// UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self openRecipeImagePicker:@"camera"];
    } else if (buttonIndex == 1) {
        [self openRecipeImagePicker:@"library"];
    }
}

- (void)openRecipeImagePicker:(NSString *)sourceType {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    
    if ([sourceType isEqualToString:@"camera"]) {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    imagePickerController.delegate = self;
    imagePickerController.restorationIdentifier = @"recipeImage";
    imagePickerController.allowsEditing = YES;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    
    if ([picker.restorationIdentifier isEqualToString:@"recipeImage"]) {
        self.masteredImage = [info valueForKey:UIImagePickerControllerEditedImage];
        userHasUploadedAPhoto = YES;
        [picker dismissViewControllerAnimated:YES completion:^{
            [self uploadMasteredPicture];
        }];
    }
//    }
    
}

- (void)uploadMasteredPicture {
    NSString *path = @"recipe_images.json";
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSDictionary *parameters = @{@"authentication_token": [[NSUserDefaults standardUserDefaults] stringForKey:@"authentication_token"], @"recipe_id": self.recipeId };
    
    NSMutableURLRequest *request = [client multipartFormRequestWithMethod:@"POST" path:path parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImagePNGRepresentation(self.masteredImage) name:@"recipe_image" fileName:@"recipe_image.png" mimeType:@"image/png"];
    }];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}


- (IBAction)shareButtonPressed {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Facebook Share" message:@"Share this recipe on your facebook wall?" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: @"Cancel", nil];
    [alertView show];
    }

- (void)publishToFacebook {
    if (FBSession.activeSession.isOpen) {
        NSString *path = @"facebook/share";
        FrecipeAPIClient *client = [FrecipeAPIClient client];
        NSDictionary *parameters = @{@"authentication_token": [[NSUserDefaults standardUserDefaults] stringForKey:@"authentication_token"], @"recipe_id": self.recipeId};
        
        NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"%@", [error localizedDescription]);
        }];
        
        FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
        [queue addOperation:operation];
        [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
            
            
            [FBRequestConnection startForPostOpenGraphObjectWithType:@"website" title:[NSString stringWithFormat:@"%@ has shared %@'s recipe, %@!", [[NSUserDefaults standardUserDefaults] stringForKey:@"name"], [self.user objectForKey:@"first_name"], self.title] image:self.recipeImageURL url:@"https://itunes.apple.com/us/app/id661973790?mt=8" description:@"Go to this link to download Frecipe!" objectProperties:@{@"fb:explicitly_shared": @"true"} completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                
                // send to google analytics
                [[[GAI sharedInstance] defaultTracker] sendSocial:@"Facebook" withAction:@"Recipe Share" withTarget:self.title];
                
                UIAlertView *alertView;
                if (!error) {
                    alertView = [[UIAlertView alloc] initWithTitle:@"Successfully Shared!" message:@"Successfully shared a recipe on your wall!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                } else {
                    alertView = [[UIAlertView alloc] initWithTitle:@"Facebook share error" message:@"There was an error sharing a recipe on facebook" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                }
                [alertView show];
            }];
        }];
    }    
}

- (IBAction)commentButtonPressed {
    CGRect frame;
    if (isCommentsOpen) {
        frame = CGRectMake(0, self.bottomBar.frame.origin.y, self.commentsView.frame.size.width, 0);
        
        [UIView animateWithDuration:0.5 animations:^{
            self.commentsView.frame = frame;
            self.commentsView.alpha = 0;
        }];
    } else {

        frame = CGRectMake(0, 0, self.commentsView.frame.size.width, self.bottomBar.frame.origin.y);
        
        [UIView animateWithDuration:0.5 animations:^{
            self.commentsView.frame = frame;
            self.commentsView.alpha = 1;
        }];
        
        self.commentsTableView.frame = CGRectMake(self.commentsTableView.frame.origin.x, self.commentsTableView.frame.origin.y, self.commentsTableView.frame.size.width, self.commentField.frame.origin.y - self.commentsTableView.frame.origin.y - 5);
        
        if (self.comments.count > 0) {
            [self.commentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.comments.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
    }
    
    isCommentsOpen = !isCommentsOpen;
}

- (IBAction)commentCloseButtonPressed {
    [self commentButtonPressed];
    [self.commentField resignFirstResponder];
}

- (IBAction)commentSubmitButtonPressed {
    
    if (self.commentField.text.length > 0) {
        NSString *path = @"comments";

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
        
        NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"recipe_id", @"text", nil];
        NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, self.commentField.text, nil];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        
        FrecipeAPIClient *client = [FrecipeAPIClient client];
        NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
        
        self.commentSubmitButton.enabled = NO;
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            self.comments = [JSON objectForKey:@"comments"];
            [self.commentNewButton setTitle:[NSString stringWithFormat:@"%i", self.comments.count] forState:UIControlStateNormal];
            [self.commentsTableView reloadData];
            [self dismissKeyboard];
            self.commentField.text = @"";
            self.commentSubmitButton.enabled = YES;
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"%@", error);
            self.commentSubmitButton.enabled = YES;
        }];
        FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
        [queue addOperation:operation];
    }
    
}

- (void)editMenuButtonPressed {
    
    [self.editDeletePopoverViewController presentPopoverFromPoint:CGPointMake(self.view.frame.size.width - 30, 40)];
}

- (IBAction)commentDeleteButtonPressed:(UIButton *)sender {
    NSIndexPath *indexPath = [self.commentsTableView indexPathForCell:(UITableViewCell *)sender.superview.superview];
//    NSDictionary  *comment = [self.comments objectAtIndex:indexPath.row] objectForKey:@"comment"];
    NSDictionary *userAndComment = [self.comments objectAtIndex:indexPath.row];
    
    NSString *path = [NSString stringWithFormat:@"comments/%@", [userAndComment objectForKey:@"comment_id"]];

    
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
        [self.commentNewButton setTitle:[NSString stringWithFormat:@"%i", self.comments.count] forState:UIControlStateNormal];

        [spinner stopAnimating];
        [spinner removeFromSuperview];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}


- (void)rate {
    NSString *path = @"recipes/rate";
    
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
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (IBAction)addToGroceryList {
    [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Recipe Detail" withAction:@"Add to Grocery List" withLabel:@"Add to Grocery List" withValue:[NSNumber numberWithInt:1]];
    NSString *path = @"groceries";
    
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
        [self.missingIngredients removeObjectsInArray:self.selectedIngredients];
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Successfully added to Grocery List!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [spinner stopAnimating];
        [spinner removeFromSuperview];
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}


- (void)goToEditRecipe {
    [self performSegueWithIdentifier:@"EditRecipe" sender:self];
}

- (void)deleteRecipe {
    NSString *path = [NSString stringWithFormat:@"recipes/%@", self.recipeId];
    
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
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
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
    
//    UITapGestureRecognizer *
//    [self.commentsPopoverViewController.view addGestureRecognizer:commentViewGestureRecognizer];
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
            self.ratingBorderView.alpha = 0;
        }];
    } else if ([alertView.title isEqualToString:@"Recipe Error"]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if ([alertView.title isEqualToString:@"Facebook Share"]) {
        if (buttonIndex == 0) {
            [self publishToFacebook];
        }
    }
}

// table view dataSource methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size;
    if ([tableView isEqual:self.commentsTableView]) {
        NSDictionary *comment = [self.comments objectAtIndex:indexPath.row];
        
        NSString *text = [NSString stringWithFormat:@"%@",[comment objectForKey:@"text"]];
        
        CGSize constraintSize = CGSizeMake(260, MAXFLOAT);
        CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:13] constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
        
        return 50 + textSize.height;
    } else if ([tableView isEqual:self.directionsTableView]){
        size = [[NSString stringWithFormat:@"%u. %@", indexPath.row + 1, [self.directions objectAtIndex:indexPath.row]] sizeWithFont:[UIFont systemFontOfSize:15.0f] constrainedToSize:CGSizeMake(150.0f, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
        NSInteger lines = round(size.height / 15);
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
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
        cell.textLabel.numberOfLines = 0;
        return cell;
    } else if ([tableView isEqual:self.commentsTableView]) {
        static NSString *CellIdentifier = @"CommentCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CommentCell"];
        }
        
        NSDictionary *userAndComment = [self.comments objectAtIndex:indexPath.row];
        FBProfilePictureView *fbProfilePictureView = (FBProfilePictureView *)[cell viewWithTag:1];
        UIImageView *profilePictureView = (UIImageView *)[cell viewWithTag:2];
        if ([[NSString stringWithFormat:@"%@", [userAndComment objectForKey:@"provider"]] isEqualToString:@"facebook"]) {
            profilePictureView.hidden = YES;
            fbProfilePictureView.hidden = NO;
            fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [userAndComment objectForKey:@"uid"]];
        } else {
            fbProfilePictureView.hidden = YES;
            profilePictureView.hidden = NO;
            [profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/%@", [self s3BucketURL], [userAndComment objectForKey:@"user_id"], [userAndComment objectForKey:@"profile_picture"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture"]];
        }
        
        UIButton *nameButton = (UIButton *)[cell viewWithTag:3];
        [nameButton setTitle:[NSString stringWithFormat:@"%@ %@", [userAndComment objectForKey:@"first_name"], [userAndComment objectForKey:@"last_name"]] forState:UIControlStateNormal];
        [nameButton sizeToFit];
        
        UITextView *textView = (UITextView *)[cell viewWithTag:4];
        textView.text = [NSString stringWithFormat:@"%@", [userAndComment objectForKey:@"text"]];
        
        CGSize constraintSize = CGSizeMake(280, MAXFLOAT);
        
        CGSize textSize = [textView.text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
        textView.frame = CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, textSize.height + 6);
        
        UILabel *timeLabel = (UILabel *)[cell viewWithTag:5];
        timeLabel.text = [FrecipeFunctions compareWithCurrentDate:[userAndComment objectForKey:@"created_at"]];
        
        [timeLabel sizeToFit];
        UIButton *deleteButton = (UIButton *)[cell viewWithTag:6];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *userId = [NSString stringWithFormat:@"%@", [defaults objectForKey:@"id"]];
        if (![userId isEqualToString:[NSString stringWithFormat:@"%@", [userAndComment objectForKey:@"user_id"]]]) {
            deleteButton.hidden = YES;
        } else {
            deleteButton.hidden = NO;
            deleteButton.frame = CGRectMake(timeLabel.frame.origin.x + timeLabel.frame.size.width - 5, deleteButton.frame.origin.y, deleteButton.frame.size.width, deleteButton.frame.size.height);
        }
        textView.font = [UIFont systemFontOfSize:13];
        
        
        
        // color
        NSString *commentId = [NSString stringWithFormat:@"%@", [userAndComment objectForKey:@"comment_id"]];

        if ([commentId isEqualToString:self.commentId]) {
            
            self.selectedCommentIndexPath = indexPath;
            cell.contentView.backgroundColor = [UIColor yellowColor];
            [UIView animateWithDuration:2.0 animations:^{
                cell.contentView.backgroundColor = [UIColor clearColor];
            }];
            self.commentId = nil;
        }
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
        [self.editDeletePopoverViewController dismissPopoverAnimated:NO];
        if (indexPath.row == 0) {
            [self goToEditRecipe];
        } else {
            [self deleteRecipe];
        }
    }
}

// table view delegate methods

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
}


// collection view dataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.masteredImages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PictureCell" forIndexPath:indexPath];
    
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    NSDictionary *masteredImage = [self.masteredImages objectAtIndex:indexPath.row];
    
    if ([masteredImage objectForKey:@"original"]) {
//        [imageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [[masteredImage objectForKey:@"url"]] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"]];
        [imageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/recipes/%@/%@", [self s3BucketURL], [masteredImage objectForKey:@"id"], [masteredImage objectForKey:@"picture_file_name"]]] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"]];
    } else {
        [imageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/recipe_images/%@/%@", [self s3BucketURL], [masteredImage objectForKey:@"id"], [masteredImage objectForKey:@"picture_file_name"]]] placeholderImage:[UIImage imageNamed:@"default_recipe_picture.png"]];
    }
    
    return cell;
}
// keybaord notification

- (void)keyboardWillBeShown:(NSNotification *)notification {
    self.originalHeight = self.commentsTableView.frame.size.height;
    
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    
    [UIView animateWithDuration:0.3 animations:^{
        self.commentsTableView.frame = CGRectMake(self.commentsTableView.frame.origin.x, self.commentsTableView.frame.origin.y, self.commentsTableView.frame.size.width, self.commentsTableView.frame.size.height - (keyboardSize.height - self.view.frame.size.height + self.commentsTableView.frame.origin.y + self.commentsTableView.frame.size.height) - 40);
        
        self.commentField.frame = CGRectMake(self.commentField.frame.origin.x, self.commentField.frame.origin.y - keyboardSize.height + 40, self.commentField.frame.size.width, self.commentField.frame.size.height);
        
        self.commentSubmitButton.frame = CGRectMake(self.commentSubmitButton.frame.origin.x, self.commentSubmitButton.frame.origin.y - keyboardSize.height + 40, self.commentSubmitButton.frame.size.width, self.commentSubmitButton.frame.size.height);
        if (self.comments.count > 0) {
            
            [self.commentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.comments.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.commentsTableView.frame = CGRectMake(self.commentsTableView.frame.origin.x, self.commentsTableView.frame.origin.y, self.commentsTableView.frame.size.width, self.originalHeight);
    
//    [UIView animateWithDuration:0.5 animations:^{
//        
//    } completion:^(BOOL finished) {
//        
//    }];
    self.commentField.frame = CGRectMake(self.commentField.frame.origin.x, self.commentField.frame.origin.y + keyboardSize.height - 40, self.commentField.frame.size.width, self.commentField.frame.size.height);
    
    self.commentSubmitButton.frame = CGRectMake(self.commentSubmitButton.frame.origin.x, self.commentSubmitButton.frame.origin.y + keyboardSize.height - 40, self.commentSubmitButton.frame.size.width, self.commentSubmitButton.frame.size.height);
}

@end
