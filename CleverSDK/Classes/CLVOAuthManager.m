//
//  CLVOAuthManager.m
//  CleverSDK
//
//  Created by Nikhil Pandit on 4/3/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import "CLVOAuthManager.h"
#import <SAMKeychain/SAMKeychain.h>
#import "AFHTTPSessionManager.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "CLVLoginHandler.h"

NSString *const CLVAccessTokenReceivedNotification = @"CLVAccessTokenReceivedNotification";
NSString *const CLVOAuthAuthorizeFailedNotification = @"CLVOAuthAuthorizeFailedNotification";

static NSString *const CLVServiceName = @"com.clever.CleverSDK";

@interface CLVOAuthManager ()

@property (nonatomic, strong) NSString *clientId;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *errorMessage;
@property (nonatomic, strong) CLVLoginHandler *clvLogin;

@property (nonatomic, copy) void (^successHandler)(NSString *);
@property (nonatomic, copy) void (^failureHandler)(NSString *);

+ (instancetype)sharedManager;

@end

@implementation CLVOAuthManager

+ (instancetype)sharedManager {
    static CLVOAuthManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

+ (void)startWithClientId:(NSString *)clientId clvLoginHandler:(CLVLoginHandler *)clvLoginHandler {
    CLVOAuthManager *manager = [self sharedManager];
    manager.clientId = clientId;
    manager.clvLogin = clvLoginHandler;
}


+ (NSString *)generateRandomString:(int)length {
    NSAssert(length % 2 == 0, @"Must generate random string with even length");
    NSMutableData *data = [NSMutableData dataWithLength:length / 2];
    NSAssert(SecRandomCopyBytes(kSecRandomDefault, length, [data mutableBytes]) == 0, @"Failure in SecRandomCopyBytes: %d", errno);
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(length)];
    const unsigned char *dataBytes = [data bytes];
    for (int i = 0; i < length / 2; ++i)
    {
        [hexString appendFormat:@"%02x", (unsigned int)dataBytes[i]];
    }
    return [NSString stringWithString:hexString];
}

+ (void)setState:(NSString *)state {
    CLVOAuthManager *manager = [self sharedManager];
    manager.state = state;
}

+ (BOOL)clientIdIsNotSet {
    NSString *clientId = [self clientId];
    if (!clientId || [clientId isEqualToString:@""] || [clientId isEqualToString:@"CLIENT_ID"]) {
        // checking to see it's not empty or the default value of "CLIENT_ID"
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *)clientId {
    return [[self sharedManager] clientId];
}

+ (NSString *)redirectUri {
    return [NSString stringWithFormat:@"clever-%@://oauth", [self clientId]];
}

+ (NSString *)state {
    CLVOAuthManager *manager = [self sharedManager];
    return [manager state];
}

+ (void)login {
    CLVOAuthManager *manager = [self sharedManager];
    [[manager clvLogin] login];
}

+ (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // check if it's the Clever redirect URI first
    if (![url.scheme isEqualToString:[NSString stringWithFormat:@"clever-%@", [self clientId]]]) {
        // not a Clever redirect URL, so exit
        return NO;
    }
    NSString *query = url.query;
    NSMutableDictionary *kvpairs = [NSMutableDictionary dictionaryWithCapacity:1];
    NSArray *components = [query componentsSeparatedByString:@"&"];
    for (NSString *component in components) {
        NSArray *kv = [component componentsSeparatedByString:@"="];
        kvpairs[kv[0]] = kv[1];
    }

    // if code is missing, then this is a Clever Portal initiated login, and we should kick off the Oauth flow
    NSString *code = kvpairs[@"code"];
    if (!code) {
        [self login];
        return YES;
    }

    NSString *state = kvpairs[@"state"];
    if (![state isEqualToString:[self state]]) {
        // If state doesn't match, return failure
        CLVOAuthManager *manager = [self sharedManager];
        manager.errorMessage = @"Authorization failed. Please try logging in again.";
        [[NSNotificationCenter defaultCenter] postNotificationName:CLVOAuthAuthorizeFailedNotification object:self];
        return YES;
    }

    AFHTTPSessionManager *tokens = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://clever.com"]];
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    tokens.requestSerializer = [AFJSONRequestSerializer serializer];
    tokens.responseSerializer = [AFJSONResponseSerializer serializer];
    NSString *encodedClientID = [[[NSString stringWithFormat:@"%@:", [self clientId]] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];

    [tokens.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@", encodedClientID] forHTTPHeaderField:@"Authorization"];
    NSDictionary *parameters = @{@"code": code, @"grant_type": @"authorization_code", @"redirect_uri": [self redirectUri]};

    [tokens POST:@"oauth/tokens" parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        // verify that the client id is what we expect
        if ([responseObject objectForKey:@"access_token"]) {
            [self setAccessToken:responseObject[@"access_token"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:CLVAccessTokenReceivedNotification object:self];
        } else {
            // if no access token was received, consider this a failure
            [[NSNotificationCenter defaultCenter] postNotificationName:CLVOAuthAuthorizeFailedNotification object:self];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        CLVOAuthManager *manager = [self sharedManager];
        manager.errorMessage = [NSString stringWithFormat:@"%@",  [error localizedDescription]];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLVOAuthAuthorizeFailedNotification object:self];
    }];
    return YES;
}

+ (void)successHandler:(void (^)(NSString *accessToken))successHandler failureHandler:(void (^)(NSString *errorMessage))failureHandler {
    CLVOAuthManager *manager = [self sharedManager];
    manager.successHandler = successHandler;
    manager.failureHandler = failureHandler;
}

+ (void)callSucessHandler {
    CLVOAuthManager *manager = [self sharedManager];
    if (manager.successHandler) {
        manager.successHandler([self accessToken]);
    }
}

+ (void)callFailureHandler {
    CLVOAuthManager *manager = [self sharedManager];
    if (manager.failureHandler) {
        manager.failureHandler(manager.errorMessage);
    }
}

+ (NSString *)accessToken {
    CLVOAuthManager *manager = [self sharedManager];
    if (!manager.accessToken) {
        // accessToken property is not set, so get it from Keychain
        NSString *appIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        manager.accessToken = [SAMKeychain passwordForService:CLVServiceName account:appIdentifier];
    }
    return manager.accessToken;
}

+ (void)setAccessToken:(NSString *)accessToken {
    // any time accessToken property is changed, the value in the Keychain should also be updated
    CLVOAuthManager *manager = [self sharedManager];
    manager.accessToken = accessToken;
    NSString *appIdentifer = [[NSBundle mainBundle] bundleIdentifier];
    [SAMKeychain setPassword:accessToken forService:CLVServiceName account:appIdentifer];
}

+ (void)clearAccessToken {
    CLVOAuthManager *manager = [self sharedManager];
    manager.accessToken = nil;
    [SAMKeychain deletePasswordForService:CLVServiceName account:[[NSBundle mainBundle] bundleIdentifier]];
}

+ (void)clearBrowserCookies {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)logout {
    [self clearBrowserCookies];
    [self clearAccessToken];
}

@end
