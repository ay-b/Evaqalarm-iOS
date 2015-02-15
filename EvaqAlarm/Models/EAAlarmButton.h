//
//  EAAlarmButton.h
//  Alarm Button
//
//  Created by Sergey Butenko on 1/30/15.
//  Copyright (c) 2015 Serhii Butenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAAlarmButton;

@protocol EAAlarmButtonDelegate <NSObject>

- (void)alarmButton:(EAAlarmButton*)sender setParked:(BOOL)parked;



@end

@interface EAAlarmButton : UIView

@property (nonatomic, weak) id<EAAlarmButtonDelegate>delegate;

- (void)startAlarm;
- (void)stopAlarm;

@end
