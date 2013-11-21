//
//  FrecipeCommentsViewController.h
//  Frecipe
//
//  Created by Hara Kang on 13. 6. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface FrecipeCommentsViewController : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UITableView *commentsTableView;
@property (weak, nonatomic) IBOutlet UITextField *commentsField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) NSMutableArray *comments;
@property (strong, nonatomic) NSString *recipeId;

@end

