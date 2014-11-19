//
//  EAPreferences.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/19/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAPreferences.h"

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

@end
