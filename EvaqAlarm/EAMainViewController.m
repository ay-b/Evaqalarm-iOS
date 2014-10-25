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

@interface EAMainViewController () <CLLocationManagerDelegate, UIActionSheetDelegate>

@property CLLocationManager *locationManager;
@property CLLocation *parkingLocation;
@property NSDate *parkingDate;

#pragma mark - UI

@property (weak, nonatomic) IBOutlet UIButton *alarmButton;

- (IBAction)alarmButtonPressed:(UILongPressGestureRecognizer*)gesture;
- (IBAction)parkingSwitchChanged:(UISwitch*)sender;

@end

@implementation EAMainViewController

#pragma mark - View life cycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self.locationManager startUpdatingLocation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    else {
        [self.locationManager startUpdatingLocation];
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.locationManager stopUpdatingLocation];
    [super viewWillDisappear:animated];
}

#pragma mark - Private API

- (void)p_sendLocation
{
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

#pragma mark - Button handlers

- (IBAction)alarmButtonPressed:(UILongPressGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self p_sendAlarm];
    }
}

- (IBAction)parkingSwitchChanged:(UISwitch*)sender
{
    if (sender.isOn) {
        self.parkingLocation = self.locationManager.location;
        self.parkingDate = [NSDate date];
        self.alarmButton.enabled = YES;
        [self p_sendLocation];
    }
    else {
        self.parkingLocation = nil;
        self.alarmButton.enabled = NO;
    }
}

#pragma mark - CLLocation manager delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //NSLog(@"upd");
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"auth status: %i", status);
}

@end

