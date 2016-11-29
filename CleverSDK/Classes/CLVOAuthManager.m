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
@property (nonatomic, strong) NSString *state;
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
    manager.state = [self generateRandomString:(32)];
    manager.clientId = clientId;
}

+(NSString*)generateRandomString:(int)num {
    NSMutableString* string = [NSMutableString stringWithCapacity:num];
    for (int i = 0; i < num; i++) {
        [string appendFormat:@"%C", (unichar)('a' + arc4random_uniform(25))];
    }
    return string;
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

+ (NSString *)state {
    return [[CLVOAuthManager sharedManager] state];
}

+ (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // check if it's the Clever redirect URI first
    if (![url.scheme isEqualToString:[NSString stringWithFormat:@"clever-%@", [CLVOAuthManager clientId]]]) {
        // not a Clever redirect URL, so exit
        return NO;
    }
    NSString *fragment = url.query;
    NSMutableDictionary *kvpairs = [NSMutableDictionary dictionaryWithCapacity:1];
    NSArray *components = [fragment componentsSeparatedByString:@"&"];
    for (NSString *component in components) {
        NSArray *kv = [component componentsSeparatedByString:@"="];
        kvpairs[kv[0]] = kv[1];
    }
    NSString *state = kvpairs[@"state"];
    if (![state isEqualToString:[self state]]) {
        // If state doesn't match, return failure
        [CLVOAuthManager sharedManager].errorMessage = @"Authorization failed. Please try logging in again.";
        [[NSNotificationCenter defaultCenter] postNotificationName:CLVOAuthAuthorizeFailedNotification object:self];
        return YES;
    }
    NSString *code = kvpairs[@"code"];
    if (code) {
        AFHTTPSessionManager *tokens = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://clever.com"]];
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
        tokens.requestSerializer = [AFJSONRequestSerializer serializer];
        tokens.responseSerializer = [AFJSONResponseSerializer serializer];
        NSString *encodedClientID = [[[NSString stringWithFormat:@"%@:", [CLVOAuthManager clientId]] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];

        [tokens.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@", encodedClientID] forHTTPHeaderField:@"Authorization"];
        NSDictionary *parameters = @{@"code": code, @"grant_type": @"authorization_code", @"redirect_uri": [self redirectUri]};

        [tokens POST:@"oauth/tokens" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        } success:^(NSURLSessionDataTask *task, id responseObject) {
            // verify that the client id is what we expect
            if ([responseObject objectForKey:@"access_token"]) {
                [CLVOAuthManager setAccessToken:responseObject[@"access_token"]];
                [[NSNotificationCenter defaultCenter] postNotificationName:CLVAccessTokenReceivedNotification object:self];
            } else {
                // if no access token was received, consider this a failure
                [[NSNotificationCenter defaultCenter] postNotificationName:CLVOAuthAuthorizeFailedNotification object:self];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [CLVOAuthManager sharedManager].errorMessage = [NSString stringWithFormat:@"%@",  [error localizedDescription]];
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
