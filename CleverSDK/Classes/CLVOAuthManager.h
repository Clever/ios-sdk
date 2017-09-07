//
//  CLVOAuthManager.h
//  CleverSDK
//
//  Created by Nikhil Pandit on 4/3/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CLVOauthDelegate
- (void) signInToClever:( NSString* _Nullable )accessToken withError:( NSString* _Nullable )error;
@end
NS_ASSUME_NONNULL_BEGIN

/**
 CLVOAuthManager
 */
@interface CLVOAuthManager : NSObject

@property (weak) id<CLVOauthDelegate> delegate; // receiver of successful signInToClever completions
@property (weak) UIViewController *uiDelegate; // on iOS 9/10, receiver of calls to present/dismiss SFSafariViewController for sign in

/**
 * Initializes the CLVOauthManager. Sets the clientId which is used for constructing the OAuth URL and logging in.
 */
+ (void)startWithClientId:(NSString *)clientId;

/**
 * Initializes the CLVOAuthManager with successHandler and failureHandler. If this method is used, the delegate will not called.
 * uiDelegate still needs to be set on iOS even if you use this method.
 */
+ (void)startWithClientId:(NSString *)clientId successHandler:(void (^)(NSString *accessToken))successHandler failureHandler:(void (^)(NSString *errorMessage))failureHandler;

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
+ (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

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
 * Return the access token.
 * Use this as the bearer token when constructing network requests to the Clever API.
 * See https://dev.clever.com/ for more information on using the accessToken.
 * Alternatively, use the CLVApiRequest class to make requests.
 */
+ (NSString *)accessToken;

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
 Allows setting the access token. Users of the SDK should not need to call this method directly.
 */
+ (void)setAccessToken:(NSString *)accessToken;

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
