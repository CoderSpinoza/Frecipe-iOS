//
//  FrecipeLoginViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeLoginViewController.h"
#import "FrecipeAPIClient.h"
#import "FrecipeAppDelegate.h"
#import "FrecipeSignupViewController.h"
#import "FrecipeSpinnerView.h"
#import <QuartzCore/QuartzCore.h>

@interface FrecipeLoginViewController () <UITextFieldDelegate>

@property (strong, nonatomic) UITextField *currentField;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *uid;
@end

@implementation FrecipeLoginViewController

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
    self.passwordField.delegate = self;
    
    self.emailField.layer.cornerRadius = 5.0f;
    self.passwordField.layer.cornerRadius = 5.0f;
    self.emailField.clipsToBounds = YES;
    self.passwordField.clipsToBounds = YES;
    
    self.trackedViewName = @"Login";
    [self addGestureRecognizers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.emailField.text = @"";
    self.passwordField.text = @"";
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed {
    [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Authentication" withAction:@"Login" withLabel:@"Login" withValue:[NSNumber numberWithInt:1]];
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSString *path = @"tokens";
    NSArray *keys = [NSArray arrayWithObjects:@"email", @"password",  nil];
    NSArray *values = [NSArray arrayWithObjects:self.emailField.text, self.passwordField.text, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    [self dismissKeyboard];
    FrecipeSpinnerView *spinnerView = [[FrecipeSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    spinnerView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [spinnerView.spinner startAnimating];
    [self.view addSubview:spinnerView];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        // save retrieved user data
        [self saveUserInfo:[JSON objectForKey:@"user"] Token:[JSON objectForKey:@"token"] ProfilePicture:[NSString stringWithFormat:@"%@", [JSON objectForKey:@"profile_picture"]]];
        
        [self performSegueWithIdentifier:@"Login" sender:self];
        
        [spinnerView removeFromSuperview];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [spinnerView removeFromSuperview];
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[JSON objectForKey:@"message"] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [errorView show];
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}
- (IBAction)loginWithFacebookButtonPressed {
    [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"Authentication" withAction:@"Login with Facebook" withLabel:@"Login with Facebook" withValue:[NSNumber numberWithInt:1]];
    
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"email",
                            @"user_likes",
                            nil];
    [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        FrecipeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        
        [delegate sessionStateChanged:session State:status Error:error];
        
        if (FBSession.activeSession.isOpen) {
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                if (!error) {
                    [self checkIfFacebookUserIsRegisteredWithId:user.id Email:[user objectForKey:@"email"] FirstName:user.first_name LastName:user.last_name];
                } else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Facebook Login Error" message:@"There was an error signing in with your facebook account." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                    [alertView show];
                }
                
            }];
        }
    }];
}

- (void)checkIfFacebookUserIsRegisteredWithId:(NSString *)uid Email:(NSString *)email FirstName:(NSString *)firstName LastName:(NSString *)lastName {
    NSString *path = @"/tokens/facebook_check";
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSArray *keys = [NSArray arrayWithObjects:@"email", @"uid", nil];
    NSArray *values = [NSArray arrayWithObjects:email, uid, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    
    FrecipeSpinnerView *spinnerView = [[FrecipeSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    spinnerView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [spinnerView.spinner startAnimating];
    [self.view addSubview:spinnerView];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSString *message = [JSON objectForKey:@"message"];
        if ([message isEqualToString:@"needs signup"]) {
            [spinnerView removeFromSuperview];
            self.email = email;
            self.firstName = firstName;
            self.lastName = lastName;
            self.uid = uid;
            [self performSegueWithIdentifier:@"Signup" sender:self];
            
        } else {
            NSString *profilePictureUrl;
            profilePictureUrl = [NSString stringWithFormat:@"%@",[JSON objectForKey:@"profile_picture"]];
            
            [self saveUserInfo:[JSON objectForKey:@"user"] Token:[JSON objectForKey:@"token"] ProfilePicture:profilePictureUrl];

            [spinnerView removeFromSuperview];
            [self performSegueWithIdentifier:@"Login" sender:self];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [spinnerView removeFromSuperview];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"There was an error processing your login request." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Signup"]) {
        FrecipeSignupViewController *signupViewController = (FrecipeSignupViewController *)segue.destinationViewController;
        if (signupViewController.view) {
            if (self.email) {                
                signupViewController.emailField.text = self.email;
                signupViewController.firstNameField.text = self.firstName;
                signupViewController.lastNameField.text = self.lastName;
                signupViewController.uid = self.uid;
                
                self.email = nil;
                self.firstName = nil;
                self.lastName = nil;
            }
        }
    }
}

// gesture recognizers
- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

// text delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentField = textField;
    
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    [self.scrollView scrollRectToVisible:textField.frame animated:YES];
    
    
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)dismissKeyboard {
    [self.currentField resignFirstResponder];
}

@end
