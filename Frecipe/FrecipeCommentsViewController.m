//
//  FrecipeCommentsViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 6. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeCommentsViewController.h"
#import "FrecipeFunctions.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface FrecipeCommentsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, assign) CGFloat originalHeight;
@end

@implementation FrecipeCommentsViewController

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
    self.commentsTableView.delegate = self;
    self.commentsTableView.dataSource = self;
    self.commentsField.delegate = self;
    self.title = @"Comments";
    [self addGestureRecognizers];
    [self registerForKeyboardNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)commentSendButtonPressed {
    if (self.commentsField.text.length > 0) {
        NSString *path = @"comments";
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
        
        NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"recipe_id", @"text", nil];
        NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, self.commentsField.text, nil];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        
        FrecipeAPIClient *client = [FrecipeAPIClient client];
        NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:parameters];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            self.comments = [JSON objectForKey:@"comments"];
            [self.commentsTableView reloadData];
            
            [self dismissKeyboard];
            self.commentsField.text = @"";
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"%@", error);
        }];
        FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
        [queue addOperation:operation];
    }
}

- (IBAction)commentDeleteButtonPressed:(UIButton *)sender {
    NSIndexPath *indexPath = [self.commentsTableView indexPathForCell:(UITableViewCell *)sender.superview.superview];

    NSDictionary *userAndComment = [self.comments objectAtIndex:indexPath.row];
    
    NSString *path = [NSString stringWithFormat:@"comments/%@", [userAndComment objectForKey:@"comment_id"]];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults stringForKey:@"authentication_token"];
    NSArray *keys = [NSArray arrayWithObjects:@"authentication_token", @"recipe_id", nil];
    NSArray *values = [NSArray arrayWithObjects:authentication_token, self.recipeId, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"DELETE" path:path parameters:parameters];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = self.view.center;
    [spinner startAnimating];
    [self.view addSubview:spinner];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.comments = [JSON objectForKey:@"comments"];
        [self.commentsTableView reloadData];
        
        [spinner stopAnimating];
        [spinner removeFromSuperview];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}


- (void)addGestureRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
}
- (void)dismissKeyboard {
    [self.commentsField resignFirstResponder];
}

// table view dataSource methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *comment = [self.comments objectAtIndex:indexPath.row];
    
    NSString *text = [NSString stringWithFormat:@"%@",[comment objectForKey:@"text"]];
    
    CGSize constraintSize = CGSizeMake(260, MAXFLOAT);
    CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:13] constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    return 50 + textSize.height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell" forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CommentCell"];
    }
    NSDictionary *userAndComment = [self.comments objectAtIndex:indexPath.row];
    NSLog(@"%@", [self.comments objectAtIndex:indexPath.row]);
    FBProfilePictureView *fbProfilePictureView = (FBProfilePictureView *)[cell viewWithTag:1];
    UIImageView *profilePictureView = (UIImageView *)[cell viewWithTag:2];
    if ([[NSString stringWithFormat:@"%@", [userAndComment objectForKey:@"provider"]] isEqualToString:@"facebook"]) {
        profilePictureView.hidden = YES;
        fbProfilePictureView.profileID = [NSString stringWithFormat:@"%@", [userAndComment objectForKey:@"uid"]];
    } else {
        fbProfilePictureView.hidden = YES;
        [profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/%@", [self s3BucketURL], [userAndComment objectForKey:@"user_id"], [userAndComment objectForKey:@"profile_picture"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture"]];
    }
    
    UIButton *nameButton = (UIButton *)[cell viewWithTag:3];
    [nameButton setTitle:[NSString stringWithFormat:@"%@ %@", [userAndComment objectForKey:@"first_name"], [userAndComment objectForKey:@"last_name"]] forState:UIControlStateNormal];
    [nameButton sizeToFit];
    
    UITextView *textView = (UITextView *)[cell viewWithTag:4];
    textView.text = [NSString stringWithFormat:@"%@", [userAndComment objectForKey:@"text"]];
    
    CGSize constraintSize = CGSizeMake(280, MAXFLOAT);
    
    CGSize textSize = [textView.text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    textView.frame = CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, textSize.height + 6);
    
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:5];
    timeLabel.text = [FrecipeFunctions compareWithCurrentDate:[userAndComment objectForKey:@"created_at"]];
    
    [timeLabel sizeToFit];
    UIButton *deleteButton = (UIButton *)[cell viewWithTag:6];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userId = [NSString stringWithFormat:@"%@", [defaults objectForKey:@"id"]];
    if (![userId isEqualToString:[NSString stringWithFormat:@"%@", [userAndComment objectForKey:@"user_id"]]]) {
        deleteButton.hidden = YES;
    } else {
        
        deleteButton.frame = CGRectMake(timeLabel.frame.origin.x + timeLabel.frame.size.width - 5, deleteButton.frame.origin.y, deleteButton.frame.size.width, deleteButton.frame.size.height);
    }
    textView.font = [UIFont systemFontOfSize:13];
    return cell;
}

- (void)keyboardWillBeShown:(NSNotification *)notification {
    self.originalHeight = self.commentsTableView.frame.size.height;
    
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    
//    [UIView animateWithDuration:0.3 animations:^{
//        self.commentsTableView.frame = CGRectMake(self.commentsTableView.frame.origin.x, self.commentsTableView.frame.origin.y, self.commentsTableView.frame.size.width, self.commentsTableView.frame.size.height - (keyboardSize.height - self.view.frame.size.height + self.commentsTableView.frame.origin.y + self.commentsTableView.frame.size.height) - 40);
//        
//        self.commentsField.frame = CGRectMake(self.commentsField.frame.origin.x, self.commentsField.frame.origin.y - keyboardSize.height + 15, self.commentsField.frame.size.width, self.commentsField.frame.size.height);
//        
//        self.sendButton.frame = CGRectMake(self.sendButton.frame.origin.x, self.sendButton.frame.origin.y - keyboardSize.height + 15, self.sendButton.frame.size.width, self.sendButton.frame.size.height);
//    }];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.commentsTableView.frame = CGRectMake(self.commentsTableView.frame.origin.x, self.commentsTableView.frame.origin.y, self.commentsTableView.frame.size.width, self.commentsTableView.frame.size.height - (keyboardSize.height - self.view.frame.size.height + self.commentsTableView.frame.origin.y + self.commentsTableView.frame.size.height) - 40);
        
        self.commentsField.frame = CGRectMake(self.commentsField.frame.origin.x, self.commentsField.frame.origin.y - keyboardSize.height + 15, self.commentsField.frame.size.width, self.commentsField.frame.size.height);
        
        self.sendButton.frame = CGRectMake(self.sendButton.frame.origin.x, self.sendButton.frame.origin.y - keyboardSize.height + 15, self.sendButton.frame.size.width, self.sendButton.frame.size.height);
    } completion:^(BOOL finished) {
        if (self.comments.count > 0) {
            [self.commentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.comments.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.commentsTableView.frame = CGRectMake(self.commentsTableView.frame.origin.x, self.commentsTableView.frame.origin.y, self.commentsTableView.frame.size.width, self.originalHeight);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.commentsField.frame = CGRectMake(self.commentsField.frame.origin.x, self.commentsField.frame.origin.y + keyboardSize.height - 15, self.commentsField.frame.size.width, self.commentsField.frame.size.height);
        
        self.sendButton.frame = CGRectMake(self.sendButton.frame.origin.x, self.sendButton.frame.origin.y + keyboardSize.height - 15, self.sendButton.frame.size.width, self.sendButton.frame.size.height);
    } completion:^(BOOL finished) {
        if (self.comments.count > 0) {
            [self.commentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.comments.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
    
}

@end
