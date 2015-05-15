//
//  CLVOAuthManager.m
//  CleverSDK
//
//  Created by Nikhil Pandit on 4/3/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import "CLVOAuthManager.h"
#import <SSKeychain/SSKeychain.h>
#import "AFHTTPSessionManager.h"
#import "AFNetworkActivityIndicatorManager.h"

NSString *const CLVAccessTokenReceivedNotification = @"CLVAccessTokenReceivedNotification";
NSString *const CLVOAuthAuthorizeFailedNotification = @"CLVOAuthAuthorizeFailedNotification";

static NSString *const CLVServiceName = @"com.clever.CleverSDK";

@interface CLVOAuthManager ()

@property (nonatomic, strong) NSString *clientId;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *errorMessage;

@property (nonatomic, copy) void (^successHandler)(NSString *);
@property (nonatomic, copy) void (^failureHandler)(NSString *);

+ (instancetype)sharedManager;

@end

@implementation CLVOAuthManager

+ (instancetype)sharedManager {
    static CLVOAuthManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[CLVOAuthManager alloc] init];
    });
    return _sharedManager;
}

+ (void)startWithClientId:(NSString *)clientId {
    CLVOAuthManager *manager = [CLVOAuthManager sharedManager];
    manager.clientId = clientId;
}

+ (BOOL)clientIdIsNotSet {
    NSString *clientId = [CLVOAuthManager clientId];
    if (!clientId || [clientId isEqualToString:@""] || [clientId isEqualToString:@"CLIENT_ID"]) {
        // checking to see it's not empty or the default value of "CLIENT_ID"
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *)clientId {
    return [[CLVOAuthManager sharedManager] clientId];
}

+ (NSString *)redirectUri {
    return [NSString stringWithFormat:@"clever-%@://oauth", [CLVOAuthManager clientId]];
}

+ (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // check if it's the Clever redirect URI first
    if (![url.scheme isEqualToString:[NSString stringWithFormat:@"clever-%@", [CLVOAuthManager clientId]]]) {
        // not a Clever redirect URL, so exit
        return NO;
    }
    NSString *fragment = url.fragment;
    NSMutableDictionary *kvpairs = [NSMutableDictionary dictionaryWithCapacity:1];
    NSArray *components = [fragment componentsSeparatedByString:@"&"];
    for (NSString *component in components) {
        NSArray *kv = [component componentsSeparatedByString:@"="];
        kvpairs[kv[0]] = kv[1];
    }
    NSString *accessToken = kvpairs[@"access_token"];
    if (accessToken) {
        [CLVOAuthManager setAccessToken:kvpairs[@"access_token"]];
        // make a request to tokeninfo to verify that this token belongs to the right app
        AFHTTPSessionManager *tokenInfo = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://clever.com/oauth/tokeninfo"]];
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
        tokenInfo.requestSerializer = [AFJSONRequestSerializer serializer];
        tokenInfo.responseSerializer = [AFJSONResponseSerializer serializer];
        [tokenInfo.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
        [tokenInfo GET:@"https://clever.com/oauth/tokeninfo" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            // verify that the client id is what we expect
            if ([responseObject[@"client_id"] isEqualToString:[CLVOAuthManager clientId]]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:CLVAccessTokenReceivedNotification object:self];
            } else {
                // if the client IDs don't match, consider this a failure
                [[NSNotificationCenter defaultCenter] postNotificationName:CLVOAuthAuthorizeFailedNotification object:self];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            // if the tokeninfo endpoint returns a failure, take the safe option and assume AuthorizationFailed
            [[NSNotificationCenter defaultCenter] postNotificationName:CLVOAuthAuthorizeFailedNotification object:self];
        }];
        
    } else {
        [CLVOAuthManager sharedManager].errorMessage = [NSString stringWithFormat:@"%@: %@", kvpairs[@"error"], kvpairs[@"error_description"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLVOAuthAuthorizeFailedNotification object:self];
    }
    return YES;
}

+ (void)successHandler:(void (^)(NSString *accessToken))successHandler failureHandler:(void (^)(NSString *errorMessage))failureHandler {
    CLVOAuthManager *manager = [CLVOAuthManager sharedManager];
    manager.successHandler = successHandler;
    manager.failureHandler = failureHandler;
}

+ (void)callSucessHandler {
    [CLVOAuthManager sharedManager].successHandler([CLVOAuthManager accessToken]);
}

+ (void)callFailureHandler {
    CLVOAuthManager *manager = [CLVOAuthManager sharedManager];
    manager.failureHandler(manager.errorMessage);
}

+ (NSString *)accessToken {
    CLVOAuthManager *manager = [CLVOAuthManager sharedManager];
    if (!manager.accessToken) {
        // accessToken property is not set, so get it from Keychain
        NSString *appIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        manager.accessToken = [SSKeychain passwordForService:CLVServiceName account:appIdentifier];
    }
    return manager.accessToken;
}

+ (void)setAccessToken:(NSString *)accessToken {
    // any time accessToken property is changed, the value in the Keychain should also be updated
    [CLVOAuthManager sharedManager].accessToken = accessToken;
    NSString *appIdentifer = [[NSBundle mainBundle] bundleIdentifier];
    [SSKeychain setPassword:accessToken forService:CLVServiceName account:appIdentifer];
}

+ (void)clearAccessToken {
    [CLVOAuthManager sharedManager].accessToken = nil;
    [SSKeychain deletePasswordForService:CLVServiceName account:[[NSBundle mainBundle] bundleIdentifier]];
}

+ (void)clearBrowserCookies {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)logout {
    [CLVOAuthManager clearBrowserCookies];
    [CLVOAuthManager clearAccessToken];
}

@end
