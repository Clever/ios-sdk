//
//  CLVLoginHandler.m
//  CleverSDK
//
//  Created by Alex Smolen on 2/9/2017.
//  Copyright (c) 2017 Clever, Inc. All rights reserved.
//

#import "CLVCleverSDK.h"
#import "CLVLoginHandler.h"
#import "CLVOAuthManager.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@interface CLVLoginHandler ()

@property (nonatomic, weak) UIViewController *parent;

@property (nonatomic, strong) NSString *districtId;

@end

@implementation CLVLoginHandler

+ (CLVLoginHandler *)loginInViewController:(UIViewController *)viewController
                            withDistrictId:(NSString *)districtId
                             successHander:(void (^)(NSString *))successHandler
                            failureHandler:(void (^)(NSString *))failureHandler {
    CLVLoginHandler *login = [[self alloc] init];
    login.districtId = districtId;
    login.parent = viewController;
    [CLVOAuthManager successHandler:successHandler failureHandler:failureHandler];
    [[NSNotificationCenter defaultCenter] addObserver:login selector:@selector(accessTokenReceived:) name:CLVAccessTokenReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:login selector:@selector(oauthAuthorizeFailed:) name:CLVOAuthAuthorizeFailedNotification object:nil];
    return login;
}

+ (CLVLoginHandler *)loginInViewController:(UIViewController *)viewController
                             successHander:(void (^)(NSString *accessToken))successHandler
                            failureHandler:(void (^)(NSString *errorMessage))failureHandler {
    return [self loginInViewController:viewController withDistrictId:nil successHander:successHandler failureHandler:failureHandler];
}

- (void)login {
    NSString *state = [CLVOAuthManager generateRandomString:32];
    [CLVOAuthManager setState:state];


    NSString *safariURLString = [NSString stringWithFormat:@"https://clever.com/oauth/authorize?response_type=code&client_id=%@&redirect_uri=%@&state=%@",
                           [CLVOAuthManager clientId], [CLVOAuthManager redirectUri], [CLVOAuthManager state]];
    NSString *districtID = [self districtId];
    if (districtID == nil) {
        districtID = @"";
    }

    NSArray *targetDataList = @[
                               districtID,
                               [CLVOAuthManager clientId],
                               [CLVOAuthManager redirectUri],
                               [CLVOAuthManager state],
                               @"code", // response_type
                               SDK_VERSION
                           ];
    NSString *target = [self createTargetFromArray:targetDataList];
    NSString *cleverAppURLString = [NSString stringWithFormat:@"com.clever://oauth?target=%@", target];

    if (self.districtId) {
        safariURLString = [NSString stringWithFormat:@"%@&district_id=%@", safariURLString, self.districtId];
    }

    // iOS 8 - always use Safari. Clever App not supported
    if (SYSTEM_VERSION_LESS_THAN(@"9.0")) {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:safariURLString]];
        return;
    }

    // Switch to native Clever app if possible
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:cleverAppURLString]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cleverAppURLString]];
        return;
    }

    // Fallbacks:
    // iOS 9/10 - use SFSafariViewController
    // iOS 11+ - use Safari
    if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
        SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:safariURLString] entersReaderIfAvailable:NO];
        if (self.parent.presentedViewController) {
            [self.parent dismissViewControllerAnimated:YES completion:^{
                [self.parent presentViewController:svc animated:YES completion:nil];
            }];
        } else {
            [self.parent presentViewController:svc animated:YES completion:nil];
        }
        return;
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:safariURLString]];
    return;
}

- (NSString*)createTargetFromArray:(NSArray*)array {
    NSMutableArray* encodedArray = [[NSMutableArray alloc] init];
    for (NSString* item in array) {
        NSData* data = [item dataUsingEncoding:NSUTF8StringEncoding];
        NSString* base64Endoded = [data base64EncodedStringWithOptions:0];
        [encodedArray addObject:base64Endoded];
    }
    return [encodedArray componentsJoinedByString:@";"];
}

- (void)accessTokenReceived:(NSNotification *)notification {
    // iOS 8 - call success handler
    // iOS 9/10 - dismiss SFSafariViewController before calling success handler
    // iOS 11+ - call success handler
    if SYSTEM_VERSION_LESS_THAN(@"9.0") {
        [CLVOAuthManager callSucessHandler];
    } else if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
        // Must dismiss SFSafariViewController
        [self.parent dismissViewControllerAnimated:NO completion:^{
            [CLVOAuthManager callSucessHandler];
        }];
    }
    [CLVOAuthManager callSucessHandler];
}

- (void)oauthAuthorizeFailed:(NSNotification *)notification {
    [self.parent dismissViewControllerAnimated:NO completion:^{
        [CLVOAuthManager callFailureHandler];
    }];
}

@end
