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
#define kDarkGrayColor [UIColor colorWithRed:0.41 green:0.46 blue:0.5 alpha:1]

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

/* System */
extern NSString *const EAReceiveAlarmNotification;
extern NSString *const EACheckPermissionsNotification;
extern NSString *const EARequestPermissionsNotification;

extern NSString *const EAAppStoreURL;
extern NSString *const EAYandexMetricApiKey;
extern NSString *const EATaifunoApiKey;

extern NSString *const EAPushToken;
extern NSString *const EAParkedNow;

extern NSString *const EAVKAppKey;
extern NSString *const EAFBAppId;

extern NSString *const EAShareLink;
/* System */

/* URLs */
extern NSString *const EAURLDomain;
extern NSString *const EAURLSetParked;
extern NSString *const EAURLClearParking;
extern NSString *const EAURLSetAlarm;
extern NSString *const EAURLPetition;
extern NSString *const EAURLPraise;
/* URLs */

#ifdef DEBUG
#define EALog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define EALog(x, ...)
#endif

#define LOC(key) NSLocalizedString((key), @"")