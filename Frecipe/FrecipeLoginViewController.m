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
    [self addGestureRecognizers];
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
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSString *path = @"tokens";
    NSArray *keys = [NSArray arrayWithObjects:@"email", @"password",  nil];
    NSArray *values = [NSArray arrayWithObjects:self.emailField.text, self.passwordField.text, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        
        // save retrieved user data
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[JSON objectForKey:@"token"] forKey:@"authentication_token"];
        [defaults setObject:[[JSON objectForKey:@"user"] objectForKey:@"id"] forKey:@"id"];
        
        if ([[NSString stringWithFormat:@"%@", [[JSON objectForKey:@"user"] objectForKey:@"provider"]] isEqualToString:@"facebook"]) {
            [defaults setObject:[[JSON objectForKey:@"user"] objectForKey:@"provider"] forKey:@"provider"];
            [defaults setObject:[[JSON objectForKey:@"user"] objectForKey:@"uid"] forKey:@"uid"];
        }
        
        [defaults setObject:[NSString stringWithFormat:@"%@ %@", [[JSON objectForKey:@"user"] objectForKey:@"first_name"], [[JSON objectForKey:@"user"] objectForKey:@"last_name"]] forKey:@"name"];
        
        NSString *profilePictureUrl = [NSString stringWithFormat:@"%@",[JSON objectForKey:@"profile_picture"]];
        
        [defaults setObject:profilePictureUrl forKey:@"profile_picture"];
        
        [defaults synchronize];
        
        [self performSegueWithIdentifier:@"Login" sender:self];
        
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"LoginError" message:[JSON objectForKey:@"message"] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [errorView show];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}
- (IBAction)loginWithFacebookButtonPressed {
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
                    NSLog(@"error TT");
                }
                
            }];
        }
    }];
}

- (void)checkIfFacebookUserIsRegisteredWithId:(NSString *)uid Email:(NSString *)email FirstName:(NSString *)firstName LastName:(NSString *)lastName {
    NSString *path = @"tokens/facebook_check";
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    
    NSArray *keys = [NSArray arrayWithObjects:@"email", @"uid", nil];
    NSArray *values = [NSArray arrayWithObjects:email, uid, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    UIView *spinnerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    spinner.center = spinnerView.center;
    spinnerView.center = self.view.center;
    spinnerView.backgroundColor = [UIColor blackColor];
    
    [spinner startAnimating];
    [spinnerView addSubview:spinner];
    [self.view addSubview:spinnerView];
    
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSString *message = [JSON objectForKey:@"message"];
        if ([message isEqualToString:@"needs signup"]) {
            self.email = email;
            self.firstName = firstName;
            self.lastName = lastName;
            self.uid = uid;
            [self performSegueWithIdentifier:@"Signup" sender:self];
            
        } else {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[JSON objectForKey:@"token"] forKey:@"authentication_token"];
            
            [defaults setObject:[[JSON objectForKey:@"user"] objectForKey:@"id"] forKey:@"id"];
            [defaults setObject:[[JSON objectForKey:@"user"] objectForKey:@"provider"] forKey:@"provider"];
            [defaults setObject:[NSString stringWithFormat:@"%@ %@", [[JSON objectForKey:@"user"] objectForKey:@"first_name"], [[JSON objectForKey:@"user"] objectForKey:@"last_name"]] forKey:@"name"];
            
            NSString *profilePictureUrl;
            profilePictureUrl = [NSString stringWithFormat:@"%@",[JSON objectForKey:@"profile_picture"]];
            
            [defaults setObject:profilePictureUrl forKey:@"profile_picture"];
            
            [defaults setObject:uid forKey:@"uid"];
            [defaults synchronize];
            
            [spinnerView removeFromSuperview];
            [self performSegueWithIdentifier:@"Login" sender:self];
        }
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        [spinnerView removeFromSuperview];
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
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
