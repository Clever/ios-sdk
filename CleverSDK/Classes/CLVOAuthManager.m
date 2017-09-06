//
//  CLVOAuthManager.m
//  CleverSDK
//
//  Created by Nikhil Pandit on 4/3/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import "CLVOAuthManager.h"
#import <SAMKeychain/SAMKeychain.h>
#import <SafariServices/SafariServices.h>
#import "AFHTTPSessionManager.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "CLVCleverSDK.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

static NSString *const CLVServiceName = @"com.clever.CleverSDK";

@interface CLVOAuthManager ()

@property (nonatomic, strong) NSString *clientId; // The partner app's clientID
@property (nonatomic, strong) NSString *districtId; // optional districtID
@property (nonatomic, strong) NSString *state; // used for oauthflow
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *errorMessage;
@property (atomic, assign) BOOL alreadyMissedCode; // used to track if a flow has already been called without a code

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

+ (void)startWithClientId:(NSString *)clientId {
    CLVOAuthManager *manager = [CLVOAuthManager sharedManager];
    manager.clientId = clientId;
    manager.alreadyMissedCode = false;
}

+ (void)setDelegate:(id<CLVOauthDelegate>) delegate {
    CLVOAuthManager *manager = [CLVOAuthManager sharedManager];
    manager.delegate = delegate;
}

+ (void)setUIDelegate:(id<CLVOAuthUIDelegate>) uiDelegate {
    CLVOAuthManager *manager = [CLVOAuthManager sharedManager];
    manager.uiDelegate = uiDelegate;
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

+ (BOOL)alreadyMissedCode {
    return [[CLVOAuthManager sharedManager] alreadyMissedCode];
}

+ (void)login {
    [[CLVOAuthManager sharedManager] login];
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
        CLVOAuthManager* manager = [CLVOAuthManager sharedManager];
        if ([CLVOAuthManager alreadyMissedCode]) {
            manager.alreadyMissedCode = NO;
            manager.errorMessage = [NSString localizedStringWithFormat:@"Authorization failed. Please try logging in again."];
            [CLVOAuthManager callFailureHandler];
            return YES;
        }
        manager.alreadyMissedCode = YES;
        [self login];
        return YES;
    }

    NSString *state = kvpairs[@"state"];
    if (![state isEqualToString:[self state]]) {
        // If state doesn't match, return failure
        [CLVOAuthManager sharedManager].errorMessage = @"Authorization failed. Please try logging in again.";
        [CLVOAuthManager callFailureHandler];
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
        [CLVOAuthManager sharedManager].alreadyMissedCode = NO;
        // verify that the client id is what we expect
        if ([responseObject objectForKey:@"access_token"]) {
            [self setAccessToken:responseObject[@"access_token"]];
            [self callSucessHandler];
        } else {
            // if no access token was received, consider this a failure
            [self callFailureHandler];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        CLVOAuthManager *manager = [self sharedManager];
        manager.alreadyMissedCode = NO;
        manager.errorMessage = [NSString stringWithFormat:@"%@",  [error localizedDescription]];
        [manager callFailureHandler];
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
    [manager callSucessHandler];
}

+ (void)callFailureHandler {
    CLVOAuthManager *manager = [self sharedManager];
    [manager callFailureHandler];
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

- (void)login {
    NSString *state = [CLVOAuthManager generateRandomString:32];
    [CLVOAuthManager setState:state];

    NSString *safariURLString = [NSString stringWithFormat:@"https://clever.com/oauth/authorize?response_type=code&client_id=%@&redirect_uri=%@&state=%@",
                                 [CLVOAuthManager clientId], [CLVOAuthManager redirectUri], [CLVOAuthManager state]];

    NSString *cleverAppURLString = [NSString stringWithFormat:@"com.clever://oauth/authorize?response_type=code&client_id=%@&redirect_uri=%@&state=%@&sdk_version=%@", [CLVOAuthManager clientId], [CLVOAuthManager redirectUri], [CLVOAuthManager state], SDK_VERSION];

    if (self.districtId) {
        NSString *districtId = [self districtId];
        if (districtId == nil) {
            districtId = @"";
        }
        safariURLString = [NSString stringWithFormat:@"%@&district_id=%@", safariURLString, districtId];
        cleverAppURLString = [NSString stringWithFormat:@"%@&district_id=%@", safariURLString, districtId];
    }

    // iOS 8 - always use Safari. Clever App not supported
    if (SYSTEM_VERSION_LESS_THAN(@"9.0")) {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:safariURLString]];
        return;
    }

    // Switch to native Clever app if possible
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:cleverAppURLString]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cleverAppURLString] options:@{} completionHandler:nil];
        return;
    }

    // Fallbacks:
    // iOS 9/10 - use SFSafariViewController
    // iOS 11+ - use Safari
    if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
        SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:safariURLString] entersReaderIfAvailable:NO];
        [self.uiDelegate presentViewController:svc animated:YES completion:nil];
        return;
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:safariURLString]];
    return;
}

- (void)callSuccessHandler {
    // iOS 8 - call success handler
    // iOS 9/10 - dismiss SFSafariViewController before calling success handler
    // iOS 11+ - call success handler
    if (SYSTEM_VERSION_LESS_THAN(@"11.0") && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")
        && self.uiDelegate.presentingViewController) {
        // Must dismiss SFSafariViewController
        [self.uiDelegate dismissViewControllerAnimated:NO completion:^{
            if (self.delegate) {
              [self.delegate signIn:[self accessToken] withError:nil];
            }
            if (self.successHandler) {
              [self.successHandler [self accessToken]];
            }
        }];
        return;
    }
    if (self.delegate) {
      [self.delegate signIn:[self accessToken] withError:nil];
    }
    if (self.successHandler) {
      [self.successHandler [self accessToken]];
    }
}

- (void)callFailureHandler {
    [self.uiDelegate dismissViewControllerAnimated:NO completion:^{
        [CLVOAuthManager callFailureHandler];
        [self.delegate signIn:nil withError:[self errorMessage]];
    }];
}

@end
