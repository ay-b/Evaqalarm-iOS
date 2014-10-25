//
//  NSString+Date.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 10/25/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "NSString+Date.h"

@implementation NSString (Date)

+ (NSString*)stringWithDate:(NSDate*)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    return [formatter stringFromDate:date];
}

@end
