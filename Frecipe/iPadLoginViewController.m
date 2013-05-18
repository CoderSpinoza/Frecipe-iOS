//
//  iPadLoginViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 13..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "iPadLoginViewController.h"
#import "FrecipeAPIClient.h"
#import "FrecipeSignupViewController.h"

#import <FacebookSDK/FacebookSDK.h>

@interface iPadLoginViewController () <UITextFieldDelegate>

@property (strong, nonatomic) UITextField *currentField;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *uid;

@end

@implementation iPadLoginViewController

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
    
    self.view.autoresizesSubviews = YES;
    [self setupDelegations];
    [self addGestureRecognizers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self willAnimateRotationToInterfaceOrientation:self.interfaceOrientation duration:0.1];
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

- (void)setupDelegations {
    self.emailField.delegate = self;
    self.passwordField.delegate = self;
}

- (IBAction)loginButtonPressed {
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSString *path = @"tokens";
    NSArray *keys = [NSArray arrayWithObjects:@"email", @"password", nil];
    NSArray *values = [NSArray arrayWithObjects:self.emailField.text, self.passwordField.text, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSDictionary *user = [JSON objectForKey:@"user"];
        NSString *provider = [NSString stringWithFormat:@"%@", [user objectForKey:@"provider"]];
        if ([provider isEqualToString:@"facebook"]) {
            [defaults setObject:provider forKey:@"provider"];
            [defaults setObject:[NSString stringWithFormat:@"%@", [user objectForKey:@"uid"]] forKey:@"uid"];
        }
        [defaults setObject:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forKey:@"name"];
        
        NSString *profilePictureUrl = [NSString stringWithFormat:@"%@",[JSON objectForKey:@"profile_picture"]];
        [defaults setObject:profilePictureUrl forKey:@"profile_picture"];
        [defaults synchronize];
        
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        
        [self performSegueWithIdentifier:@"Login" sender:self];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"LoginError" message:[JSON objectForKey:@"message"] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [errorView show];
        
        NSLog(@"%@", error);
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];
    [operation start];
}

- (IBAction)loginWithFacebookButtonPressed {
}




// gesture recognizers
- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)dismissKeyboard {
    [self.currentField resignFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Login"]) {
        NSLog(@"login");
    }
}

// text delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentField = textField;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


// auto rotate
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSArray *views = [NSArray arrayWithObjects:self.frecipeLabel, self.emailField, self.passwordField, self.loginButton, self.loginWithFacebookButton, self.orLabel, self.signupButton, nil];
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        
        for (UIView *view in views) {
            view.frame = CGRectMake(self.view.center.y - view.frame.size.width / 2, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
        }
        
        
    } else {
        for (UIView *view in views) {
            view.frame = CGRectMake(self.view.center.x - view.frame.size.width / 2, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
        }
    }
}

@end
