//
//  EAPreferences.h
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/19/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EAPreferencesDelegate <NSObject>

- (void)shouldPresentSharingView;
- (void)shouldPresentFeedbackView;

@end

@interface EAPreferences : NSObject

@property (weak) id<EAPreferencesDelegate> delegate;
- (instancetype)initWithDelegate:(id<EAPreferencesDelegate>)delegate NS_DESIGNATED_INITIALIZER;

@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger countOfParking;
- (void)incerementParkingCount;

+ (void)setUid:(NSString*)uid;
+ (NSString*)uid;

+ (BOOL)fullAccessEnabled;
+ (BOOL)isLocationEnabled;
+ (BOOL)isPushEnabled;

+ (void)permissionsRequested;
+ (BOOL)isPermissionsRequested;

@end
