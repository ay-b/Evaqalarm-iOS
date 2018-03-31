//
//  EAButtonViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 1/31/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "EAButtonViewController.h"
#import "EAAlarmButton.h"

@interface EAButtonViewController ()

- (IBAction)stop;
- (IBAction)start;
@property (weak, nonatomic) IBOutlet EAAlarmButton *alarmButton;

@end

@implementation EAButtonViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)stop
{
    [self.alarmButton stopAlarm];
}

- (IBAction)start
{
    [self.alarmButton startAlarm];
}

@end
