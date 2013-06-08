//
//  FrecipeAppDelegate.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#define PRODUCTION YES
#define STAGING YES
@interface FrecipeAppDelegate : UIResponder <UIApplicationDelegate, BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
extern NSString *const FBSessionStateChangedNotification;
- (void)sessionStateChanged:(FBSession *)session State: (FBSessionState) state Error: (NSError *)error;
@end
