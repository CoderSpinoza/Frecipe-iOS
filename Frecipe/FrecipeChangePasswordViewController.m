//
//  FrecipeChangePasswordViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 31..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeChangePasswordViewController.h"
#import "FrecipeAPIClient.h"

@interface FrecipeChangePasswordViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UITextField *currentField;

@end

@implementation FrecipeChangePasswordViewController

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
    self.currentPasswordField.delegate = self;
    self.differentPasswordField.delegate = self;
    self.passwordConfirmationField.delegate = self;
    
    [self addGestureRecognizers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    
    if (![self checkPasswordLength]) {
        self.errorLabel.text = @"Password should be longer than 6 letters.";
        return;
    }
    
    if (![self.differentPasswordField.text isEqualToString:self.passwordConfirmationField.text]) {
        self.errorLabel.text = @"Password and confirmation should match.";
        return;
    }
    
    NSString *path = @"tokens/password";
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"current_password", @"new_password", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.currentPasswordField.text, self.differentPasswordField.text, nil];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        NSString *message;
        if (response.statusCode == 404) {
            message = @"The password you typed was not correct.";
        } else {
            message = @"There was an error updating your password.";
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password Update Error" message:message delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        self.errorLabel.text = message;
//        [alertView show];
    }];
    [operation start];
}

- (BOOL)checkPasswordLength {
    return self.currentPasswordField.text.length > 6 && self.differentPasswordField.text.length > 6 && self.passwordConfirmationField.text.length > 6;
}

- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizers = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizers];
}

- (void)dismissKeyboard {
    [self.currentField resignFirstResponder];
}
// text field delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentField = textField;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if (![self checkPasswordLength]) {
        self.errorLabel.text = @"Password should be longer than 6 letters.";
    } else {
        self.errorLabel.text = @"";
    }
    return YES;
}


@end
