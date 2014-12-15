//
//  EAPreferences.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/19/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAPreferences.h"
#import "EASubscriptionPlan.h"
#import "EAConstants.h"
@import UIKit;
@import CoreLocation;

static NSString *const kParkingCount = @"ParkingCount";

@implementation EAPreferences

- (instancetype)initWithDelegate:(id<EAPreferencesDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (NSInteger)countOfParking
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kParkingCount];
}

- (void)incerementParkingCount
{
    NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:kParkingCount];
    count++;
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kParkingCount];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self p_shouldPresentView];
}

- (void)p_shouldPresentView
{
    NSInteger count = [self countOfParking];
    if (count%5 == 0 && count%10 != 0) { // 5, 15, 25, 35
        [self.delegate shouldPresentSharingView];
    }
    else if (count%10 == 0) { // 10, 20, 30, 40
        [self.delegate shouldPresentFeedbackView];
    }
}

+ (void)setUid:(NSString*)uid
{
    [[NSUserDefaults standardUserDefaults] setObject:uid forKey:EAPushToken];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*)uid
{
    NSString *uid = [[NSUserDefaults standardUserDefaults] objectForKey:EAPushToken];
    return uid ? uid : @"";
}

+ (NSArray*)availablePlans
{
    EASubscriptionPlan *plan1 = [EASubscriptionPlan planWithUid:@"me.speind.evaqalarm.subscription1" price:@"50" duration:@"1 месяц"];
    EASubscriptionPlan *plan6 = [EASubscriptionPlan planWithUid:@"me.speind.evaqalarm.subscription6" price:@"250" duration:@"6 месяцев"];
    EASubscriptionPlan *plan12 = [EASubscriptionPlan planWithUid:@"me.speind.evaqalarm.subscription12" price:@"450" duration:@"12 месяцев"];

    return @[plan1, plan6, plan12];
}

+ (BOOL)fullAccessEnabled
{
    return [self p_isPushEnabled] && [self p_isLocationEnabled];
}

+ (BOOL)p_isLocationEnabled
{
    return [CLLocationManager locationServicesEnabled];
}

+ (BOOL)p_isPushEnabled
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        return [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    }
    
    UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    return !(types == UIRemoteNotificationTypeNone);
}

@end
