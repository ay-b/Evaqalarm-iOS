//
//  EASubscribeViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/12/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EASubscribeViewController.h"
#import "EAPlanTableViewCell.h"

#import <RMStore.h>
#import <MKStoreKit/MKStoreManager.h>

static NSString *const kCellIndentifier = @"PlanCell";
static const NSTimeInterval kAnimationDuration = 0.3;

@interface EASubscribeViewController () <UITableViewDataSource, UITableViewDelegate>

@property NSArray *plans;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *purchaseButton;

- (IBAction)purchaseButtonPressed:(id)sender;

@end

@implementation EASubscribeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    
    self.plans = @[@{@"duration" : @"1 месяц",
                     @"price" : @"50",
                     @"uid" : @"me.speind.evaqalarm.subscription1"},
                   @{@"duration" : @"6 месяцев",
                     @"price" : @"250",
                     @"uid" : @"me.speind.evaqalarm.subscription6"},
                   @{@"duration" : @"12 месяцев",
                     @"price" : @"450",
                     @"uid" : @"me.speind.evaqalarm.subscription12"}];
    
}

- (IBAction)purchaseButtonPressed:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSDictionary *plan = self.plans[indexPath.row];
    NSString *uid = plan[@"uid"];
    
    [[RMStore defaultStore] addPayment:uid success:^(SKPaymentTransaction *transaction) {
        NSLog(@"Product purchased");
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        NSLog(@"Something went wrong");
    }];
}

- (void)p_purchaseBought
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)p_updateView
{
    NSArray *selectedCells = [self.tableView indexPathsForSelectedRows];
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.purchaseButton.enabled = selectedCells.count > 0;
        self.purchaseButton.alpha = selectedCells.count > 0 ? 1 : 0;
    }];
}

#pragma mark - UITableView delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.plans.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EAPlanTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIndentifier forIndexPath:indexPath];
    
    NSDictionary *plan = self.plans[indexPath.row];
    cell.durationLabel.text = plan[@"duration"];
    cell.priceLabel.text = plan[@"price"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self p_updateView];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    if (cell.selected) {
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self p_updateView];
        return nil;
    }
    return indexPath;
}

// hide last separator
-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

@end
