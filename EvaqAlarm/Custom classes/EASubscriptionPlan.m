//
//  EASubscriptionPlan.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 12/15/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EASubscriptionPlan.h"

@interface EASubscriptionPlan ()

@end

@implementation EASubscriptionPlan

- (instancetype)initWithUid:(NSString*)uid price:(NSString*)price duration:(NSString*)duration
{
    self = [super init];
    if (self) {
        _uid = uid;
        _price = price;
        _duration = duration;
    }
    return self;
}

+ (instancetype)planWithUid:(NSString*)uid price:(NSString*)price duration:(NSString*)duration
{
    return [[self alloc]initWithUid:uid price:price duration:duration];
}

@end
