//
//  CLVLoginHandler.h
//  CleverSDK
//
//  Created by Alex Smolen on 2/9/2017.
//  Copyright (c) 2017 Clever, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>

@interface CLVLoginHandler : NSObject

/**
 Create a `CLVLoginHandler` with a `UIViewController`, successHandler, and failureHandler.
 @param viewController The base viewController on which the Login screen is presented modally.
 @param successHandler Called with the `accessToken` after dismissing the Login screen on success.
 @param failureHandler Called with the `errorMessage` after dismissing the Login screen on failure.
 */
+ (CLVLoginHandler *)loginInViewController:(UIViewController *)viewController
                             successHander:(void (^)(NSString *accessToken))successHandler
                            failureHandler:(void (^)(NSString *errorMessage))failureHandler;

/**
 Create a `CLVLoginHandler` with a `UIViewController`, districtID, successHandler, and failureHandler.
 @param viewController The base viewController on which the Login screen is presented modally.
 @param districtId Sent as a GET param to the `oauth/authorize` call.
 @param successHandler Called with the `accessToken` after dismissing the Login screen on success.
 @param failureHandler Called with the `errorMessage` after dismissing the Login screen on failure.
 */
+ (CLVLoginHandler *)loginInViewController:(UIViewController *)viewController
                            withDistrictId:(NSString *)districtId
                             successHander:(void (^)(NSString *))successHandler
                            failureHandler:(void (^)(NSString *))failureHandler;

- (void)login;

@end
