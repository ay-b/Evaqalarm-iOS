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
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <YandexMobileMetrica/YandexMobileMetrica.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "TFTaifuno.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (void)initialize
{
    if ([self class] == [AppDelegate class]) {
    #ifndef DEBUG
        [YMMYandexMetrica startWithAPIKey:EAYandexMetricApiKey];
    #endif
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[TFTaifuno sharedInstance] setApiKey:EATaifunoApiKey];
    [Fabric with:@[CrashlyticsKit]];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    NSDictionary *userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        [[NSNotificationCenter defaultCenter] postNotificationName:EAReceiveAlarmNotification object:self userInfo:userInfo];
    }
    
    if ([EAPreferences isPermissionsRequested]) {
        [self p_requestRegisterNotifications];
    }
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_requestRegisterNotifications) name:EARequestPermissionsNotification object:nil];
    }
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
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
    return YES;
}

- (void) applicationWillTerminate:(UIApplication *)application
{
    [[TFTaifuno sharedInstance] saveTaifuno];
}

#pragma mark - Push notifications

- (void)p_requestRegisterNotifications
{
    UIApplication *application = [UIApplication sharedApplication];
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    else {
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [[[deviceToken description] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""];
    [EAPreferences setUid:token];
    [[TFTaifuno sharedInstance] registerDeviceToken:[token stringByReplacingOccurrencesOfString:@" " withString:@""]];

    EALog(@"Push token is: %@", token);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    EALog(@"Failed to get push token: %@", error);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSMutableDictionary *extendedUserInfo = [userInfo mutableCopy];
    extendedUserInfo[@"playSound"] = application.applicationState == UIApplicationStateActive ? @(YES) : @(NO);

    [[NSNotificationCenter defaultCenter] postNotificationName:EAReceiveAlarmNotification object:self userInfo:extendedUserInfo];
    completionHandler(UIBackgroundFetchResultNewData);
    
    [[TFTaifuno sharedInstance] didRecieveNewNotification:userInfo];
}

@end
