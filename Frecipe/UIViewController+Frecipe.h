//
//  UIViewController+Frecipe.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 2..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrecipeBadgeView.h"
@interface UIViewController (Frecipe)

- (BOOL)isTall;
- (BOOL)isIpad;
- (BOOL)isIphone;
- (void)registerForKeyboardNotifications;
- (void)saveUserInfo:(NSDictionary *)user Token:(NSString *)token ProfilePicture:(NSString *)profilePictureUrl;
- (NSDictionary *)loaduserInfo;
- (NSURL *)documentDirectory;
@end
