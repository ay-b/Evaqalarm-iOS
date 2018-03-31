//
//  EAConfirmButton.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/18/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAConfirmButton.h"

@implementation EAConfirmButton

- (void)drawRect:(CGRect)rect
{
    UIImage *image = [UIImage imageNamed:@"button"];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(20, 30, 20, 30)];
    [self setBackgroundImage:image forState:UIControlStateNormal];
}

@end
