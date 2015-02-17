//
//  TFTaifuno.h
//  Taifuno
//
//  Created by Artem Olkov on 13/10/14.
//  Copyright (c) 2014 aolkov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface TFTaifuno : NSObject

+ (TFTaifuno *) sharedInstance;

    //setup methods
- (void) setApiKey:(NSString *) apiKey;
- (void) startChatOnViewController:(UIViewController *) vc WithCallback:(void (^)()) callback;

    //notifications method
- (void) didRecieveNewNotification:(NSDictionary *)userInfo;
- (void) registerDeviceToken:(NSString *) token;

    //save data
- (void) saveTaifuno;
    //delete all data (If your user is logged out, for example
- (void) signOut;

@end
