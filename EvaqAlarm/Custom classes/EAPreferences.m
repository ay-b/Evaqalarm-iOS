//
//  EAPreferences.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/19/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAPreferences.h"
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
    if (count%10 == 0) { // 10, 20, 30, 40
        [self.delegate shouldPresentFeedbackView];
    }
    else if (count%5 == 0) { // 5, 15, 25, 35
        [self.delegate shouldPresentSharingView];
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

+ (BOOL)fullAccessEnabled
{
    return [self isPushEnabled] && [self isLocationEnabled];
}

+ (BOOL)isLocationEnabled
{
    return [CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways);
}

+ (BOOL)isPushEnabled
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        return [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    }
    
    UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    return !(types == UIRemoteNotificationTypeNone);
}

@end
