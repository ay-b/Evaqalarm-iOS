//
//  EAPlanTableViewCell.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/12/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EAPlanTableViewCell.h"

@interface EAPlanTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;

@end

@implementation EAPlanTableViewCell

- (void)awakeFromNib
{
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self.checkImageView setHighlighted:selected];
}

@end
