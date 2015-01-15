//
//  EAShareViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/18/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAShareViewController.h"
#import "EAConstants.h"
#import "EAMainViewController.h"

@interface EAShareViewController ()

- (IBAction)cancelButtonPressed;
- (IBAction)confirmButtonPressed;

@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation EAShareViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textLabel.text = _sharing ? NSLocalizedString(@"Invite to share", nil) : NSLocalizedString(@"Invite to rate", nil);
}

- (IBAction)cancelButtonPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)confirmButtonPressed
{
    EAMainViewController *vc = (EAMainViewController*)self.presentingViewController;
    
    [self dismissViewControllerAnimated:YES completion:^{
        if (_sharing) {
            [vc shareButtonPressed];
        }
        else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:EAAppStoreURL]];
        }
    }];
}

@end
