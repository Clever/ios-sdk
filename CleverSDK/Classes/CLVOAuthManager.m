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
@property (nonatomic, strong) NSString *redirectUri; // The partner app's redirectURI
@property (nonatomic, strong) NSString *iosClientId; // The partner app's redirectURI
@property (atomic, assign) BOOL isUniversalLinkLogin; // universal link flow vs old ios flow
@property (nonatomic, strong) NSString *code;
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

+ (void) startWithClientId:(NSString *)clientId IosClientId:(NSString *)iosClientId RedirectURI:(NSString *)redirectUri successHandler:(void (^)(NSString *code))successHandler failureHandler:(void (^)(NSString *errorMessage))failureHandler {
    [self startWithClientId:clientId IosClientId: iosClientId RedirectURI: redirectUri];
    CLVOAuthManager *manager = [self sharedManager];
    manager.successHandler = successHandler;
    manager.failureHandler = failureHandler;
    manager.isUniversalLinkLogin = true;
}

+ (void) startWithClientId:(NSString *)clientId IosClientId:(NSString *)iosClientId RedirectURI:(NSString *)redirectUri {
    CLVOAuthManager *manager = [self sharedManager];
    manager.clientId = clientId;
    manager.alreadyMissedCode = NO;
    manager.iosClientId = iosClientId;
    manager.redirectUri = redirectUri;
}

+ (void)setDelegate:(id<CLVOauthDelegate>) delegate {
    CLVOAuthManager *manager = [self sharedManager];
    manager.delegate = delegate;
}

+ (UIViewController *)uiDelegate {
    return [[self sharedManager] uiDelegate];
}

+ (void)setUIDelegate:(UIViewController *) uiDelegate {
    CLVOAuthManager *manager = [self sharedManager];
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

+ (NSString *)iosClientId {
    return [[self sharedManager] iosClientId];
}

+ (NSString *)redirectUri {
    return [[self sharedManager] redirectUri];
}

+ (NSString *)iosRedirectUri {
    return [NSString stringWithFormat:@"clever-%@://oauth", [self iosClientId]];
}

+ (NSString *)state {
    CLVOAuthManager *manager = [self sharedManager];
    return [manager state];
}

+ (void)login {
    NSString *state = [self generateRandomString:32];
    [self setState:state];
    
    
    NSString *safariURLString = [NSString stringWithFormat:@"https://clever.com/oauth/authorize?response_type=code&client_id=%@&redirect_uri=%@&state=%@",
                                 [self iosClientId], [self iosRedirectUri], [self state]];

    NSString *universalLinkURLString = [NSString stringWithFormat:@"https://clever.com/oauth/authorize?response_type=code&client_id=%@&redirect_uri=%@&state=%@",
                                 [self clientId], [self redirectUri], [self state]];

    NSString *cleverAppURLString = [NSString stringWithFormat:@"com.clever://oauth/authorize?response_type=code&client_id=%@&redirect_uri=%@&state=%@&sdk_version=%@", [self iosClientId], [self iosRedirectUri], [self state], SDK_VERSION];
    
    // Temporary, this is how we will check if we are using the better app
    NSString *newCleverAppURLString = @"com.cleverv2://";
    
    // Checking for the new app here
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:newCleverAppURLString]]) {
        // We want to redirect to Safari here to trigger the universal link flow (May have to do things with the state here, unclear atm
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:universalLinkURLString]];
        return;
    }
    
    CLVOAuthManager *manager = [self sharedManager];
    if (manager.districtId) {
        NSString *districtId = manager.districtId;
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
        // Use old openURL method if on iOS 9-
        if (SYSTEM_VERSION_LESS_THAN(@"10.0")) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cleverAppURLString]];
            return;
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cleverAppURLString] options:@{} completionHandler:nil];
        return;
    }
    
    // Fallbacks:
    // iOS 9/10 - use SFSafariViewController
    // iOS 11+ - use Safari
    if (SYSTEM_VERSION_LESS_THAN(@"11.0") && manager.uiDelegate) {
        SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:safariURLString] entersReaderIfAvailable:NO];
        if ([manager.uiDelegate presentedViewController]) {
            [manager.uiDelegate dismissViewControllerAnimated:YES completion:^{
                [manager.uiDelegate presentViewController:svc animated:YES completion:nil];
            }];
        } else {
            [manager.uiDelegate presentViewController:svc animated:YES completion:nil];
        }
        return;
    }
    
    // Use old openURL method if on iOS 9-
    if (SYSTEM_VERSION_LESS_THAN(@"10.0")) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:safariURLString]];
        return;
    }

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:safariURLString] options:@{} completionHandler:nil];
}

+ (BOOL)handleURL:(NSURL *)url {
    if ([url.scheme isEqualToString:[NSString stringWithFormat:@"clever-%@", [self iosClientId]]]) {
        // uses clever redirect so it is the old iOS flow
        [self isOldIosFlow];
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
        CLVOAuthManager* manager = [self sharedManager];
        if (manager.alreadyMissedCode) {
            manager.alreadyMissedCode = NO;
            manager.errorMessage = [NSString localizedStringWithFormat:@"Authorization failed. Please try logging in again."];
            [self callFailureHandler];
            return YES;
        }
        manager.alreadyMissedCode = YES;
        [self login];
        return YES;
    }
    
    NSString *state = kvpairs[@"state"];
    if (![state isEqualToString:[self state]]) {
        // If state doesn't match, return failure
        CLVOAuthManager *manager = [self sharedManager];
        manager.errorMessage = @"Authorization failed. Please try logging in again.";
        [self callFailureHandler];
        return YES;
    }
    
    [self setCode:code];
    [self callSucessHandler];
    return YES;
}

+ (void)callSucessHandler {
    CLVOAuthManager *manager = [self sharedManager];
    // iOS 8 - call success handler
    // iOS 9/10 w/o native app - dismiss SFSafariViewController before calling success handler
    // iOS 9/10 w/ native app - call success handler
    // iOS 11+ - call success handler
    if (SYSTEM_VERSION_LESS_THAN(@"11.0")
        && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")
        && manager.uiDelegate
        && [manager.uiDelegate presentedViewController]) {
        // Must dismiss SFSafariViewController
        [manager.uiDelegate dismissViewControllerAnimated:NO completion:^{
            if (manager.successHandler) {
                manager.successHandler(self.code);
            } else if (manager.delegate) {
                [manager.delegate signInToClever:[self code] withError:nil];
            }
        }];
        return;
    }
    if (manager.successHandler) {
        manager.successHandler(self.code);
    } else if (manager.delegate) {
        [manager.delegate signInToClever:[self code] withError:nil];
    }
}

+ (void)callFailureHandler {
    [self logout];
    CLVOAuthManager *manager = [self sharedManager];
    // iOS 8 - call success handler
    // iOS 9/10 w/o native app - dismiss SFSafariViewController before calling success handler
    // iOS 9/10 w/ native app - call success handler
    // iOS 11+ - call success handler
    if (SYSTEM_VERSION_LESS_THAN(@"11.0")
        && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")
        && manager.uiDelegate
        && [manager.uiDelegate presentedViewController]) {
        // Must dismiss SFSafariViewController
        [manager.uiDelegate dismissViewControllerAnimated:NO completion:^{
            if (manager.failureHandler) {
                manager.failureHandler(manager.errorMessage);
            } else if (manager.delegate) {
                [manager.delegate signInToClever:nil withError:[manager errorMessage]];
            }
        }];
        return;
    }
    if (manager.failureHandler) {
        manager.failureHandler(manager.errorMessage);
    } else if (manager.delegate) {
        [manager.delegate signInToClever:nil withError:[manager errorMessage]];
    }
}

+ (NSString *)code {
    CLVOAuthManager *manager = [self sharedManager];
    if (!manager.code) {
        // accessToken property is not set, so get it from Keychain
        NSString *appIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        manager.code = [SAMKeychain passwordForService:CLVServiceName account:appIdentifier];
    }
    return manager.code;
}

+ (void)setCode:(NSString *)code {
    // any time accessToken property is changed, the value in the Keychain should also be updated
    CLVOAuthManager *manager = [self sharedManager];
    manager.code = code;
    NSString *appIdentifer = [[NSBundle mainBundle] bundleIdentifier];
    [SAMKeychain setPassword:code forService:CLVServiceName account:appIdentifer];
}


+ (BOOL)isUniversalLinkLogin {
    CLVOAuthManager *manager = [self sharedManager];
    return manager.isUniversalLinkLogin;
}

+ (void)isOldIosFlow {
    CLVOAuthManager *manager = [self sharedManager];
    manager.isUniversalLinkLogin = false;
}

+ (void)clearCode {
    CLVOAuthManager *manager = [self sharedManager];
    manager.code = nil;
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
    [self clearCode];
}

@end
