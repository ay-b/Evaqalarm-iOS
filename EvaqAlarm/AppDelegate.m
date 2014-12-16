//
//  AppDelegate.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 10/25/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "AppDelegate.h"
#import "EAConstants.h"
#import "EAPreferences.h"
#import "EAMainViewController.h"

#import <vk-ios-sdk/VKSdk.h>
#import <Facebook-iOS-SDK/FacebookSDK/FacebookSDK.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    NSDictionary *userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        NSNotification *notification = [NSNotification notificationWithName:EAReceiveAlarmNotification object:self userInfo:userInfo];

        EAMainViewController *vc = (EAMainViewController*)self.window.rootViewController;
        [vc p_receiveAlarm:notification];
    }
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    }
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [FBAppEvents activateApp];
    [[NSNotificationCenter defaultCenter] postNotificationName:EACheckPermissionsNotification object:self];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[url scheme] hasPrefix:[NSString stringWithFormat:@"vk%@", EAVKAppKey]]) {
        return [VKSdk processOpenURL:url fromApplication:sourceApplication];
    }
    else if ([[url scheme] hasPrefix:[NSString stringWithFormat:@"fb%@", EAFBAppId]]) {
        return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    }
    return YES;
}

#pragma mark - Push notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [[[deviceToken description] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""];
    [EAPreferences setUid:token];

    EALog(@"Push token is: %@", token);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    EALog(@"Failed to get push token: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSMutableDictionary *info = [userInfo mutableCopy];
    info[@"playSound"] = application.applicationState == UIApplicationStateActive ? @(YES) : @(NO);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:EAReceiveAlarmNotification object:self userInfo:info];
}

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}
#endif

@end
