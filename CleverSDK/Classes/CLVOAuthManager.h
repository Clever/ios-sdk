//
//  CLVOAuthManager.h
//  CleverSDK
//
//  Created by Nikhil Pandit on 4/3/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CLVOauthDelegate
- (void) signInToClever:( NSString* _Nullable )code withError:( NSString* _Nullable )error;
@end
NS_ASSUME_NONNULL_BEGIN

/**
 CLVOAuthManager
 */
@interface CLVOAuthManager : NSObject

@property (weak) id<CLVOauthDelegate> delegate; // receiver of successful signInToClever completions
@property (weak) UIViewController *uiDelegate; // on iOS 9/10, receiver of calls to present/dismiss SFSafariViewController for sign in

/**
 * Initializes the CLVOAuthManager with successHandler and failureHandler. If this method is used, the delegate will not called.
 * uiDelegate still needs to be set on iOS even if you use this method.
 */
+ (void)startWithClientId:(NSString *)clientId IosClientId:(NSString *)iosClientId RedirectURI:(NSString *)redirectUri successHandler:(void (^)(NSString *code))successHandler failureHandler:(void (^)(NSString *errorMessage))failureHandler;

/**
 * setDelegate sets the CLVOAuthDelegate implementer to be called upon completion
 */
+ (void)setDelegate:(id<CLVOauthDelegate>) delegate;

/**
 * setUIDelegate sets the UIViewController to be called to present/dismiss the SFSafariViewController.
 * This is only used on iOS 9/10
 */
+ (void)setUIDelegate:(UIViewController *) uiDelegate;

/**
 * This method should be called under `application:openURL:sourceApplication:annotation:` method in the AppDelegate
 * This will also retrieve the `access_token` and attach it automatically for requests made using `CLVApiRequest`
 */
+ (BOOL)handleURL:(NSURL *)url;

/**
 * Start the login flow
 */
+ (void)login;

/**
 * It is important to call this method when the user tries to logout. This clears the `access_token` locally, and invalidates any stored state on the device.
 * It also makes a call to the server to logout the user from the app.
 */
+ (void)logout;

/**
 * Return the code to be used to exchange for a token server side.
 * See https://dev.clever.com/ for more information on using the code.
 */
+ (NSString *)code;

/**
 * Returns whether the user is logging in via universal links or the old iOS SDK flow.
 */
+ (BOOL)isUniversalLinkLogin;

///----------------------------------------
/// Methods used by other classes of the SDK or internally
///----------------------------------------

/**
 Simple helper method to determine whether or not the clientId was set
 */
+ (BOOL)clientIdIsNotSet;

/**
 Return the saved clientId to the caller
 */
+ (NSString *)clientId;

/**
 Return the redirectURI to the caller
 */
+ (NSString *)redirectUri;

/**
 Return the uiDelegate
 */
+ (UIViewController *)uiDelegate;

/**
 Call the success handler
 */
+ (void)callSucessHandler;

/**
 Call the failure handler
 */
+ (void)callFailureHandler;

/**
 Allows setting the code. Users of the SDK should not need to call this method directly.
 */
+ (void)setCode:(NSString *)code;

/**
 This method sets the state value used in the OAuth fow.
 It should be called before every login attempt to ensure a unique, random state value is used.
 */
+ (void)setState:(NSString *)state;

/**
 Return the state
 */
+ (NSString *)state;


@end

NS_ASSUME_NONNULL_END
