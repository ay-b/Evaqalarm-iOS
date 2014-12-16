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

static NSString *const kShareText = @"EvaqAlarm хорошо работает, когда у приложения много пользователей — расскажи друзьям!";
static NSString *const kRatingText = @"EqvaqAlarm – отличное приложение, так ведь? Стоит поставить ему хорошую оценку, чтобы другие сразу видели это!";

@interface EAShareViewController ()

- (IBAction)cancelButtonPressed;
- (IBAction)confirmButtonPressed;

@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation EAShareViewController

- (void)viewDidLoad
{ 
    [super viewDidLoad];
    self.textLabel.text = _sharing ? kShareText : kRatingText;
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
