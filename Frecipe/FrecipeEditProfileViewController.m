//
//  FrecipeEditProfileViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 24..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeEditProfileViewController.h"
#import "FrecipeAPIClient.h"
#import "ECSlidingViewController.h"

@interface FrecipeEditProfileViewController () <UITextFieldDelegate, UITextViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UITextField *currentField;
@property (strong, nonatomic) UIImage *image;

@end

@implementation FrecipeEditProfileViewController

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
    self.user = [self loaduserInfo];
    self.trackedViewName = @"Edit Profile";
//
    if ([[NSString stringWithFormat:@"%@", [self.user objectForKey:@"provider"]] isEqualToString:@"facebook"]) {
        self.profilePictureView.hidden = YES;
        self.editLabel.hidden = YES;
        
    } else {
        self.profilePictureView.hidden = NO;
        self.profilePictureView.alpha = 1;
        self.fbProfilePictureView.hidden = YES;
    }
    
    self.firstNameField.text = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"first_name"]];
    self.lastNameField.text = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"last_name"]];
    
    self.websiteField.text = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"website"]];
    self.aboutTextView.text = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"about"]];
    // setting borders
    
    self.basicInfoView.layer.cornerRadius = 5.0f;
    self.userAboutView.layer.cornerRadius = 5.0f;
    self.websiteView.layer.cornerRadius = 5.0f;
    [self.basicInfoView setBasicShadow];
    [self.websiteView setBasicShadow];
    [self.userAboutView setBasicShadow];
    
    self.aboutTextView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.aboutTextView.layer.borderWidth = 1.0f;
    self.aboutTextView.layer.cornerRadius = 5.0f;
    
    self.firstNameField.delegate = self;
    self.lastNameField.delegate = self;
    self.aboutTextView.delegate = self;
    
    self.scrollView.contentSize = self.scrollView.frame.size;
    [self addGestureRecognizers];
    [self registerForKeyboardNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Profile" withAction:@"Edit" withLabel:@"Edit" withValue:[NSNumber numberWithInt:1]];
    
    NSString *path = @"tokens/update";
    
    NSString *authentication_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"first_name", @"last_name", @"website", @"about", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.firstNameField.text, self.lastNameField.text, self.websiteField.text, self.aboutTextView.text, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    FrecipeAPIClient *client = [FrecipeAPIClient client];
//    NSURLRequest *request = [client requestWithMethod:@"PUT" path:path parameters:parameters];
    
    NSMutableURLRequest *request = [client multipartFormRequestWithMethod:@"PUT" path:path parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if (self.image) {
             [formData appendPartWithFileData:UIImageJPEGRepresentation(self.image, 0.9) name:@"image" fileName:@"profile_picture.jpg" mimeType:@"image/jpeg"];
        }
    }];
    
    // button handling
    UIView *blockingView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 20, self.view.frame.size.width, self.view.frame.size.height)];
    blockingView.backgroundColor = [UIColor clearColor];
    FrecipeSpinnerView *spinnerView = [[FrecipeSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    spinnerView.center = blockingView.center;
    [spinnerView.spinner startAnimating];
    spinnerView.label.text = @"Updating";
    [blockingView addSubview:spinnerView];
    [self.view addSubview:blockingView];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [self saveUserInfo:[JSON objectForKey:@"user"] Token:nil ProfilePicture:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"profile_picture"]]];
        
        NSLog(@"%@", self.slidingViewController.underLeftViewController);
        [blockingView removeFromSuperview];
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Profile Update Error" message:@"There was an error updating your profile." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
        [blockingView removeFromSuperview];
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    UITapGestureRecognizer *profilePictureTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openProfilePictureActionSheet)];
    self.profilePictureView.userInteractionEnabled = YES;
    [self.profilePictureView addGestureRecognizer:profilePictureTapGestureRecognizer];
}

- (void)dismissKeyboard {
    [self.currentField resignFirstResponder];
    [self.websiteField resignFirstResponder];
    [self.aboutTextView resignFirstResponder];
}

- (void)openProfilePictureActionSheet {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"How to upload profile picture?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Photo Library", nil];
    [actionSheet showInView:self.view];
}

// text field delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentField = textField;
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.currentField resignFirstResponder];
    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return YES;
}


// action sheet delegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self openRecipeImagePicker:@"camera"];
    } else if (buttonIndex == 1){
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
    imagePickerController.restorationIdentifier = @"profilePicture";
    imagePickerController.allowsEditing = YES;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

// image picker delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if ([picker.restorationIdentifier isEqualToString:@"profilePicture"]) {
        UIImage *image = [info valueForKey:UIImagePickerControllerEditedImage];
        self.image = image;
        self.profilePictureView.image = image;
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

//keyboard registration

- (void)keyboardWillBeShown:(NSNotification *)notification {
    
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height - keyboardSize.height);
    if (self.aboutTextView.isFirstResponder) {
        [self.scrollView scrollRectToVisible:CGRectMake(self.aboutTextView.frame.origin.x, self.userAboutView.frame.origin.y + 120, self.aboutTextView.frame.size.width, self.aboutTextView.frame.size.height) animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height + keyboardSize.height);
}

@end
