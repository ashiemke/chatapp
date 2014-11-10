//
//  AppDelegate.m
//  chat
//
//  Created by Adam Shiemke on 11/5/14.
//  Copyright (c) 2014 Adam Shiemke. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <SVProgressHUD.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [Parse setApplicationId:@"4601bz0aVUS3PU3Bcb4Jl37YOEaZLN38cGdnGoQD"
                  clientKey:@"uBmLBAGZ8oW7rwmXdset7S32vXxFI3WdW3B4jSjY"];
    
    // handle notification data if we start up cold
    NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notificationPayload && notificationPayload[@"conversation"]){
        [self handleNotificationForConversationId:notificationPayload[@"conversation"]];
    }
    
    // Register for Push Notitications, if running iOS 8
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge );
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else {
        // Register for Push Notifications before iOS 8
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert )];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Clear the app badge when the app starts
    if ([PFInstallation currentInstallation].badge != 0) {
        [PFInstallation currentInstallation].badge = 0;
        [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                // TODO: Handle error
            }
            else {
                // only update locally if the remote update succeeded so they always match
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
            }
        }];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
    
    if (userInfo[@"conversation"]){
        [self handleNotificationForConversationId:userInfo[@"conversation"]];
    }
    
}

- (void) handleNotificationForConversationId:(NSString*)conversationId{
//    PFObject *conversation = [PFObject objectWithoutDataWithClassName:@"Conversation" objectId:conversationId];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewDataForConversationNotificationName object:self userInfo:@{@"conversationId":conversationId}];
    
}

@end
