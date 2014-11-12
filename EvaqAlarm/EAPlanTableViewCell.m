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

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self.checkImageView setHighlighted:selected];

    
    [UIView animateWithDuration:0.3 animations:^{
//        self.leftOffsetConstraint.constant = selected ? 62 : 15;
//        [self.nameLabel layoutIfNeeded];
//        [self.selectedIndicatorView layoutIfNeeded];
    }];
    
    // Configure the view for the selected state
}

@end
