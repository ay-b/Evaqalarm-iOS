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

#define kStrokeColor [UIColor colorWithRed:1 green:0 blue:0 alpha:1].CGColor
#define kFillColor [UIColor clearColor].CGColor

@interface EAAlarmButton ()
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
    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:<#(id)#> action:@selector(<#selector#>)];
}

- (void)p_drawCircles
{
    [self.layer addSublayer:[self p_circle1]];
    [self.layer addSublayer:[self p_circle2]];
    [self.layer addSublayer:[self p_circle3]];
}

- (CAShapeLayer*)p_circle1
{
    int lineWidth = self.bounds.size.width/2 * 0.12;
    int radius = self.bounds.size.width/2 * 1 - lineWidth/2;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius].CGPath;
    circle.position = CGPointMake(CGRectGetMidX(self.bounds)-radius, CGRectGetMidY(self.bounds)-radius);
    circle.strokeColor = kStrokeColor;
    circle.fillColor = kFillColor;
    circle.lineWidth = lineWidth;
    
    return circle;
}

- (CAShapeLayer*)p_circle2
{
    int lineWidth = self.bounds.size.width/2 * 0.15;
    int radius = self.bounds.size.width/2 * 0.82 - lineWidth/2;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius].CGPath;
    circle.position = CGPointMake(CGRectGetMidX(self.bounds)-radius, CGRectGetMidY(self.bounds)-radius);
    circle.strokeColor = kStrokeColor;
    circle.fillColor = kFillColor;
    circle.lineWidth = lineWidth;
    
    return circle;
}

- (CAShapeLayer*)p_circle3
{
    int lineWidth = self.bounds.size.width/2 * 0.6;
    int radius = lineWidth / 2;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, lineWidth, lineWidth)].CGPath;
    circle.position = CGPointMake(CGRectGetMidX(self.bounds)-radius, CGRectGetMidY(self.bounds)-radius);
    circle.strokeColor = kStrokeColor;
    circle.fillColor = kFillColor;
    circle.lineWidth = lineWidth;
    
    return circle;
}

@end
