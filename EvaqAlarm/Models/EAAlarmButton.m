//
//  EAAlarmButton.m
//  Alarm Button
//
//  Created by Sergey Butenko on 1/30/15.
//  Copyright (c) 2015 Serhii Butenko. All rights reserved.
//

#import "EAAlarmButton.h"
#import <pop/POP.h>

static NSString *const kPopAnimation = @"PopAnimation";
static NSString *const kFillAnimation = @"FillAnimation";

#define kFillColor [UIColor clearColor].CGColor
#define kParkedColor [UIColor colorWithRed:169/255.0 green:219/255.0 blue:72/255.0 alpha:1]
#define kAlarmColor [UIColor colorWithRed:255/255.0 green:59/255.0 blue:48/255.0 alpha:1]
#define kDefaultColor [UIColor colorWithRed:220/255.0 green:221/255.0 blue:221/255.0 alpha:1]

static const NSTimeInterval kAlertAnimationDuration = 1.8;

@interface EAAlarmButton () <UIGestureRecognizerDelegate>
{
    POPSpringAnimation *scaleAnimation;
}

@end

@implementation EAAlarmButton

- (void)startAlarm
{
    if (!scaleAnimation) {
        scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    }
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.2f, 1.2f)];
    scaleAnimation.repeatForever = YES;
    [self.layer pop_addAnimation:scaleAnimation forKey:kPopAnimation];
}

- (void)stopAlarm
{
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.0f, 1.0f)];
    scaleAnimation.repeatForever = NO;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    UIImageView *img = [[UIImageView alloc] initWithFrame:self.bounds];
    img.image = [UIImage imageNamed:@"button_alarm"];
    //[self addSubview:img];
    
    [self p_drawCircles];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hold:)];
    [self addGestureRecognizer:tap];
    [self addGestureRecognizer:longPress];
}

- (void)p_drawCircles
{
    [self.layer addSublayer:[self p_circle1WithColor:kDefaultColor]];
    [self.layer addSublayer:[self p_circle2WithColor:kDefaultColor]];
    [self.layer addSublayer:[self p_circle3WithColor:kDefaultColor]];
}

- (CAShapeLayer*)p_circle1WithColor:(UIColor*)strokeColor
{
    int lineWidth = self.bounds.size.width/2 * 0.12;
    int radius = self.bounds.size.width/2 * 1 - lineWidth/2;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius].CGPath;
    circle.position = CGPointMake(CGRectGetMidX(self.bounds)-radius, CGRectGetMidY(self.bounds)-radius);
    circle.strokeColor = strokeColor.CGColor;
    circle.fillColor = kFillColor;
    circle.lineWidth = lineWidth;
    
    return circle;
}

- (CAShapeLayer*)p_circle2WithColor:(UIColor*)strokeColor
{
    int lineWidth = self.bounds.size.width/2 * 0.15;
    int radius = self.bounds.size.width/2 * 0.82 - lineWidth/2;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius].CGPath;
    circle.position = CGPointMake(CGRectGetMidX(self.bounds)-radius, CGRectGetMidY(self.bounds)-radius);
    circle.strokeColor = strokeColor.CGColor;
    circle.fillColor = kFillColor;
    circle.lineWidth = lineWidth;
    
    return circle;
}

- (CAShapeLayer*)p_circle3WithColor:(UIColor*)strokeColor
{
    int lineWidth = self.bounds.size.width/2 * 0.6;
    int radius = lineWidth / 2;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, lineWidth, lineWidth)].CGPath;
    circle.position = CGPointMake(CGRectGetMidX(self.bounds)-radius, CGRectGetMidY(self.bounds)-radius);
    circle.strokeColor = strokeColor.CGColor;
    circle.fillColor = kFillColor;
    circle.lineWidth = lineWidth;
    circle.affineTransform = CGAffineTransformRotate(circle.affineTransform, M_PI_2);

    return circle;
}

#pragma mark - Gestures

- (void)tap:(UITapGestureRecognizer*)sender
{
//    if (isAnimationStarted) {
//        return;
//    }
//    
//    isParking = !isParking;
//    if (isParking) {
//        [self p_setParked];
//    }
//    else {
//        [self p_clearParking];
//    }
//    
//    self.logoImageView.image = [UIImage imageNamed:isParking ? @"button_parked" : @"button_default"];
//    self.hintLabel.text = LOC(isParking ? @"Instruction: tap to off" : @"Instruction: tap to on");
}

- (void)hold:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self p_startAnimation];
    }
    else if (sender.state == UIGestureRecognizerStateEnded) {
        [self p_stopAnimation];
    }
}

- (IBAction)sendAlarm:(UILongPressGestureRecognizer *)sender
{
//    if (sender.state == UIGestureRecognizerStateBegan) {
//        isAlarmSent = YES;
//        isAnimationStarted = NO;
//        [self p_stopAnimation];
//        [self p_sendAlarm];
//    }
}

- (IBAction)startAnimation:(UILongPressGestureRecognizer*)sender
{
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]];
}

- (void)p_startAnimation
{
    // Configure animation
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    drawAnimation.duration = kAlertAnimationDuration;
    drawAnimation.repeatCount = 1.0;
    drawAnimation.fromValue = @0.0f;
    drawAnimation.toValue = @1.0f;
    drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    NSArray *circles = @[[self p_circle1WithColor:kAlarmColor], [self p_circle2WithColor:kAlarmColor], [self p_circle3WithColor:kAlarmColor]];
    for (CAShapeLayer* circle in circles) {
        [self.layer addSublayer:circle];
        [circle addAnimation:drawAnimation forKey:kFillAnimation];
    }
}

- (void)p_stopAnimation
{
    NSArray *layers = [self.layer.sublayers copy];
    for (CALayer *layer in layers) {
        if ([layer isKindOfClass:[CAShapeLayer class]] && [layer animationForKey:kFillAnimation]) {
            [layer removeAllAnimations];
            [layer removeFromSuperlayer];
        }
    }
}


@end
