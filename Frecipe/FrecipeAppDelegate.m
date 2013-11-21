//
//  FrecipeAppDelegate.m
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeAppDelegate.h"
#import "FrecipeAPIClient.h"
#import <NewRelicAgent/NewRelicAgent.h>
#import <GoogleMaps/GoogleMaps.h>
#import <SBAPNSPusher.h>

@implementation FrecipeAppDelegate
@synthesize ingredients = _ingredients;
@synthesize recipes = _recipes;

- (NSMutableArray *)ingredients {
    if (_ingredients == nil) {
        
    }
    return _ingredients;
}

- (NSMutableArray *)recipes {
    if (_recipes == nil) {
        
    }
    return _recipes;
}

NSString *const FBSessionStateChangedNotification = @"com.Frecipe.Frecipe:FBSessionStateChangedNotification";

- (void)sessionStateChanged:(FBSession *)session State: (FBSessionState) state Error: (NSError *)error {
    switch (state) {
        case FBSessionStateOpen:
            if (!error) {
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FBSessionStateChangedNotification object:session];
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *authentication_token = [defaults objectForKey:@"authentication_token"];
    
    NSString *provider = [defaults stringForKey:@"provider"];
//    [[UIBarButtonItem appearance] setTintColor:[[UIColor alloc] initWithRed:0.86 green:0.30 blue:0.27 alpha:1]];
    self.window.tintColor = [[UIColor alloc] initWithRed:0.86 green:0.30 blue:0.27 alpha:1];
//    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIIm] forState:<#(UIControlState)#> barMetrics:<#(UIBarMetrics)#>
    if ([provider isEqualToString:@"facebook"]) {
        if (!FBSession.activeSession.isOpen) {
            [FBSession openActiveSessionWithReadPermissions:[NSArray arrayWithObjects:@"email", nil]allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            }];
        }
    }
    
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"bar_red.png"] forBarMetrics:UIBarMetricsDefault];
    
//    [[UISearchBar appearance] setBackgroundImage:[UIImage imageNamed:@"bar_red.png"]];
    
//    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"bar_red.png"] forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
    
    UIStoryboard *storyboard = self.window.rootViewController.storyboard;
    UIViewController *initViewController;

    if (authentication_token) {
        initViewController = [storyboard instantiateViewControllerWithIdentifier:@"Initial"];
    } else {
        initViewController = [storyboard instantiateViewControllerWithIdentifier:@"Login"];
    }
    
    // register for remote notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    
    // start hockey app
//    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:@"8484ababc392d769df681ca04c4e7577" liveIdentifier:@"8484ababc392d769df681ca04c4e7577" delegate:self];
//    [[BITHockeyManager sharedHockeyManager] startManager];
//    [[BITHockeyManager sharedHockeyManager].updateManager setRequireAuthorization:YES];
//    [[BITHockeyManager sharedHockeyManager].updateManager setAuthenticationSecret:@"b9c372f90ac7726f80cd2681f853f9bc"];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    // stat new relic
//    [NewRelicAgent startWithApplicationToken:@"AAc3ea27dc72cade020e5d024fda602d64acf5a852"];
    
    
    // start Google Anayltics
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    // Optional: set debug to YES for extra debugging information.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-42729674-1"];
    [tracker self];
    // start Google Maps
    
    [SBAPNSPusher start];
    [GMSServices provideAPIKey:@"AIzaSyCuR2690b6QFZY_BwvumrszQudupzD-Og0"];
    self.window.rootViewController = initViewController;
    return YES;
}

//- (NSString *)customDeviceIdentifierForUpdateManager:(BITUpdateManager *)updateManager {
//#ifndef CONFIGURATION_AppStore
//    if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)]) {
//        NSLog(@"send device identifier to hockey app!");
//        return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
//    }
//#endif
//    return nil;
//}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBSession.activeSession handleOpenURL:url];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)sendDeviceToken:(NSData *)deviceToken {
    NSString *path = @"tokens/device.json";
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSString *authentication_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"authentication_token"];
    
    if (!authentication_token) {
        return;
    }
    
    NSLog(@"%@", [deviceToken description]);
    NSURLRequest *request = [client requestWithMethod:@"POST" path:path parameters:@{@"authentication_token": authentication_token, @"device_token": [[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""]}];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [[NSUserDefaults standardUserDefaults] setValue:[deviceToken description] forKey:@"device_token"];
        NSLog(@"%@", JSON);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

// notification delegate methods

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSString *previousDescriptionToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"];
    if (![previousDescriptionToken isEqualToString:[deviceToken description]]) {
        NSLog(@"not same!");
        
        [self sendDeviceToken:deviceToken];
    } else {
        NSLog(@"same!");
        [self sendDeviceToken:deviceToken];
        NSLog(@"%@", [deviceToken description]);
    }
    
    
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to register for push notifications.");
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        
    } else if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive) {
        
    } else if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        
    } else {
        
    }
}

// custom methods for registering push notifiactions
@end
