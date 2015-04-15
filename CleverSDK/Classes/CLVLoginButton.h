//
//  CLVLoginButton.h
//  CleverSDK
//
//  Created by Nikhil Pandit on 4/3/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLVLoginButton : UIButton

/**
 Create a `CLVLoginButton` with a `UIViewController`, successHandler, and failureHandler.
 @param viewController The base viewController on which the Login screen is presented modally.
 @param successHandler Called with the `accessToken` after dismissing the Login screen on success.
 @param failureHandler Called with the `errorMessage` after dismissing the Login screen on failure.
 */
+ (CLVLoginButton *)buttonInViewController:(UIViewController *)viewController
                             successHander:(void (^)(NSString *accessToken))successHandler
                            failureHandler:(void (^)(NSString *errorMessage))failureHandler;

/**
 Create a `CLVLoginButton` with a `UIViewController`, districtID, successHandler, and failureHandler.
 @param viewController The base viewController on which teh Login screen is presented modally.
 @param districtId Sent as a GET param to the `oauth/authorize` call.
 @param successHandler Called with the `accessToken` after dismissing the Login screen on success.
 @param failureHandler Called with the `errorMessage` after dismissing the Login screen on failure.
 */
+ (CLVLoginButton *)buttonInViewController:(UIViewController *)viewController
                            withDistrictId:(NSString *)districtId
                             successHander:(void (^)(NSString *))successHandler
                            failureHandler:(void (^)(NSString *))failureHandler;

/**
 Set the origin of the button. This is the preferred method of manipulating the button frame.
 */
- (void)setOrigin:(CGPoint)origin;

/**
 Scales the button by multiplying the width and height by the `scaleFactor`.
 */
- (void)scale:(CGFloat)scaleFactor;

/**
 Scales the button to the `width` and modifies the height to match the width.
 */
- (void)scaleWithWidth:(CGFloat)width;

/**
 Scales the button to the `height` and modifies the width to match the height.
 */
- (void)scaleWithHeight:(CGFloat)height;

@end
