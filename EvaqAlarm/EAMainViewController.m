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

#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFNetworking.h>
#import <VK-ios-sdk/VKSdk.h>
#import <FacebookSDK/FacebookSDK.h>
#import <pop/POP.h>
#import <TSMessages/TSMessage.h>
#import <VKActivity/VKActivity.h>
#import "Reachability.h"
#import <YandexMobileMetrica/YandexMobileMetrica.h>
@import AudioToolbox;
@import MapKit;

typedef NS_ENUM(NSUInteger, EAStatus) {
    EAStatusNotParked,
    EAStatusParked,
    EAStatusAlarmReceived,
    EAStatusAlarmSkip
};

static const NSInteger kFacebookButton = 0;
static const NSInteger kVkontakteButton = 1;

static const NSTimeInterval kAlertAnimationDuration = 1.8;

static const NSInteger kStatusHeight = 20;
static const NSInteger kTopOffset = 45 + 6; // radius = 12, so we should offset r/2
static NSString *const kAnimationName = @"RadialAnimation";
static NSString *const kPopAnimation = @"PopAnimation";

static const NSTimeInterval kMainScreenTimeInterval = 0.5;
static const NSTimeInterval kTimeInterval = 0.2;
static const NSInteger kMapZoom = 0.05;

static NSString *const kShareVCStoryboardID = @"ShareVC";
static NSString *const kSenderId = @"senderId";

@interface EAMainViewController () <CLLocationManagerDelegate, UIActionSheetDelegate, VKSdkDelegate, EAPreferencesDelegate, UIGestureRecognizerDelegate, MKMapViewDelegate>
{
    BOOL isParking;
    BOOL isAlarmSent;
    BOOL isAnimationStarted;
    BOOL isDisclaimerSkipped;
    NSTimer *alarmTimer;
    POPSpringAnimation *scaleAnimation;
    UIVisualEffectView *permissionsVisualEffectView;
    UIView *permissionsView;
    CLLocationCoordinate2D currentCoordinates;
    
    SystemSoundID alarmSoundID;
    
    BOOL mainScreenShown;
}
@property CLLocationManager *locationManager;
@property CLLocation *parkingLocation;
@property NSDate *parkingDate;
@property NSArray *alertButtonComponents;
@property NSString *alarmSenderUid;

@property (nonatomic) EAPreferences *preferences;

#pragma mark - UI

- (IBAction)praiseAlarmButtonPressed;
- (IBAction)petitionAlarmButtonPressed;
@property (weak, nonatomic) IBOutlet UIButton *praiseAlarmButton;
@property (weak, nonatomic) IBOutlet UIButton *petitionAlarmButton;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;


- (IBAction)tapOnView:(UITapGestureRecognizer *)sender;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleOffsetConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoSizeConstraint;

@property (weak, nonatomic) IBOutlet UILabel *disclaimerLabel;

#pragma mark Alarm button

@property (weak, nonatomic) IBOutlet UIView *alarmButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *alarmButton;

#pragma mark Action View
@property (weak, nonatomic) IBOutlet UIView *actionView;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *qrButton;

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
    self.preferences = [[EAPreferences alloc] initWithDelegate:self];
    [VKSdk initializeWithDelegate:self andAppId:EAVKAppKey];
    [VKSdk wakeUpSession];
    
    // prepare location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_checkPermissions) name:EACheckPermissionsNotification object:nil];
    [self p_checkPermissions];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveAlarm:) name:EAReceiveAlarmNotification object:nil];
    isParking = [[NSUserDefaults standardUserDefaults] boolForKey:EAParkedNow];
    self.hintLabel.text = LOC(isParking ? @"Instruction: tap to off" : @"Instruction: tap to on");
    
    [self p_initialAnimationShow];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.locationManager stopUpdatingLocation];
    [super viewWillDisappear:animated];
}

#pragma mark - Server API

- (void)p_setParked
{
    NSDictionary *parameters = @{@"auto" : @{@"deviceId": [EAPreferences uid],
                                             @"lat" : @(self.parkingLocation.coordinate.latitude),
                                             @"lon" : @(self.parkingLocation.coordinate.longitude)
                                             }
                                 };
    self.alarmButton.enabled = NO;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:EAURLSetParked parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self p_statusChanged:EAStatusParked];
        
        self.alarmButton.enabled = YES;
        EALog(@"Set parking done");
        [YMMYandexMetrica reportEvent:@"Parking success" onFailure:nil];
        
        [self.preferences incerementParkingCount];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:EAParkedNow];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [TSMessage showNotificationWithTitle:LOC(@"Parked mode on") type:TSMessageNotificationTypeSuccess];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.alarmButton.enabled = YES;
        [self invertParkingState];
        [self p_statusChanged:EAStatusNotParked];
        [YMMYandexMetrica reportEvent:@"Server error on send parking" onFailure:nil];
        
        EALog(@"Set parked error: %@", error);
        [TSMessage showNotificationWithTitle:LOC(@"Can't activate parked mode") type:TSMessageNotificationTypeError];
    }];
}

- (void)p_clearParking
{
    NSDictionary *parameters = @{@"auto" : @{@"deviceId": [EAPreferences uid]}};
    
    self.alarmButton.enabled = NO;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:EAURLClearParking parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self p_statusChanged:EAStatusNotParked];
        
        self.alarmButton.enabled = YES;
        EALog(@"Clear parking done");
        [YMMYandexMetrica reportEvent:@"Parking cancelled" onFailure:nil];
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:EAParkedNow];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [TSMessage showNotificationWithTitle:LOC(@"Parking mode off") type:TSMessageNotificationTypeSuccess];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self p_statusChanged:EAStatusParked];
        
        self.alarmButton.enabled = YES;
        [self invertParkingState];
        
        EALog(@"Clear parking error: %@", error);
        [YMMYandexMetrica reportEvent:@"Server error on parking cancell" onFailure:nil];
        [TSMessage showNotificationWithTitle:LOC(@"Can't deactivate parked mode") type:TSMessageNotificationTypeError];
    }];
}

- (void)invertParkingState
{
    isParking = !isParking;
    self.logoImageView.image = [UIImage imageNamed:isParking ? @"button_parked" : @"button_default"];
}

- (void)p_sendAlarm
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOC(@"Thank you") message:LOC(@"Alert will send") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    
    NSDictionary *parameters = @{@"auto" : @{@"deviceId": [EAPreferences uid],
                                             @"lat" : @(self.parkingLocation.coordinate.latitude),
                                             @"lon" : @(self.parkingLocation.coordinate.longitude)
                                             }
                                 };
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:EAURLSetAlarm parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        EALog(@"Set alarm done");
        [YMMYandexMetrica reportEvent:@"Alarm success" onFailure:nil];
        [TSMessage showNotificationWithTitle:LOC(@"Alarm signal sent") type:TSMessageNotificationTypeSuccess];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        EALog(@"Set alarm error: %@", error);
        [YMMYandexMetrica reportEvent:@"Server error on send alarm" onFailure:nil];
        [TSMessage showNotificationWithTitle:LOC(@"Can't send alarm signal") type:TSMessageNotificationTypeError];
    }];
}

- (void)praiseAlarmSender:(BOOL)praise
{
    NSDictionary *parameters = @{@"auto" : @{@"deviceId": self.alarmSenderUid}};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:praise ? EAURLPraise : EAURLPetition parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        EALog(@"%@ done", praise ? @"Praise" : @"Petition");
        
        [TSMessage showNotificationWithTitle:LOC(@"Rate sent") type:TSMessageNotificationTypeSuccess];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        EALog(@"%@ error: %@", praise ? @"Praise" : @"Petition", error);
        [TSMessage showNotificationWithTitle:LOC(@"Error sending rating") type:TSMessageNotificationTypeError];
    }];
    [self p_statusChanged:EAStatusAlarmSkip];
}

#pragma mark - Animations
#pragma mark Initial

- (void)p_initialAnimationShow
{
    // title animation
    self.titleLabel.alpha = 0;
    self.titleOffsetConstraint.constant = - self.titleLabel.frame.size.height;
    [self.titleLabel layoutIfNeeded];
    [UIView animateWithDuration:kMainScreenTimeInterval animations:^{
        self.titleOffsetConstraint.constant = 60;
        [self.titleLabel layoutIfNeeded];
        self.hintLabel.alpha = 1;
    } completion:nil];
    
    // disclaimer animation
    self.disclaimerLabel.alpha = 0;
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
        self.logoImageView.image = [UIImage imageNamed:isParking ? @"button_parked" : @"button_default"];
        [self.logoImageView layoutIfNeeded];
        self.logoImageView.alpha = 0.5;
    } completion:^(BOOL finished) {
        [self p_postAnimation];
        isDisclaimerSkipped = YES;
    }];
}

- (void)p_postAnimation
{
//    // share button animation
//    CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
//    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
//    rotationAnimation.duration = kMainScreenTimeInterval;
//    [self.shareButton.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
//    
//    // rotate share button
//    [UIView animateWithDuration:kMainScreenTimeInterval delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        self.shareButtonWidthConstraint.constant = kShareButtonSize;
//        [self.shareButton layoutIfNeeded];
//    } completion:nil];
    
    // appearing hint label
    [UIView animateWithDuration:kMainScreenTimeInterval delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        self.hintOffsetConstraint.constant = 60;
//        [self.hintLabel layoutIfNeeded];
        self.actionView.alpha = 1;
        self.mapView.alpha = 1;
        [self p_statusChanged:isParking ? EAStatusParked : EAStatusNotParked];
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
        //[self.view.layer addSublayer:circle];
        [self.alarmButtonContainer.layer addSublayer:circle];
        [circle addAnimation:drawAnimation forKey:kAnimationName];
    }
}

- (void)p_stopAnimation
{
    isAnimationStarted = NO;
    EALog(@"Cancel animation");
    
    NSArray *layers = [self.alarmButtonContainer.layer.sublayers copy];
    for (CALayer *layer in layers) {
        if ([layer isKindOfClass:[CAShapeLayer class]] && [layer animationForKey:kAnimationName]) {
            [layer removeAllAnimations];
            [layer removeFromSuperlayer];
        }
    }
}

- (void)p_startPopAnimation
{
    self.alarmButton.enabled = NO;
    self.hintLabel.text = LOC(@"Rate alarm");
    self.logoImageView.image = [UIImage imageNamed:@"button_alarm"];
    self.petitionAlarmButton.hidden = self.praiseAlarmButton.hidden = NO;

    if (!scaleAnimation) {
        scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    }
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.2f, 1.2f)];
    scaleAnimation.repeatForever = YES;
    [self.logoImageView.layer pop_addAnimation:scaleAnimation forKey:kPopAnimation];
}

- (void)p_stopPopAnimation
{
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.0f, 1.0f)];
    scaleAnimation.repeatForever = NO;

    self.alarmButton.enabled = YES;
    self.hintLabel.text = LOC(isParking ? @"Instruction: tap to off" : @"Instruction: tap to on");
    self.logoImageView.image = [UIImage imageNamed:isParking ? @"button_parked" : @"button_default"];
    self.petitionAlarmButton.hidden = self.praiseAlarmButton.hidden = YES;
    
    AudioServicesDisposeSystemSoundID(alarmSoundID);
}

#pragma mark - Button handlers

- (IBAction)shareButtonPressed
{
    [YMMYandexMetrica reportEvent:@"Share button clicked" onFailure:nil];
    
    NSArray *items = @[LOC(@"Shared text"), [NSURL URLWithString:EAShareLink]];
    NSArray *activities = @[[[VKActivity alloc] init]];
    
    UIActivityViewController* activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:activities];
    if ([activityViewController respondsToSelector:@selector(popoverPresentationController)]) {
        UIPopoverPresentationController *presentationController = [activityViewController popoverPresentationController];
        presentationController.sourceView = self.shareButton;
    }
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)tap:(id)sender
{
    if (isAnimationStarted) {
        return;
    }
    
    isParking = !isParking;
    if (isParking) {
        [self p_setParked];
    }
    else {
        [self p_clearParking];
    }
    
    self.logoImageView.image = [UIImage imageNamed:isParking ? @"button_parked" : @"button_default"];
    self.hintLabel.text = LOC(isParking ? @"Instruction: tap to off" : @"Instruction: tap to on");
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

- (IBAction)startAnimation:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self p_startAnimation];
    }
    else if (sender.state == UIGestureRecognizerStateEnded && !isAlarmSent) {
        [self p_stopAnimation];
    }
}

- (IBAction)tapOnView:(UITapGestureRecognizer *)sender
{
    if (!mainScreenShown  && [sender.view isEqual:self.view]) {
        [YMMYandexMetrica reportEvent:@"Skip splash clicked" onFailure:nil];
        
        [self p_initialAnimationHide];
        mainScreenShown = YES;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]];
}

- (IBAction)praiseAlarmButtonPressed
{
    [self p_stopPopAnimation];
    [self praiseAlarmSender:YES];
}

- (IBAction)petitionAlarmButtonPressed
{
    [self p_stopPopAnimation];
    [self praiseAlarmSender:NO];
}

#pragma mark - Private API

- (void)p_checkPermissions
{
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    BOOL shouldShowView = NO; //![EAPreferences fullAccessEnabled];
    
    if (shouldShowView) {
        if (![EAPreferences isPushEnabled]) {
            [YMMYandexMetrica reportEvent:@"Push notifications disabled" onFailure:nil];
        }
        if (![EAPreferences isLocationEnabled]) {
            [YMMYandexMetrica reportEvent:@"GPS disabled" onFailure:nil];
        }
        
        if (![permissionsView superview]) {
            permissionsView = [[NSBundle mainBundle] loadNibNamed:@"EAPermissionsView" owner:self options:nil][0];
            permissionsView.frame = self.view.frame;
            
            if (IS_OS_8_OR_LATER) {
                permissionsView.backgroundColor = [UIColor clearColor];
                
                UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                permissionsVisualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                permissionsVisualEffectView.frame = self.view.frame;
                [self.view addSubview:permissionsVisualEffectView];
            }
            [self.view addSubview:permissionsView];
        }
    }
    else {
        [permissionsView removeFromSuperview];
        if (IS_OS_8_OR_LATER) {
            [permissionsVisualEffectView removeFromSuperview];
        }
    }
    self.view.userInteractionEnabled = !shouldShowView;
}

- (void)receiveAlarm:(NSNotification*)notification
{
    EALog(@"Push: %@", notification.userInfo);
    [self p_statusChanged:EAStatusAlarmReceived];
    
    BOOL playSound = [notification.userInfo[@"playSound"] boolValue];
    if (playSound) {
        [self p_playAlarmSound];
    }
        
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!isDisclaimerSkipped) {
            [self p_initialAnimationHide];
        }

        self.alarmSenderUid = notification.userInfo[kSenderId];
        [self p_startPopAnimation];
    });
}

- (void)p_playAlarmSound
{
    CFStringRef state;
    UInt32 propertySize = sizeof(CFStringRef);
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &state);
    BOOL shouldPlay = CFStringGetLength(state) > 0 ;
    
    if (shouldPlay) {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"alarm" ofType:@"wav"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &alarmSoundID);
        AudioServicesPlaySystemSound (alarmSoundID);
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
}

- (BOOL)p_isReachable
{
    return [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable;
}

//-(UIStatusBarStyle)preferredStatusBarStyle{
//    return isParking ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
//}

- (void)p_statusChanged:(EAStatus)status
{
    UIColor *bgColor;
    
    switch (status) {
        case EAStatusNotParked:
            bgColor = [UIColor whiteColor];
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
            break;
        case EAStatusParked:
            bgColor = kGreenColor;
            break;
        case EAStatusAlarmReceived:
            [self p_startPopAnimation];
            bgColor = kRedColor;
            break;
        case EAStatusAlarmSkip:
            [self p_stopPopAnimation];
            bgColor = kGreenColor;
            break;
    }
    self.view.backgroundColor = bgColor;
    
    // change style for changed bg color
    [[UIApplication sharedApplication] setStatusBarStyle:status != EAStatusNotParked ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
    [self.shareButton setImage:[UIImage imageNamed:status != EAStatusNotParked ? @"button_share_highlighted" : @"button_share_default"] forState:UIControlStateNormal];
    [self.cameraButton setImage:[UIImage imageNamed:status != EAStatusNotParked ? @"button_camera_highlighted" : @"button_camera_default"] forState:UIControlStateNormal];
    [self.qrButton setImage:[UIImage imageNamed:status != EAStatusNotParked ? @"button_qr_highlighted" : @"button_qr_default"] forState:UIControlStateNormal];
    self.hintLabel.textColor = status != EAStatusNotParked ? [UIColor whiteColor] : kDarkGrayColor;
}

#pragma mark - Design elements

- (CAShapeLayer*)p_circle1WithColor:(UIColor*)color
{
    int lineWidth = 11;
    int radius = 100 - lineWidth/2;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius].CGPath;
    circle.position = CGPointMake(CGRectGetMidX(self.alarmButtonContainer.bounds)-radius, CGRectGetMidY(self.alarmButtonContainer.bounds)-radius);
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
    circle.position = CGPointMake(CGRectGetMidX(self.alarmButtonContainer.bounds)-radius, CGRectGetMidY(self.alarmButtonContainer.bounds)-radius);
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
    circle.position = CGPointMake(CGRectGetMidX(self.alarmButtonContainer.bounds)-radius, CGRectGetMidY(self.alarmButtonContainer.bounds)-radius);
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.strokeColor = color.CGColor;
    circle.lineWidth = lineWidth;
    
    return circle;
}

#pragma mark - Social

- (void)p_showAlertWithError:(NSError*)error
{
    if (error) {
        [TSMessage showNotificationWithTitle:LOC(@"Can't send post") type:TSMessageNotificationTypeError];
    }
    else {
        [TSMessage showNotificationWithTitle:LOC(@"Post submitted") type:TSMessageNotificationTypeSuccess];
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
                             @"message" : LOC(@"Shared text")
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
    NSDictionary *parameters = @{@"message" : LOC(@"Shared text"), @"attachments:" : EAShareLink};
    VKRequest *request = [[VKApi wall] post:parameters];
    [request executeWithResultBlock:^(VKResponse *response) {
        EALog(@"Share to vk done");
        [self p_showAlertWithError:nil];
    } errorBlock:^(NSError *error) {
        EALog(@"Share to vk error: %@", error);
        [self p_showAlertWithError:error];
    }];
}

#pragma mark - CLLocation manager delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.parkingLocation = [locations lastObject];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    EALog(@"Location error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    EALog(@"Auth status: %i", status);
    [self p_checkPermissions];
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

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    //currentCoordinates = [mapView convertPoint:self.alarmButton.center toCoordinateFromView:self.alarmButton];
    currentCoordinates = [mapView centerCoordinate];
    
    [mapView removeAnnotations:mapView.annotations];
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:currentCoordinates];
    [mapView addAnnotation:annotation];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = mapView.userLocation.coordinate;
    mapRegion.span = MKCoordinateSpanMake(kMapZoom, kMapZoom);
    [mapView setRegion:mapRegion animated: YES];
}

//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
//{
//    
//}

@end

