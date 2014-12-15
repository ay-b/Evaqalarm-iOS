//
//  EASubscriptionPlan.h
//  EvaqAlarm
//
//  Created by Sergey Butenko on 12/15/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EASubscriptionPlan : NSObject

@property (readonly, strong) NSString *uid;
@property (readonly, strong) NSString *price;
@property (readonly, strong) NSString *duration;

+ (instancetype)planWithUid:(NSString*)uid price:(NSString*)price duration:(NSString*)duration;

@end
