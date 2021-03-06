//
//  UIViewController+Frecipe.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 2..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrecipeBadgeView.h"
#import "FrecipeAppDelegate.h"

@interface UIViewController (Frecipe)

- (BOOL)isTall;
- (BOOL)isIpad;
- (BOOL)isIphone;
- (void)registerForKeyboardNotifications;
- (void)removeForKeyboardNotifications;
- (void)saveUserInfo:(NSDictionary *)user Token:(NSString *)token ProfilePicture:(NSString *)profilePictureUrl;
- (NSDictionary *)loaduserInfo;
- (NSURL *)documentDirectory;
- (BOOL)validateEmail:(NSString *)email;
- (NSString *)s3BucketURL;

@end
