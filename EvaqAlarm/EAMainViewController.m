//
//  EAMainViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 10/25/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAMainViewController.h"
#import "EAConstants.h"
#import "EAPreferences.h"
#import "EAShareViewController.h"
#import "NSString+Date.h"

#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFNetworking.h>
#import <VK-ios-sdk/VKSdk.h>
#import <FacebookSDK/FacebookSDK.h>
#import <pop/POP.h>
#import <TSMessages/TSMessage.h>
#import "Reachability.h"

static const NSInteger kFacebookButton = 0;
static const NSInteger kVkontakteButton = 1;

static const NSTimeInterval kAlertAnimationDuration = 1.8;

static const NSInteger kStatusHeight = 20;
static const NSInteger kTopOffset = 45 + 6; // radius = 12, so we should offset r/2
static NSString *const kAnimationName = @"RadialAnimation";


static const NSTimeInterval kMainScreenTimeInterval = 0.5;
static const NSTimeInterval kTimeInterval = 0.2;
static const NSInteger kSharButtonSize = 44;


static NSString *const kShareVCStoryboardID = @"ShareVC";

@interface EAMainViewController () <CLLocationManagerDelegate, UIActionSheetDelegate, VKSdkDelegate, EAPreferencesDelegate, UIGestureRecognizerDelegate>
{
    BOOL isParking;
    BOOL isAlarmSent;
    BOOL isAnimationStarted;
    NSTimer *alarmTimer;
    
    BOOL mainScreenShown;
}
@property CLLocationManager *locationManager;
@property CLLocation *parkingLocation;
@property NSDate *parkingDate;
@property NSArray *alertButtonComponents;

@property (nonatomic) EAPreferences *preferences;

#pragma mark - UI

- (IBAction)tapOnView:(UITapGestureRecognizer *)sender;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleOffsetConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoSizeConstraint;

@property (weak, nonatomic) IBOutlet UILabel *disclaimerLabel;

#pragma mark Alarm button

@property (weak, nonatomic) IBOutlet UIView *alarmButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *alarmButton;

#pragma mark Share

@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *shareButtonWidthConstraint;

#pragma mark Hint

@property (weak, nonatomic) IBOutlet UILabel *hintLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hintOffsetConstraint;

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

    // prepare location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
//    // prepare the view
//    self.hintLabel.text = kParkingDisabledString;
//    self.alertButtonComponents = @[[self p_circle1WithColor:kGrayColor], [self p_circle2WithColor:kGrayColor], [self p_circle3WithColor:kGrayColor]];
//    for (CAShapeLayer* circle in self.alertButtonComponents) {
//        [self.view.layer addSublayer:circle];
//    }
    
    [self p_initialAnimationShow];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.locationManager stopUpdatingLocation];
    [super viewWillDisappear:animated];
}

- (EAPreferences *)preferences
{
    if (!_preferences) {
        _preferences = [[EAPreferences alloc] initWithDelegate:self];
    }
    return _preferences;
}

#pragma mark - Animations
#pragma mark Initial

- (void)p_initialAnimationShow
{
    // hide hint
    self.hintLabel.alpha = 0;
    self.hintOffsetConstraint.constant = - self.hintLabel.frame.size.height;
    [self.hintLabel layoutIfNeeded];
    
    // hide share button
    self.shareButtonWidthConstraint.constant = 0;
    [self.shareButton layoutIfNeeded];
    
    // title animation
    self.titleLabel.alpha = 0;
    self.titleOffsetConstraint.constant = - self.titleLabel.frame.size.height;
    [self.titleLabel layoutIfNeeded];
    [UIView animateWithDuration:kMainScreenTimeInterval animations:^{
        self.titleOffsetConstraint.constant = 60;
        [self.titleLabel layoutIfNeeded];
        self.titleLabel.alpha = 1;
    } completion:nil];
    
    // disclaimer animation
    self.disclaimerLabel.alpha = 0;
    //self.titleOffsetConstraint.constant = - self.titleLabel.frame.size.height;
    //[self.disclaimerLabel layoutIfNeeded];
    [UIView animateWithDuration:kMainScreenTimeInterval animations:^{
        self.titleOffsetConstraint.constant = 60;
        [self.disclaimerLabel layoutIfNeeded];
        self.disclaimerLabel.alpha = 1;
    } completion:nil];
}

- (void)p_initialAnimationHide
{
    [UIView animateWithDuration:kTimeInterval delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        // hide title
        self.titleLabel.alpha = 0;
        self.disclaimerLabel.alpha = 0;
        
        // bigger button
        self.logoSizeConstraint.constant = 200;
        self.logoImageView.image = [UIImage imageNamed:@"button_default"];
        
        [self.logoImageView layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self p_postAnimation];
    }];
}

- (void)p_postAnimation
{
    // share button animation
    CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = kMainScreenTimeInterval;
    [self.shareButton.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    // rotate share button
    [UIView animateWithDuration:kMainScreenTimeInterval delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.shareButtonWidthConstraint.constant = kSharButtonSize;
        [self.shareButton layoutIfNeeded];
    } completion:nil];
    
    // appearing hint label
    [UIView animateWithDuration:kMainScreenTimeInterval delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.hintOffsetConstraint.constant = 60;
        [self.hintLabel layoutIfNeeded];
        self.hintLabel.alpha = 1;
    } completion:^(BOOL finished) {
        self.alarmButton.enabled = YES;
    }];
}

#pragma mark Alarm

- (void)p_startAnimation
{
    EALog(@"start animation");
    isAnimationStarted = YES;
    isAlarmSent = NO;
    
    // Configure animation
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    drawAnimation.duration = kAlertAnimationDuration;
    drawAnimation.repeatCount = 1.0;
    drawAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    drawAnimation.toValue = [NSNumber numberWithFloat:1.0f];
    drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    NSArray *circles = @[[self p_circle1WithColor:kRedColor], [self p_circle2WithColor:kRedColor], [self p_circle3WithColor:kRedColor]];
    for (CAShapeLayer* circle in circles) {
        [self.view.layer addSublayer:circle];
        [circle addAnimation:drawAnimation forKey:kAnimationName];
    }
}

- (void)p_stopAnimation
{
    isAnimationStarted = NO;
    EALog(@"cancel animation");
    
    NSArray *layers = [self.view.layer.sublayers copy];
    for (CALayer *layer in layers) {
        if ([layer isKindOfClass:[CAShapeLayer class]] && [layer animationForKey:kAnimationName]) {
            [layer removeAllAnimations];
            [layer removeFromSuperlayer];
        }
    }
}

- (void)p_startPopAnimation
{
//    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
//    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.2f, 1.2f)];
//    scaleAnimation.repeatForever = YES;
//    [self.logoImageView.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSmallAnimation"];
}

#pragma mark - Button handlers

- (IBAction)shareButtonPressed
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Расскажи друзьям" delegate:self cancelButtonTitle:@"Отменить" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"VK", nil];
    [actionSheet showInView:[self.view window]];
}

- (IBAction)tap:(id)sender
{
    if (isAnimationStarted) {
        return;
    }
    //EALog(@"tap");
    
    BOOL willParking = !isParking;
    if (willParking && [self isReachable]) {
        [self p_setParked];
    }
    
    isParking = willParking;
    self.logoImageView.image = [UIImage imageNamed:isParking ? @"button_parked" : @"button_default"];
    self.hintLabel.text = isParking ? kParkingEnabledString : kParkingDisabledString;
}

- (IBAction)sendAlarm:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        isAlarmSent = YES;
        isAnimationStarted = NO;
        [self p_stopAnimation];
        [self p_sendAlarm];
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
}

- (IBAction)tapOnView:(UITapGestureRecognizer *)sender
{
    if (!mainScreenShown) {
        [self p_initialAnimationHide];
        mainScreenShown = YES;
    }
}

#pragma mark - Private API

- (BOOL)isReachable
{
//    NetworkStatus status = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
//    if (status == NotReachable) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:@"Ошибка при работе с сетью." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//        [alert show];
//        return NO;
//    }
//    if (!self.parkingLocation || !self.parkingLocation.coordinate.latitude || !self.parkingLocation.coordinate.longitude) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:@"Включите доступ к геолокации." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//        [alert show];
//        return NO;
//    }
    
    return YES;
}

#pragma mark Elements

- (CAShapeLayer*)p_circle1WithColor:(UIColor*)color
{
    int lineWidth = 11;
    int radius = 100 - lineWidth/2;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius].CGPath;
    circle.position = CGPointMake(CGRectGetMidX(self.view.frame)-radius, kTopOffset + kStatusHeight + 14.5);
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.strokeColor = color.CGColor;
    circle.lineWidth = lineWidth;
    
    return circle;
}

- (CAShapeLayer*)p_circle2WithColor:(UIColor*)color
{
    int lineWidth = 15;
    int radius = 82 - lineWidth/2;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius].CGPath;
    circle.position = CGPointMake(CGRectGetMidX(self.view.frame)-radius, kTopOffset + kStatusHeight + 19 + 15);
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.strokeColor = color.CGColor;
    circle.lineWidth = lineWidth;
    
    return circle;
}

- (CAShapeLayer*)p_circle3WithColor:(UIColor*)color
{
    int lineWidth = 60;
    int radius = 60 - lineWidth/2;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius].CGPath;
    circle.position = CGPointMake(CGRectGetMidX(self.view.frame)-radius, kTopOffset + kStatusHeight + 64 + 15);
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.strokeColor = color.CGColor;
    circle.lineWidth = lineWidth;
    
    return circle;
}

#pragma mark Server API

- (void)p_setParked
{
    //self.parkingLocation = self.locationManager.location;
    NSString *uid = [[NSUserDefaults standardUserDefaults] objectForKey:EAPushToken];
    if (!uid) {
        uid = @"";
    }

    if (!self.parkingLocation) {
        NSString *msg = [NSString stringWithFormat:@"ID: %@; location: (%lf; %lf); time: %@", uid, self.parkingLocation.coordinate.latitude, self.parkingLocation.coordinate.longitude, [NSString stringWithDate:self.parkingDate]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sent" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSDictionary *parameters = @{@"auto" : @{@"deviceId": uid,
                                             @"lat" : @(self.parkingLocation.coordinate.latitude),
                                             @"lon" : @(self.parkingLocation.coordinate.longitude)
                                            }
                                };
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:EAURLSetParked parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [TSMessage showNotificationWithTitle:@"Парковка успешно активирована." type:TSMessageNotificationTypeSuccess];
        [self.preferences incerementParkingCount];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        EALog(@"Set parked error: %@", error);
        [TSMessage showNotificationWithTitle:@"Не удалось активировать парковку." type:TSMessageNotificationTypeError];
    }];
}

- (void)p_clearParking
{
    NSDictionary *parameters = @{@"deviceId": [[NSUserDefaults standardUserDefaults] objectForKey:EAUID]};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:EAURLClearParking parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        EALog(@"Clear parking: %@", responseObject);
        [TSMessage showNotificationWithTitle:@"Парковка успешно деактивирована." type:TSMessageNotificationTypeError];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        EALog(@"Clear parking error: %@", error);
        [TSMessage showNotificationWithTitle:@"Не удалось деактивировать парковку." type:TSMessageNotificationTypeError];
    }];
}

- (void)p_sendAlarm
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Спасибо" message:@"Ваше предупреждение будет отправлено." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    
    NSString *uid = [[NSUserDefaults standardUserDefaults] objectForKey:EAPushToken];
    if (!uid) {
        uid = @"";
    }
    
    NSDictionary *parameters = @{@"auto" : @{@"deviceId": uid,
                                             @"lat" : @(self.parkingLocation.coordinate.latitude),
                                             @"lon" : @(self.parkingLocation.coordinate.longitude)
                                             }
                                 };
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:EAURLSetAlarm parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        EALog(@"Set alarm done");
        [TSMessage showNotificationWithTitle:@"Тревога отправлена." type:TSMessageNotificationTypeSuccess];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        EALog(@"Set alarm error: %@", error);
        [TSMessage showNotificationWithTitle:@"Не удалось отправить тревогу." type:TSMessageNotificationTypeError];
    }];
}

#pragma mark - Social

- (void)p_showAlertWithError:(NSError*)error
{
    if (error) {
        [TSMessage showNotificationWithTitle:@"Не удалось опубликовать пост. Попробуйте позже." type:TSMessageNotificationTypeError];
    }
    else {
        [TSMessage showNotificationWithTitle:@"Пост успешно опубликован." type:TSMessageNotificationTypeSuccess];
    }
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
        [self p_showAlertWithError:error];
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
        EALog(@"share to vk done");
        [self p_showAlertWithError:nil];
    } errorBlock:^(NSError *error) {
        EALog(@"share to vk error: %@", error);
        [self p_showAlertWithError:error];
    }];
}

#pragma mark - CLLocation manager delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //EALog(@"upd");
    self.parkingLocation = [locations lastObject];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    EALog(@"location error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    EALog(@"auth status: %i", status);
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

#pragma mark - EAPreferences delegate

- (void)shouldPresentSharingView
{
    EAShareViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:kShareVCStoryboardID];
    vc.sharing = YES;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)shouldPresentFeedbackView
{
    EAShareViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:kShareVCStoryboardID];
    vc.sharing = NO;
    [self presentViewController:vc animated:YES completion:nil];
}

@end

