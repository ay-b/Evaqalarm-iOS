//
//  EAPlanTableViewCell.h
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/12/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EASubscriptionPlan;

@interface EAPlanTableViewCell : UITableViewCell

- (void)configureWithPlan:(EASubscriptionPlan*)plan;

@end
