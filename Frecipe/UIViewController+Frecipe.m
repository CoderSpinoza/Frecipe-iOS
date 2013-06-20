//
//  UIViewController+Frecipe.m
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 2..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "UIViewController+Frecipe.h"

@implementation UIViewController (Frecipe)

- (BOOL)isTall {
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    if (height == 568 || height == 1024) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isIpad {
    NSString *device = [[UIDevice currentDevice] model];
    
    return [device hasPrefix:@"iPad"];
}

- (BOOL)isIphone {
    NSString *device = [[UIDevice currentDevice] model];
    
    return [device hasPrefix:@"iPhone"];
}

- (NSURL *)documentDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (BOOL)validateEmail:(NSString *)email {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailPredicate evaluateWithObject:email];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:self];
}

- (void)saveUserInfo:(NSDictionary *)user Token:(NSString *)token ProfilePicture:(NSString *)profilePictureUrl {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[user objectForKey:@"id"] forKey:@"id"];
    if ([[NSString stringWithFormat:@"%@", [user objectForKey:@"provider"]] isEqualToString:@"facebook"]) {
        [defaults setObject:[user objectForKey:@"provider"] forKey:@"provider"];
        [defaults setObject:[user objectForKey:@"uid"] forKey:@"uid"];
    }
    
    if (token) {
        [defaults setObject:token forKey:@"authentication_token"];
    }
    if (profilePictureUrl) {
        [defaults setObject:profilePictureUrl forKey:@"profile_picture"];
    }
    
    [defaults setObject:[NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]] forKey:@"name"];
    [defaults setObject:[NSString stringWithFormat:@"%@", [user objectForKey:@"website"]] forKey:@"website"];
    [defaults setObject:[NSString stringWithFormat:@"%@", [user objectForKey:@"first_name"]] forKey:@"first_name"];
    [defaults setObject:[NSString stringWithFormat:@"%@", [user objectForKey:@"last_name"]] forKey:@"last_name"];
    [defaults setObject:[NSString stringWithFormat:@"%@", [user objectForKey:@"email"]] forKey:@"email"];
    [defaults setObject:[NSString stringWithFormat:@"%@", [user objectForKey:@"about"]] forKey:@"about"];
    [defaults synchronize];
}

- (NSDictionary *)loaduserInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *keys = [NSArray arrayWithObjects:@"id", @"email", @"first_name", @"last_name", @"provider", @"uid", @"website", @"about", nil];
    
    NSString *provider = [defaults stringForKey:@"provider"];
    NSString *uid = [defaults stringForKey:@"uid"];
    if (provider == nil) {
        provider = @"";
        uid = @"";
    }
    
    NSArray *values = [NSArray arrayWithObjects:[defaults stringForKey:@"id"],[defaults stringForKey:@"email"], [defaults stringForKey:@"first_name"], [defaults stringForKey:@"last_name"], provider, uid, [defaults stringForKey:@"website"], [defaults stringForKey:@"about"], nil];
    
    NSDictionary *user = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    return user;
}

- (NSString *)s3BucketURL {
    NSString *url;
    if (STAGING) {
        url = @"https://s3.amazonaws.com/Frecipe/public/image";
    } else {
        url = @"https://s3.amazonaws.com/FrecipeProduction/public/image";
    }
    return url;
}


@end
