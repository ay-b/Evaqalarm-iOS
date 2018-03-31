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

    //custom parameters setup
- (void) setUserId:(NSString *) id;
- (void) setUserEmail:(NSString *) email;
    //If you want - you can instantiate sending of params by yourself.
    //Otherwise - they will be sent before starting chat
- (void) sendUserParams;

    //start taifuno chat
- (void) startChatOnViewController:(UIViewController *) vc;
- (void) startChatOnViewController:(UIViewController *) vc WithInfo:(NSString *) info;


    //notifications method
- (void) didRecieveNewNotification:(NSDictionary *)userInfo;
- (void) registerDeviceToken:(NSString *) token;

    //save data
- (void) saveTaifuno;
    //delete all data (If your user is logged out, for example
- (void) didBecomeActive;
- (void) signOut;

@end
