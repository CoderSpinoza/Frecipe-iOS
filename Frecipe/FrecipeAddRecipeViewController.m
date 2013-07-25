//
//  FrecipeAddRecipeViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeAddRecipeViewController.h"
#import "FrecipeAPIClient.h"

@interface FrecipeAddRecipeViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate> {
    BOOL userHasUploadedRecipePhoto;
}

@property (strong, nonatomic) UITextField *currentField;
@property (strong, nonatomic) NSArray *allIngredients;

@end

@implementation FrecipeAddRecipeViewController

@synthesize ingredients = _ingredients;
@synthesize directions = _directions;
@synthesize recipeId = _recipeId;

- (NSString *)recipeId {
    if (_recipeId == nil) {
        _recipeId = @"0";
    }
    return _recipeId;
}
- (NSMutableArray *)ingredients {
    if (_ingredients == nil) {
        _ingredients = [[NSMutableArray alloc] init];
    }
    return _ingredients;
}

- (NSMutableArray *)directions {
    if (_directions == nil) {
        _directions = [[NSMutableArray alloc] init];
    }
    return _directions;
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
    self.recipeNameField.delegate = self;
    self.ingredientField.delegate = self;
    self.directionField.delegate = self;
    
    self.ingredientField.autoCompleteTableCellBackgroundColor = [UIColor whiteColor];
    self.ingredientField.autoCompleteDataSource = self;
    self.ingredientField.autoCompleteTableView.userInteractionEnabled = YES;
    self.ingredientField.autoCompleteDelegate = self;
    self.ingredientsTableView.dataSource = self;
    self.ingredientsTableView.delegate = self;
    
    self.directionsTableView.dataSource = self;
    self.directionsTableView.delegate = self;

//    [self addGestureRecognizers];
    [self registerForKeyboardNotifications];
    [self fetchAllIngredients];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchAllIngredients {
    NSString *path = @"ingredients.json";
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:nil];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.allIngredients = [NSMutableArray arrayWithArray:JSON];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)segmentedControlPressed:(UISegmentedControl *)sender {
    
    if (self.ingredientField.autoCompleteTableViewHidden == NO) {
        [self.ingredientField resignFirstResponder];
    }
    if (sender.selectedSegmentIndex == 0) {
        self.recipeNameField.hidden = NO;
        self.recipeImageButton.hidden = NO;
        self.ingredientField.hidden = YES;
        self.ingredientsTableView.hidden = YES;
        self.directionField.hidden = YES;
        self.directionsTableView.hidden = YES;
    } else if (sender.selectedSegmentIndex == 1) {
        self.recipeNameField.hidden = YES;
        self.recipeImageButton.hidden = YES;
        self.ingredientField.hidden = NO;
        self.ingredientsTableView.hidden = NO;
        self.directionField.hidden = YES;
        self.directionsTableView.hidden = YES;
    } else if (sender.selectedSegmentIndex == 2) {
        self.recipeNameField.hidden = YES;
        self.recipeImageButton.hidden = YES;
        self.ingredientField.hidden = YES;
        self.ingredientsTableView.hidden = YES;
        self.directionField.hidden = NO;
        self.directionsTableView.hidden = NO;
    }
}


- (IBAction)addButtonPressed:(UIBarButtonItem *)sender {
    NSString *path;
    NSString *method;
    if ([self.editing isEqualToString:@"1"]) {
        path = [NSString stringWithFormat:@"recipes/%@", self.recipeId];
        method = @"PUT";
        userHasUploadedRecipePhoto = YES;
    } else {
        path = @"/recipes";
        method = @"POST";
    }
    if (self.ingredients.count > 0 && userHasUploadedRecipePhoto) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
        
        NSString *ingredients = [self.ingredients componentsJoinedByString:@","];
        NSString *directions = [self.directions componentsJoinedByString:@"\n"];
        NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"recipe_name", @"ingredients", @"steps", @"recipe_id", nil];
        NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeNameField.text, ingredients, directions, self.recipeId, nil];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        
        FrecipeAPIClient *client = [FrecipeAPIClient client];
        NSMutableURLRequest *request = [client multipartFormRequestWithMethod:method path:path parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:UIImageJPEGRepresentation(self.recipeImageButton.imageView.image, 0.9) name:@"recipe_image" fileName:@"recipe_image.jpg" mimeType:@"image/jpeg"];
        }];
        
        // add a spinning view
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        UIView *blockingView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 20, self.view.frame.size.width, self.view.frame.size.height)];
        blockingView.backgroundColor = [UIColor blackColor];
        blockingView.alpha = 0.5;
        [blockingView addSubview:spinner];
        [self.view addSubview:blockingView];
        [spinner startAnimating];
        
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
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Recipe Upload Error" message:@"You should upload image and ingredients" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }
}

- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    
//    UITapGestureRecognizer *tapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboardForIngredientsTableView)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
//    [self.ingredientsTableView addGestureRecognizer:tapGestureRecognizer2];
//    [self.directionsTableView addGestureRecognizer:tapGestureRecognizer2];
}

- (void)dismissKeyboard {
    [self.currentField resignFirstResponder];
}

- (void)dismissKeyboardForIngredientsTableView {
    [self.ingredientField resignFirstResponder];
}

- (IBAction)showImagePickerActionSheet {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"How to upload photo?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Photo Library", nil];
    [actionSheet showInView:self.view];
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

// text field delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentField = textField;
    return YES;
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.recipeNameField]) {
        [textField resignFirstResponder];
        textField.text = [textField.text capitalizedString];
    } else if ([textField isEqual:self.ingredientField]) {
        if (![textField.text isEqualToString:@""]) {
            [self.ingredients addObject:[textField.text capitalizedString]];
            textField.text = @"";
            [self.ingredientsTableView reloadData];
            if (self.ingredients.count > 0) {
                [self.ingredientsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.ingredients.count - 1  inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        } else {
            [textField resignFirstResponder];
        }
    } else if ([textField isEqual:self.directionField]) {
        if (![textField.text isEqualToString:@""]) {
            [self.directions addObject:textField.text];
            textField.text = @"";
            [self.directionsTableView reloadData];
            if (self.directions.count > 0) {
                [self.directionsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.directions.count - 1  inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
            
        } else {
            [textField resignFirstResponder];
        }
    }
    return YES;
}

// action sheet delegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self openRecipeImagePicker:@"camera"];
    } else if (buttonIndex == 1) {
        [self openRecipeImagePicker:@"library"];
    }
    
}

// image picker delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if ([picker.restorationIdentifier isEqualToString:@"recipeImage"]) {
        [self.recipeImageButton setImage:[info valueForKey:UIImagePickerControllerEditedImage] forState:UIControlStateNormal];
        userHasUploadedRecipePhoto = YES;
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

// table view delegate and dataSource Methods
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([tableView isEqual:self.ingredientsTableView]) {
            [self.ingredients removeObjectAtIndex:indexPath.row];
            [self.ingredientsTableView reloadData];
        } else {
            [self.directions removeObjectAtIndex:indexPath.row];
            [self.directionsTableView reloadData];
        }
    }
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
        
    } else {
        return self.directions.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size;
    if ([tableView isEqual:self.ingredientsTableView]) {
        size = [[NSString stringWithFormat:@"%u. %@", indexPath.row + 1, [self.ingredients objectAtIndex:indexPath.row]] sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:CGSizeMake(320.0f, 9999.0f) lineBreakMode:NSLineBreakByCharWrapping];
    } else {
        size = [[NSString stringWithFormat:@"%u. %@", indexPath.row + 1, [self.directions objectAtIndex:indexPath.row]] sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:CGSizeMake(200.0f, 9999.0f) lineBreakMode:NSLineBreakByWordWrapping];
    }
    NSInteger lines = round(size.height / 18);
    if (lines < 2) {
        return 44;
    } else {
        return size.height + 16;
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
        cell.textLabel.text = [NSString stringWithFormat:@"%u. %@", indexPath.row + 1, [self.ingredients objectAtIndex:indexPath.row]];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
        return cell;
    } else {
        static NSString *CellIdentifier = @"DirectionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DirectionCell"];
        }
        
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.numberOfLines = 0;
        
        cell.textLabel.text = [NSString stringWithFormat:@"%u. %@", indexPath.row + 1, [self.directions objectAtIndex:indexPath.row]];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
        
        // attach a long press gesture recognizer
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [cell addGestureRecognizer:longPressGestureRecognizer];
        
        return cell;
        
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.directionsTableView]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if ([tableView isEqual:self.directionsTableView]) {
        NSString *source = [self.directions objectAtIndex:sourceIndexPath.row];
        [self.directions removeObjectAtIndex:sourceIndexPath.row];
        [self.directions insertObject:source atIndex:destinationIndexPath.row];
        [self.directionsTableView reloadData];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (self.directionsTableView.editing) {
            NSLog(@"quit");
            [self.directionsTableView setEditing:NO animated:YES];
        } else {
            NSLog(@"edit");
            [self.directionsTableView setEditing:YES animated:YES];
        }
    }
}

// MLPAutoCompleteTextField dataSource and delegate methods

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField possibleCompletionsForString:(NSString *)string completionHandler:(void (^)(NSArray *))handler {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        handler(self.allIngredients);
    });
}

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField didSelectAutoCompleteString:(NSString *)selectedString withAutoCompleteObject:(id<MLPAutoCompletionObject>)selectedObject forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.ingredients addObject:[selectedString capitalizedString]];
    self.ingredientField.text = @"";
    [self.ingredientsTableView reloadData];
    [self.ingredientField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.1f];
}

// keyboard notification

- (void)keyboardWillBeShown:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
        CGFloat difference;
        if (![self isTall]) {
            difference = 180;
        } else {
            difference = self.view.frame.size.height - self.recipeImageButton.frame.origin.y - self.recipeImageButton.frame.size.height - 44;
        }
        
        self.recipeImageButton.frame = CGRectMake(self.recipeImageButton.frame.origin.x + difference / 2, self.recipeImageButton.frame.origin.y, self.recipeImageButton.frame.size.width - difference, self.recipeImageButton.frame.size.height - difference);
        
        self.recipeImageButton.titleEdgeInsets = UIEdgeInsetsMake(10, 0, 0, 0);
        
        self.ingredientsTableView.frame = CGRectMake(self.ingredientsTableView.frame.origin.x, self.ingredientsTableView.frame.origin.y, self.ingredientsTableView.frame.size.width, self.ingredientsTableView.frame.size.height - (keyboardSize.height - self.view.frame.size.height + self.ingredientsTableView.frame.origin.y + self.ingredientsTableView.frame.size.height));
        
        if (self.ingredients.count > 0) {
            [self.ingredientsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.ingredients.count - 1  inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        
        self.directionsTableView.frame = CGRectMake(self.directionsTableView.frame.origin.x, self.directionsTableView.frame.origin.y, self.directionsTableView.frame.size.width, self.directionsTableView.frame.size.height - (keyboardSize.height - self.view.frame.size.height + self.directionsTableView.frame.origin.y + self.directionsTableView.frame.size.height));
        
        if (self.directions.count > 0) {
            [self.directionsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.directions.count - 1  inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    } completion:nil];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.recipeImageButton.frame = CGRectMake(20, 135, 280, 280);
    } completion:^(BOOL finished) {
    }];
    self.ingredientsTableView.frame = CGRectMake(self.ingredientsTableView.frame.origin.x, self.ingredientsTableView.frame.origin.y, self.ingredientsTableView.frame.size.width, 280);
    self.directionsTableView.frame = CGRectMake(self.directionsTableView.frame.origin.x, self.directionsTableView.frame.origin.y, self.directionsTableView.frame.size.width, 280);
    self.recipeImageButton.titleEdgeInsets = UIEdgeInsetsMake(40, 0, 0, 0);

}

@end
