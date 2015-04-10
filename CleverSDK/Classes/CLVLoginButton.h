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
 The `UIViewController` is used as the base `UIViewController` on which the Login screen is presented modally.
 The successHander and failureHandler are passed on to the `CLVOAuthManager`.
 These are called when the login succeeds or fails.
 */
+ (CLVLoginButton *)buttonInViewController:(UIViewController *)viewController
                             successHander:(void (^)(NSString *accessToken))successHandler
                            failureHandler:(void (^)(NSString *errorMessage))failureHandler;

/**
 This is the preferred method of setting the frame for the button.
 Instead of modifying the frame directly, you can set the origin of the frame, and use `scale:`, `scaleWithWidth:`, or `scaleWithHeight:` to set the size.
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
