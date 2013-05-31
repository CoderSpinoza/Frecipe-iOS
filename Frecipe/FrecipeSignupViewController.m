//
//  FrecipeSignupViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeSignupViewController.h"
#import "FrecipeAPIClient.h"
#import "FrecipeAppDelegate.h"

@interface FrecipeSignupViewController () <UITextFieldDelegate>

@property (strong, nonatomic) UITextField *currentField;

@end

@implementation FrecipeSignupViewController

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
    self.emailField.delegate = self;
    self.firstNameField.delegate = self;
    self.lastNameField.delegate = self;
    self.passwordField.delegate = self;
    self.confirmationField.delegate = self;
    self.scrollView.contentSize = self.scrollView.frame.size;
    [self addGestureRecognizer];
    [self registerForKeyboardNotifications];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
//    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    
}

- (IBAction)useYourFacebookInfoButtonPressed {
    if (!FBSession.activeSession.isOpen) {
        NSArray *permissions = [[NSArray alloc] initWithObjects:
                                @"email",
                                nil];
        [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                if (!error) {
                    self.uid = [NSString stringWithFormat:@"%@", user.id];
                    self.emailField.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"email"]];
                    self.firstNameField.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"first_name"]];
                    self.lastNameField.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"last_name"]];
                } else {
                    NSLog(@"error TT");
                }
                
            }];

        }];
    } else {
        [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
            if (!error) {
                self.uid = [NSString stringWithFormat:@"%@", user.id];
                self.emailField.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"email"]];
                self.firstNameField.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"first_name"]];
                self.lastNameField.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"last_name"]];
            } else {
                NSLog(@"error TT");
            }
            
        }];

    }
}

- (IBAction)signupButtonPressed {
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSString *path = @"users";
    
    NSArray *keys;
    NSArray *values;
    if (self.uid) {
        keys = [NSArray arrayWithObjects:@"email", @"first_name", @"last_name", @"password", @"password_confirmation", @"uid", @"provider", nil];
        values = [NSArray arrayWithObjects:self.emailField.text, self.firstNameField.text, self.lastNameField.text, self.passwordField.text, self.confirmationField.text, self.uid, @"facebook", nil];
    } else {
        keys = [NSArray arrayWithObjects:@"email", @"first_name", @"last_name", @"password", @"password_confirmation", nil];
        values = [NSArray arrayWithObjects:self.emailField.text, self.firstNameField.text, self.lastNameField.text, self.passwordField.text, self.confirmationField.text, nil];
    }
    
    NSDictionary *user = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:user forKey:@"user"];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    [client setParameterEncoding:AFJSONParameterEncoding];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        
        NSString *message = [JSON objectAtIndex:0];
        
        if ([message isEqualToString:@"success"]) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[JSON objectAtIndex:2] forKey:@"authentication_token"];
            [defaults setObject:[[JSON objectAtIndex:1] objectForKey:@"id"] forKey:@"id"];
            [defaults setObject:[[JSON objectAtIndex:1] objectForKey:@"provider"] forKey:@"provider"];
            
            [defaults setObject:[NSString stringWithFormat:@"%@ %@", [[JSON objectAtIndex:1] objectForKey:@"first_name"], [[JSON objectAtIndex:1] objectForKey:@"last_name"]] forKey:@"name"];
            
            NSString *profilePictureUrl;
        
            profilePictureUrl = [NSString stringWithFormat:@"%@", [JSON objectAtIndex:3]];

            [defaults setObject:profilePictureUrl forKey:@"profile_picture"];
            [defaults synchronize];
            
            [self saveUserInfo:[JSON objectAtIndex:1] Token:nil ProfilePicture:nil];
            FrecipeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            [UIView transitionWithView:delegate.window duration:0.7 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                delegate.window.rootViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Initial"];
            } completion:nil];
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"There was an error processing your signup request" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            [alertView show];
        }
        
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"There was an error processing your signup request." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}

- (void)addGestureRecognizer {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)dismissKeyboard {
    [self.currentField resignFirstResponder];
}

// text field delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentField = textField;
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

// keyboard notification registration
- (void)keyboardWillBeShown:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height - keyboardSize.height);
    [self.scrollView scrollRectToVisible:CGRectMake(self.currentField.frame.origin.x, self.currentField.frame.origin.y, self.currentField.frame.size.width, self.currentField.frame.size.height + 20) animated:YES];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height + keyboardSize.height);
}


@end
