//
//  FrecipeNotificationsViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 10..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeNotificationsViewController.h"
#import <UIImageView+WebCache.h>
#import <FacebookSDK/FacebookSDK.h>

@interface FrecipeNotificationsViewController ()

@end

@implementation FrecipeNotificationsViewController
@synthesize notifications = _notifications;

- (void)setNotifications:(NSMutableArray *)notifications {
    _notifications = notifications;
    [self.tableView reloadData];
}
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Notifications";
//    NSLog(@"load");
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
//    NSLog(@"%@", self.notifications);
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    CGFloat fontSize = 13;
    UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    UIFont *regularFont = [UIFont systemFontOfSize:fontSize];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName, nil];
    NSDictionary *subAttributes = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName, nil];
    
    NSDictionary *notification = [self.notifications objectAtIndex:indexPath.row];
    NSDictionary *source = [notification objectForKey:@"source"];
    NSDictionary *recipe = [notification objectForKey:@"recipe"];
    NSString *category = [NSString stringWithFormat:@"%@", [notification objectForKey:@"category"]];
    
    NSString *sourceName = [NSString stringWithFormat:@"%@ %@", [source objectForKey:@"first_name"], [source objectForKey:@"last_name"]];
    NSString *recipeName;
    NSRange sourceRange = NSMakeRange(0, sourceName.length);
    NSString *originalText;
    if ([category isEqualToString:@"like"]) {
        recipeName = [NSString stringWithFormat:@"%@", [recipe objectForKey:@"name"]];
        originalText = [NSString stringWithFormat:@"%@ liked your recipe %@.", sourceName, recipeName];
    } else if ([category isEqualToString:@"comment"]) {
        recipeName = [NSString stringWithFormat:@"%@", [recipe objectForKey:@"name"]];
        originalText = [NSString stringWithFormat:@"%@ commented on your recipe %@.", sourceName, recipeName];
    } else if ([category isEqualToString:@"follow"]) {
        originalText = [NSString stringWithFormat:@"%@ is now following you!", sourceName];
    } else {
        recipeName = [NSString stringWithFormat:@"%@", [recipe objectForKey:@"name"]];
        originalText = [NSString stringWithFormat:@"%@ uploaded a new recipe %@.", sourceName, recipeName];
    }
    
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:originalText attributes:subAttributes];
    [attributedText setAttributes:attributes range:sourceRange];
    
    if (![category isEqualToString:@"follow"]) {
        NSRange recipeRange = NSMakeRange(originalText.length - recipeName.length - 1, recipeName.length);
        [attributedText setAttributes:attributes range:recipeRange];
    }
    
    cell.textLabel.attributedText = attributedText;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    if ([[NSString stringWithFormat:@"%@", [notification objectForKey:@"seen"]] isEqualToString:@"0"]) {
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        backgroundView.opaque = YES;
        backgroundView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.95 alpha:0.7];
        cell.backgroundView = backgroundView;
    } else {
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        backgroundView.opaque = YES;
        backgroundView.backgroundColor = [UIColor clearColor];
        cell.backgroundView = backgroundView;
    }
    NSString *provider = [NSString stringWithFormat:@"%@", [source objectForKey:@"provider"]];
    
    FBProfilePictureView *fbProfilePictreView = [[FBProfilePictureView alloc] initWithProfileID:[NSString stringWithFormat:@"%@", [source objectForKey:@"uid"]] pictureCropping:FBProfilePictureCroppingSquare];
    if ([provider isEqualToString:@"facebook"]) {
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
        [imageView removeFromSuperview];
        cell.imageView.image = [UIImage imageNamed:@"default_profile_picture.png"];
        
//        fbProfilePictreView.frame = CGRectMake(0, 0, 43, 43);
        
        CGFloat height = [self calculateHeight:indexPath];
        
        
        FBProfilePictureView *previousView = (FBProfilePictureView *)[cell viewWithTag:1];
        UIImageView *previousView2 = (UIImageView *)[cell viewWithTag:2];
        [previousView removeFromSuperview];
        [previousView2 removeFromSuperview];
        fbProfilePictreView.tag = 1;
        
        if (height > 40) {
            fbProfilePictreView.frame = CGRectMake(0, (height - 43) / 2, 43, 43);
        } else {
            fbProfilePictreView.frame = CGRectMake(0, 0, 43, 43);
        }
        [cell addSubview:fbProfilePictreView];
        cell.imageView.hidden = YES;
    } else {
        
        FBProfilePictureView *previousView = (FBProfilePictureView *)[cell viewWithTag:1];
        UIImageView *previousView2 = (UIImageView *)[cell viewWithTag:2];
        [previousView removeFromSuperview];
        [previousView2 removeFromSuperview];
        
        cell.imageView.image = [UIImage imageNamed:@"default_profile_picture.png"];
        fbProfilePictreView.hidden = YES;
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.tag = 1;
        [imageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [notification objectForKey:@"profile_picture"]]] placeholderImage:[UIImage imageNamed:@"default_profile_picture.png"]];
        [cell addSubview:imageView];
        
        
        
        imageView.tag = 2;
        CGFloat height = [self calculateHeight:indexPath];
        if (height > 40) {
            imageView.frame = CGRectMake(0, (height - 43) / 2, 43, 43);
        } else {
            imageView.frame = CGRectMake(0, 0, 43, 43);
        }
        cell.imageView.hidden = YES;
    }
    
    return cell;
}


- (CGFloat)calculateHeight:(NSIndexPath *)indexPath {
    CGFloat fontSize = 14;
    UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    
    NSDictionary *notification = [self.notifications objectAtIndex:indexPath.row];
    NSDictionary *source = [notification objectForKey:@"source"];
    NSDictionary *recipe = [notification objectForKey:@"recipe"];
    NSString *category = [NSString stringWithFormat:@"%@", [notification objectForKey:@"category"]];
    
    NSString *sourceName = [NSString stringWithFormat:@"%@ %@", [source objectForKey:@"first_name"], [source objectForKey:@"last_name"]];
    NSString *originalText;
    if ([category isEqualToString:@"like"]) {
        originalText = [NSString stringWithFormat:@"%@ liked your recipe %@.", sourceName, [recipe objectForKey:@"name"]];
    } else if ([category isEqualToString:@"comment"]) {
        originalText = [NSString stringWithFormat:@"%@ commented on your recipe %@.", sourceName, [recipe objectForKey:@"name"]];
    } else if ([category isEqualToString:@"follow"]) {
        originalText = [NSString stringWithFormat:@"%@ is now following you!", sourceName];
    } else {
        originalText = [NSString stringWithFormat:@"%@ uploaded a new recipe %@.", sourceName, [recipe objectForKey:@"name"]];
    }
    
    CGSize constraintSize = CGSizeMake(200, MAXFLOAT);
    CGSize labelSize = [originalText sizeWithFont:boldFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    if (labelSize.height > 40) {
        return labelSize.height+10;
    } else {
        return 44;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat fontSize = 14;
    UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    
    NSDictionary *notification = [self.notifications objectAtIndex:indexPath.row];
    NSDictionary *source = [notification objectForKey:@"source"];
    NSDictionary *recipe = [notification objectForKey:@"recipe"];
    NSString *category = [NSString stringWithFormat:@"%@", [notification objectForKey:@"category"]];
    
    NSString *sourceName = [NSString stringWithFormat:@"%@ %@", [source objectForKey:@"first_name"], [source objectForKey:@"last_name"]];
    NSString *originalText;
    if ([category isEqualToString:@"like"]) {
        originalText = [NSString stringWithFormat:@"%@ liked your recipe %@.", sourceName, [recipe objectForKey:@"name"]];
    } else if ([category isEqualToString:@"comment"]) {
        originalText = [NSString stringWithFormat:@"%@ commented on your recipe %@.", sourceName, [recipe objectForKey:@"name"]];
    } else if ([category isEqualToString:@"follow"]) {
        originalText = [NSString stringWithFormat:@"%@ is now following you!", sourceName];
    } else {
        originalText = [NSString stringWithFormat:@"%@ uploaded a new recipe %@.", sourceName, [recipe objectForKey:@"name"]];
    }
    
    CGSize constraintSize = CGSizeMake(200, MAXFLOAT);
    CGSize labelSize = [originalText sizeWithFont:boldFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    if (labelSize.height > 40) {
        
        return labelSize.height+10;
    } else {
        return 44;
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate



@end
