//
//  EAMainViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 10/25/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAMainViewController.h"
#import "EAConstants.h"
#import "NSString+Date.h"

#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFNetworking.h>
#import <DTProgressView.h>
#import <VK-ios-sdk/VKSdk.h>
#import <FacebookSDK/FacebookSDK.h>

static const NSInteger kFacebookButton = 0;
static const NSInteger kVkontakteButton = 1;
static const NSTimeInterval kAnimationDuration = 1.8;

static const NSInteger kStatusHeight = 20;
static const NSInteger kTopOffset = 45 + 6; // radius = 12, so we should offset r/2

static NSString *const kParkingEnabledString = @"Нажмите кнопку для деактивации парковки.\n•\nУдерживайте кнопку для активации тревоги.";
static NSString *const kParkingDisabledString = @"Нажмите кнопку для активации парковки.\n•\nУдерживайте кнопку для активации тревоги.";

#define kGreenColor [UIColor colorWithRed:169/255.0 green:219/255.0 blue:72/255.0 alpha:1]
#define kRedColor [UIColor colorWithRed:255/255.0 green:59/255.0 blue:48/255.0 alpha:1]
#define kGrayColor [UIColor colorWithRed:220/255.0 green:221/255.0 blue:221/255.0 alpha:1]

@interface EAMainViewController () <CLLocationManagerDelegate, UIActionSheetDelegate, VKSdkDelegate, UIGestureRecognizerDelegate>
{
    BOOL isParking;
    BOOL isAlarmSent;
    BOOL isAnimationStarted;
    NSTimer *alarmTimer;
}
@property CLLocationManager *locationManager;
@property CLLocation *parkingLocation;
@property NSDate *parkingDate;

#pragma mark - UI

- (IBAction)alarmButtonPressed:(UIButton*)sender;
@property (weak, nonatomic) IBOutlet UIButton *alarmButton;
@property (weak, nonatomic) IBOutlet UILabel *instructionLabel;

@end

@implementation EAMainViewController

#pragma mark - View life cycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.locationManager startUpdatingLocation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateLocationManager];
    
    self.instructionLabel.text = kParkingDisabledString;
    [self.alarmButton setBackgroundColor:kGrayColor];
}

- (void)updateLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
//    [self.locationManager startUpdatingLocation];
//    [self.locationManager stopUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.locationManager stopUpdatingLocation];
    [super viewWillDisappear:animated];
}

#pragma mark - Button handlers

- (IBAction)parkingSwitchChanged:(UISwitch*)sender
{
    if (sender.isOn) {
        self.parkingLocation = self.locationManager.location;
        self.parkingDate = [NSDate date];
        [self p_sendLocation];
    }
    else {
        self.parkingLocation = nil;
    }
}

- (IBAction)showShare
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Расскажи друзьям" delegate:self cancelButtonTitle:@"Отменить" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"VK", nil];
    [actionSheet showInView:[self.view window]];
}

- (IBAction)tap:(id)sender
{
    if (isAnimationStarted) {
        return;
    }
    
    NSLog(@"tap");
    
    isParking = !isParking;
    [self.alarmButton setBackgroundColor:isParking ? kGreenColor : kGrayColor];
    
    if (isParking) {
        //[self p_sendLocation];
    }
}

- (IBAction)sendAlarm:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        isAlarmSent = YES;
        isAnimationStarted = NO;
        [self p_stopAnimation];
        //[self p_sendAlarm];

         NSLog(@"alarm sent");
    }
}

- (IBAction)starAnimation:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self p_startAnimation];
    }
    else if (sender.state == UIGestureRecognizerStateEnded && !isAlarmSent) {
        [self p_stopAnimation];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]];
    return YES;
}

#pragma mark - Private API

#pragma mark Animation

- (void)p_startAnimation
{
    NSLog(@"start animation");
    isAnimationStarted = YES;
    isAlarmSent = NO;
    
    
    
    // Set up the shape of the circle
    int radius = 100;
    CAShapeLayer *circle = [CAShapeLayer layer];
    // Make a circular shape
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius)
                                             cornerRadius:radius].CGPath;
    // Center the shape in self.view
    circle.position = CGPointMake(CGRectGetMidX(self.view.frame)-radius, kTopOffset + kStatusHeight);

    // Configure the apperence of the circle
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.strokeColor = kRedColor.CGColor;
    circle.lineWidth = 12;

    // Add to parent layer
    [self.view.layer addSublayer:circle];

    // Configure animation
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    drawAnimation.duration            = kAnimationDuration; // "animate over 10 seconds or so.."
    drawAnimation.repeatCount         = 1.0;  // Animate only once..

    // Animate from no part of the stroke being drawn to the entire stroke being drawn
    drawAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    drawAnimation.toValue   = [NSNumber numberWithFloat:1.0f];

    // Experiment with timing to get the appearence to look the way you want
    drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];

    // Add the animation to the circle
    [circle addAnimation:drawAnimation forKey:@"drawCircleAnimation"];
}

- (void)p_stopAnimation
{
    isAnimationStarted = NO;
    NSLog(@"cancel animation");
    
    dispatch_async(dispatch_get_main_queue(), ^{
    for (CALayer *layer in self.view.layer.sublayers) {
        
            if ([layer isKindOfClass:[CAShapeLayer class]]) {
        [layer removeAllAnimations];
        [layer removeFromSuperlayer];
            }
        
    }
        });
    //[self.view.layer removeAllAnimations];
}

#pragma mark Server

- (void)p_sendLocation
{
    [self updateLocationManager];
    
    NSString *uid = [[NSUserDefaults standardUserDefaults] objectForKey:EAUID];
    NSLog(@"%@ (%lf; %lf) at %@", uid, self.parkingLocation.coordinate.latitude, self.parkingLocation.coordinate.longitude, [NSString stringWithDate:self.parkingDate]);
    
    NSString *msg = [NSString stringWithFormat:@"ID: %@; location: (%lf; %lf); time: %@", uid, self.parkingLocation.coordinate.latitude, self.parkingLocation.coordinate.longitude, [NSString stringWithDate:self.parkingDate]];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sent" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    
    //    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //    NSDictionary *parameters = @{@"foo": @"bar"};
    //    [manager POST:@"http://example.com/resources.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
    //        NSLog(@"JSON: %@", responseObject);
    //    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    //        NSLog(@"Request error: %@", error);
    //    }];
}

- (void)p_sendAlarm
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Спасибо" message:@"Ваше предупреждение отправлено." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

#pragma mark - CLLocation manager delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //NSLog(@"upd");
    self.parkingLocation = [locations lastObject];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"auth status: %i", status);
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kFacebookButton) {
        [self p_shareToFB];
    }
    else if (buttonIndex == kVkontakteButton) {
        [self p_shareToVK];
    }
}

#pragma mark - Social

- (void)showAlertWithError:(NSError*)error
{
    NSString *msg = @"";
    if (error) {
        msg = @"Не удалось опубликовать пост. Попробуйте позже.";
    }
    else {
        msg = @"Пост успешно опубликован.";
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Расскажи всем" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

#pragma mark FB

- (void)p_shareToFB
{
    FBSession *session = [[FBSession alloc] initWithPermissions:@[@"publish_actions", @"publish_stream"]];
    [FBSession setActiveSession:session];
    [session openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView
            completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                [self p_publishToFB];
            }];
}

- (void)p_publishToFB
{
    NSDictionary *params = @{@"link" : EAShareLink,
                             @"picture": @"",
                             @"name" : @"",
                             @"caption" : @"",
                             @"message" : EAShareMessage
                             };
    
    [FBRequestConnection startWithGraphPath:@"me/feed" parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self showAlertWithError:error];
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
        [self showAlertWithError:nil];
    } errorBlock:^(NSError *error) {
        NSLog(@"share to vk error: %@", error);
        [self showAlertWithError:error];
    }];
}

#pragma mark - VK sdk delegate

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {}
- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken {}
- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError {}
- (void)vkSdkShouldPresentViewController:(UIViewController *)controller
{
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken
{
    [self p_publishToVK];
}

@end

