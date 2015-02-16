//
//  EARequestPermissionsViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 2/16/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "EARequestPermissionsViewController.h"
#import "EAConstants.h"
#import "EAPreferences.h"

static const NSTimeInterval kButtonAppearanceTimeInterval = 3;
static const NSTimeInterval kButtonAlphaTimeInterval = 0.3;

@interface EARequestPermissionsViewController ()

- (IBAction)confirmButtonPressed;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;

@end

@implementation EARequestPermissionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSTimer scheduledTimerWithTimeInterval:kButtonAppearanceTimeInterval target:self selector:@selector(p_showButton) userInfo:nil repeats:NO];
}

- (void)p_showButton
{
    [UIView animateWithDuration:kButtonAlphaTimeInterval animations:^{
        self.confirmButton.alpha = 1;
    }];
}

- (IBAction)confirmButtonPressed
{
    [EAPreferences permissionsRequested];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:EARequestPermissionsNotification object:nil userInfo:nil];
    }];
}

@end
