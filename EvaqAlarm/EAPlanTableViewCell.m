//
//  EAPlanTableViewCell.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/12/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAPlanTableViewCell.h"
#import "EASubscriptionPlan.h"

@interface EAPlanTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;

@end

@implementation EAPlanTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self.checkImageView setHighlighted:selected];
}

- (void)configureWithPlan:(EASubscriptionPlan*)plan
{
    self.durationLabel.text = plan.duration;
    self.priceLabel.text = plan.price;
}

@end
