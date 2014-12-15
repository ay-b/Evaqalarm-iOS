//
//  EASubscribeViewController.m
//  EvaqAlarm
//
//  Created by Sergey Butenko on 11/12/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "EASubscribeViewController.h"
#import "EAPlanTableViewCell.h"
#import "EAConstants.h"
#import "EAPreferences.h"
#import "EASubscriptionPlan.h"

#import <RMStore.h>
#import <MKStoreKit/MKStoreManager.h>

static NSString *const kCellIndentifier = @"PlanCell";
static const NSTimeInterval kAnimationDuration = 0.3;

@interface EASubscribeViewController () <UITableViewDataSource, UITableViewDelegate>

@property NSArray *plans;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *purchaseButton;

- (IBAction)purchaseButtonPressed;

@end

@implementation EASubscribeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    self.plans = [EAPreferences availablePlans];
}

- (IBAction)purchaseButtonPressed
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    EASubscriptionPlan *plan = self.plans[indexPath.row];
    
    [[RMStore defaultStore] addPayment:plan.uid success:^(SKPaymentTransaction *transaction) {
        EALog(@"Product purchased");
        [self p_purchaseBought];
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        EALog(@"Something went wrong");
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
 
    EASubscriptionPlan *plan = self.plans[indexPath.row];
    [cell configureWithPlan:plan];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self p_updateView];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.selected) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
