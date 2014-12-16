//
//  EAMainViewController.h
//  EvaqAlarm
//
//  Created by Sergey Butenko on 10/25/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAMainViewController : UIViewController

- (IBAction)shareButtonPressed;

- (void)p_receiveAlarm:(NSNotification*)notification;

@end
