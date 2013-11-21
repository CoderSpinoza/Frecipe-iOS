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
#import "FrecipeSpinnerView.h"

@interface FrecipeSignupViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UITextField *currentField;
@property (strong, nonatomic) FrecipeSpinnerView *spinnerView;
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
    
    self.screenName = @"Signup";
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

- (void)checkIfFacebookUserIsRegisteredWithId:(NSString *)uid Email:(NSString *)email FirstName:(NSString *)firstName LastName:(NSString *)lastName {
    NSString *path = @"/tokens/facebook_check";
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSArray *keys = [NSArray arrayWithObjects:@"email", @"uid", nil];
    NSArray *values = [NSArray arrayWithObjects:email, uid, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSString *message = [JSON objectForKey:@"message"];
        if ([message isEqualToString:@"needs signup"]) {
            self.uid = uid;
            self.emailField.text = email;
            self.firstNameField.text = firstName;
            self.lastNameField.text = lastName;
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You already signed up with this facebook account." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            [alertView show];
            [self.spinnerView removeFromSuperview];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"There was an error processing your login request." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}


- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
//    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    
}

- (IBAction)useYourFacebookInfoButtonPressed {
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Authentication" action:@"Connect with Facebook" label:@"Connect with Facebook" value:[NSNumber numberWithInt:1]] build]];
//    [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Authentication" withAction:@"Connect with Facebook" withLabel:@"Connect with Facebook" withValue:[NSNumber numberWithInt:1]];
    FrecipeSpinnerView *spinnerView = [[FrecipeSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    spinnerView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [spinnerView.spinner startAnimating];
    self.spinnerView = spinnerView;
    [self.view addSubview:self.spinnerView];
    if (!FBSession.activeSession.isOpen) {
        NSArray *permissions = [[NSArray alloc] initWithObjects:
                                @"email",
                                nil];
        
        
        [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                if (!error) {
//                    self.uid = [NSString stringWithFormat:@"%@", user.id];
//                    self.emailField.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"email"]];
//                    self.firstNameField.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"first_name"]];
//                    self.lastNameField.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"last_name"]];
                    [self checkIfFacebookUserIsRegisteredWithId:[NSString stringWithFormat:@"%@", user.id] Email:[NSString stringWithFormat:@"%@", [user objectForKey:@"email"]] FirstName:[NSString stringWithFormat:@"%@", [user objectForKey:@"first_name"]] LastName:[NSString stringWithFormat:@"%@", [user objectForKey:@"last_name"]]];
                } else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error fetching your facebook info." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                    [alertView show];
                }
                [self.spinnerView removeFromSuperview];
                
            }];
        }];
    } else {
        [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
            if (!error) {
                [self checkIfFacebookUserIsRegisteredWithId:[NSString stringWithFormat:@"%@", user.id] Email:[NSString stringWithFormat:@"%@", [user objectForKey:@"email"]] FirstName:[NSString stringWithFormat:@"%@", [user objectForKey:@"first_name"]] LastName:[NSString stringWithFormat:@"%@", [user objectForKey:@"last_name"]]];
                
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error fetching your facebook info." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                [alertView show];
            }
            [spinnerView removeFromSuperview];
        }];
    }
}

- (IBAction)signupButtonPressed:(id)sender {
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Authentication" action:@"Signup" label:@"Signup" value:[NSNumber numberWithInt:1]] build]];
//    [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Authentication" withAction:@"Signup" withLabel:@"Signup" withValue:[NSNumber numberWithInt:1]];
    if (![self.emailField.text isEmail]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Please enter a valid email address." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
        return;
    }
    
    if (self.firstNameField.text.length == 0 || self.lastNameField.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"First name or last name cannot be blank." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
        return;
    }
    
    if (![self.passwordField.text isEqualToString:self.confirmationField.text]) {
        NSLog(@"%u %@ %@", [self.emailField.text isEqualToString:self.confirmationField.text], self.emailField.text, self.confirmationField.text);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Passwords do not match." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
        return;
    }
    
    if (self.passwordField.text.length == 0 || self.confirmationField.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Passwords cannot be blank." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
        return;
    }
    
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
    
    FrecipeSpinnerView *spinnerView = [[FrecipeSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    spinnerView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [spinnerView.spinner startAnimating];
    [self.view addSubview:spinnerView];
    
    self.signupButton.enabled = NO;
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSString *message = [JSON objectForKey:@"message"];
        
        if ([message isEqualToString:@"success"]) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[JSON objectForKey:@"authentication_token"] forKey:@"authentication_token"];
            [defaults setObject:[[JSON objectForKey:@"user"] objectForKey:@"id"] forKey:@"id"];
            
            if ([[NSString stringWithFormat:@"%@", [[JSON objectForKey:@"user"] objectForKey:@"provider"]] isEqualToString:@"facebook"]) {
                [defaults setObject:[[JSON objectForKey:@"user"] objectForKey:@"provider"] forKey:@"provider"];
                [defaults setObject:[[JSON objectForKey:@"user"] objectForKey:@"uid"] forKey:@"uid"];
            }
            
            [defaults setObject:[NSString stringWithFormat:@"%@ %@", [[JSON objectForKey:@"user"] objectForKey:@"first_name"], [[JSON objectForKey:@"user"] objectForKey:@"last_name"]] forKey:@"name"];
            
            NSString *profilePictureUrl;
            
            profilePictureUrl = [NSString stringWithFormat:@"%@", [JSON objectForKey:@"profile_picture"]];
            
            [defaults setObject:profilePictureUrl forKey:@"profile_picture"];
            [defaults setObject:[[JSON objectForKey:@"user"] objectForKey:@"about"] forKey:@"about"];
            [defaults setObject:[[JSON objectForKey:@"user"] objectForKey:@"website"] forKey:@"website"];
            [defaults synchronize];
            
            [self saveUserInfo:[JSON objectForKey:@"user"] Token:nil ProfilePicture:nil];
            FrecipeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            [UIView transitionWithView:delegate.window duration:0.7 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
                BOOL oldState = [UIView areAnimationsEnabled];
                [UIView setAnimationsEnabled:NO];
                delegate.window.rootViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Initial"];
                [UIView setAnimationsEnabled:oldState];
            } completion:nil];
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Signup Error" message:[JSON objectForKey:@"message"] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            [alertView show];
        }
        
        [spinnerView removeFromSuperview];
        self.signupButton.enabled = YES;
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Signup Error" message:[JSON objectForKey:@"message"] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
        [spinnerView removeFromSuperview];
        self.signupButton.enabled = YES;
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
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

// alert view delegate methods
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    if ([alertView.title isEqualToString:@"Error"]) {
//        if (buttonIndex == 0) {
//            [self useYourFacebookInfoButtonPressed];
//        }
//    }
//}

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
