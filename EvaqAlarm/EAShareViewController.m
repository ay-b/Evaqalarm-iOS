//
//  EAShareViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/18/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAShareViewController.h"
#import "EAConstants.h"

static NSString *const shareText = @"EvaqAlarm хорошо работает, когда у приложения много пользователей — расскажи друзьям!";
static NSString *const ratingText = @"EqvaqAlarm – отличное приложение, так ведь? Стоит поставить ему хорошую оценку, чтобы другие сразу видели это!";

@interface EAShareViewController ()

- (IBAction)cancelButtonPressed;
- (IBAction)confirmButtonPressed;

@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation EAShareViewController

- (void)viewDidLoad
{ 
    [super viewDidLoad];
    self.textLabel.text = _isSharing ? shareText : ratingText;
}

- (IBAction)cancelButtonPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)confirmButtonPressed
{
    if (_isSharing) {
        
    }
    else {
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:EAAppStoreURL]];
    }
}

@end
