//
//  EAMainViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 10/25/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAMainViewController.h"

#import <CoreLocation/CoreLocation.h>

@interface EAMainViewController () <CLLocationManagerDelegate>

@property CLLocationManager *locationManager;
@property CLLocation *parkingLocation;
@property NSDate *parkingDate;

#pragma mark - UI

@property (weak, nonatomic) IBOutlet UIButton *alarmButton;

- (IBAction)alarmButtonPressed;
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
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)viewWillDisappear:(BOOL)animated
{
    //[self.locationManager stopUpdatingLocation];
    [super viewWillDisappear:animated];
}

#pragma mark - Private API

- (void)p_sendLocation
{
    NSLog(@"location: (%lf; %lf) at %@", self.parkingLocation.coordinate.latitude, self.parkingLocation.coordinate.longitude, self.parkingDate);
}

#pragma mark - Button handlers

- (IBAction)alarmButtonPressed
{
    if (self.parkingLocation) {
        [self p_sendLocation];
    }
}

- (IBAction)parkingSwitchChanged:(UISwitch*)sender
{
    if (sender.isOn) {
        self.parkingLocation = self.locationManager.location;
        self.parkingDate = [NSDate date];
        self.alarmButton.enabled = YES;
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

