//
//  EAConstants.h
//  EvaqAlarm
//
//  Created by Sergey Butenko on 10/25/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kGreenColor [UIColor colorWithRed:169/255.0 green:219/255.0 blue:72/255.0 alpha:1]
#define kRedColor [UIColor colorWithRed:255/255.0 green:59/255.0 blue:48/255.0 alpha:1]
#define kGrayColor [UIColor colorWithRed:220/255.0 green:221/255.0 blue:221/255.0 alpha:1]

static NSString *const kParkingEnabledString = @"Нажмите кнопку для деактивации парковки.\n•\nУдерживайте кнопку для активации тревоги.";
static NSString *const kParkingDisabledString = @"Нажмите кнопку для активации парковки.\n•\nУдерживайте кнопку для активации тревоги.";

extern NSString *const EAAppStoreURL;

extern NSString *const EAReceiveAlarmNotification;

/* System */
extern NSString *const EAPushToken;
extern NSString *const EAParkedNow;

extern NSString *const EAVKAppKey;
extern NSString *const EAFBAppId;

extern NSString *const EAShareMessage;
extern NSString *const EAShareLink;
/* System */

/* URLs */
extern NSString *const EAURLDomain;
extern NSString *const EAURLSetParked;
extern NSString *const EAURLClearParking;
extern NSString *const EAURLSetAlarm;
/* URLs */

// Debug Logging
#if 1
#define EALog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define EALog(x, ...)
#endif