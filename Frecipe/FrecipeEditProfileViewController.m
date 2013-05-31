//
//  FrecipeEditProfileViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 24..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeEditProfileViewController.h"
#import "FrecipeAPIClient.h"

@interface FrecipeEditProfileViewController () <UITextFieldDelegate, UITextViewDelegate>

@property (strong, nonatomic) UITextField *currentField;

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
    
    if ([[NSString stringWithFormat:@"%@", [self.user objectForKey:@"provider"]] isEqualToString:@"facebook"]) {
        self.fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [self.user objectForKey:@"uid"]];
        self.profilePictureView.hidden = YES;
        
    } else {
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
    NSString *path = @"tokens/update";
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSString *authentication_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"first_name", @"last_name", @"website", @"about", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.firstNameField.text, self.lastNameField.text, self.websiteField.text, self.aboutTextView.text, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"PUT" path:path parameters:parameters];
    NSLog(@"%@", parameters);
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [self saveUserInfo:[JSON objectForKey:@"user"] Token:nil ProfilePicture:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Profile Update Error" message:@"There was an error updating your profile." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
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

- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)dismissKeyboard {
    [self.currentField resignFirstResponder];
    [self.websiteField resignFirstResponder];
    [self.aboutTextView resignFirstResponder];
}

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
