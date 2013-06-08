//
//  FrecipeForgotPasswordViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 31..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeForgotPasswordViewController.h"
#import "FrecipeAPIClient.h"

@interface FrecipeForgotPasswordViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@end

@implementation FrecipeForgotPasswordViewController

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
    [self addGestureRecognizers];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendButtonPressed:(UIBarButtonItem *)sender {
    if ([self validateEmail:self.emailField.text]) {
        NSString *path = @"tokens/reset";
        
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:self.emailField.text, @"email", nil];
        
        FrecipeAPIClient *client = [FrecipeAPIClient client];
        NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            UIAlertView *alertView;
            if (response.statusCode == 404) {
                alertView = [[UIAlertView alloc] initWithTitle:@"Email Error" message:@"There was no account associated with this email." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            } else {
                alertView = [[UIAlertView alloc] initWithTitle:@"Server Error" message:@"There was an error processing your request." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            }
            [alertView show];
        }];
        FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
        [queue addOperation:operation];
        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You have to input a valid email address!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }
}

- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
}

- (void)dismissKeyboard {
    [self.emailField resignFirstResponder];
}
// text field delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

// alert view delegate methods

- (void)alertViewCancel:(UIAlertView *)alertView {
    
}


@end
