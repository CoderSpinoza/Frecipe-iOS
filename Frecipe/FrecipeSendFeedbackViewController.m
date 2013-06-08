//
//  FrecipeSendFeedbackViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 6. 3..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeSendFeedbackViewController.h"
#import "FrecipeAPIClient.h"

@interface FrecipeSendFeedbackViewController () <UITextViewDelegate>

@end

@implementation FrecipeSendFeedbackViewController

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
    [self.feedbackTextView setShadowWithColor:[UIColor grayColor] Radius:3.0f Offset:CGSizeMake(0, 0) Opacity:0.75f];
    
    self.feedbackTextView.text = @"Your feedback here.";
    self.feedbackTextView.textColor = [UIColor lightGrayColor];
    self.feedbackTextView.delegate = self;
    
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
    
    if (self.feedbackTextView.text.length == 0) {
        return;
    }
    NSString *path = @"feedbacks";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"content", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.feedbackTextView.text, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"done");
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error sending feed back. Sorry." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)dismissKeyboard {
    [self.feedbackTextView resignFirstResponder];
}
// text view delegate methods
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if ([textView.textColor isEqual:[UIColor lightGrayColor]]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        textView.textColor = [UIColor lightGrayColor];
        textView.text = @"Your feedback here.";
    }
    return YES;
}


@end
