//
//  EAShareViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 10/25/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAShareViewController.h"
#import "EAConstants.h"

#import <VK-ios-sdk/VKSdk.h>
#import <FacebookSDK/FacebookSDK.h>

@interface EAShareViewController () <VKSdkDelegate>

- (IBAction)vkButtonPressed:(id)sender;
- (IBAction)fbButtonPressed:(id)sender;

@end

@implementation EAShareViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [VKSdk initializeWithDelegate:self andAppId:EAVKAppKey];
    [VKSdk wakeUpSession];
}

#pragma mark - Button handlers

- (IBAction)vkButtonPressed:(id)sender
{
    [self p_shareToVK];
}

- (IBAction)fbButtonPressed:(id)sender
{
    [self p_shareToFB];
}

#pragma mark - Social
#pragma mark FB

- (void)p_shareToFB
{
    FBSession *session = [[FBSession alloc] initWithPermissions:@[@"public_profile", @"email", @"user_photos"]];
    [FBSession setActiveSession:session];
    [session openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView
            completionHandler:^(FBSession *session,
                                FBSessionState status,
                                NSError *error) {
                if (error) {
                    NSLog(@"Facebook auth error: [%@]", error);
                } else {
                    [self p_publishToFB];
                }
            }];
}

- (void)p_publishToFB
{
    NSDictionary *params = @{@"link" : EAShareLink,
                             @"picture": @"http://cordiant.ru/images/logo1.png",
                             @"name" : @"Cordiant",
                             @"caption" : @"Ведущий российский производитель шин.",
                             @"message" : EAShareMessage
                             };
    
    [FBRequestConnection startWithGraphPath:@"me/feed" parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
         NSString *alertText;
         if (error) {
             alertText = @"Произошла ошибка, попробуйте еще раз!";
         } else {
             alertText = @"Сообщение успешно опубликовано!";
         }
         [[[UIAlertView alloc] initWithTitle:@"Результат" message:alertText  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
     }];
}

#pragma mark VK

- (void)p_shareToVK
{
    if ([VKSdk isLoggedIn]) {
        [self p_publishToVK];
    }
    else {
        [VKSdk authorize:@[VK_PER_WALL, VK_PER_FRIENDS, VK_PER_OFFLINE] revokeAccess:YES forceOAuth:NO inApp:NO];
    }
}

- (void)p_publishToVK
{
    NSDictionary *parameters = @{@"message" : EAShareMessage, @"attachments:" : EAShareLink};
    VKRequest *request = [[VKApi wall] post:parameters];
    [request executeWithResultBlock:^(VKResponse *response) {
         NSLog(@"share to vk done");
    } errorBlock:^(NSError *error) {
        NSLog(@"share to vk error: %@", error);
    }];
}

#pragma mark - VK sdk delegate

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError
{
    
}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken
{
    
}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError
{
    
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller
{
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken
{
    [self p_publishToVK];
}

@end
