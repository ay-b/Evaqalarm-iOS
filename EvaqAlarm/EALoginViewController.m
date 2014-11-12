//
//  EALoginViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 10/26/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EALoginViewController.h"
#import "EAConstants.h"

@implementation EALoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)tapOnView:(UITapGestureRecognizer *)sender
{
    [self performSegueWithIdentifier:@"toMain" sender:sender];
}

@end
