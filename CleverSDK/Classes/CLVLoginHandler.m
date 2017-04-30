//
//  CLVLoginHandler.m
//  CleverSDK
//
//  Created by Alex Smolen on 2/9/2017.
//  Copyright (c) 2017 Clever, Inc. All rights reserved.
//

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

    NSString *urlString = [NSString stringWithFormat:@"https://clever.com/oauth/authorize?response_type=code&client_id=%@&redirect_uri=%@&state=%@",
                           [CLVOAuthManager clientId], [CLVOAuthManager redirectUri], [CLVOAuthManager state]];

    if (self.districtId) {
        urlString = [NSString stringWithFormat:@"%@&district_id=%@", urlString, self.districtId];
    }

    // Use SFSVC if iOS version >= 9.0
    if (SYSTEM_VERSION_LESS_THAN(@"9.0")) {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:urlString]];
        return;
    }

    SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:urlString] entersReaderIfAvailable:NO];
    if (self.parent.presentedViewController) {
        [self.parent dismissViewControllerAnimated:YES completion:^{
            [self.parent presentViewController:svc animated:YES completion:nil];
        }];
    } else {
        [self.parent presentViewController:svc animated:YES completion:nil];
    }
}

- (void)accessTokenReceived:(NSNotification *)notification {
    if (SYSTEM_VERSION_LESS_THAN(@"9.0")) {
        [CLVOAuthManager callSucessHandler];
    } else {
        [self.parent dismissViewControllerAnimated:NO completion:^{
            [CLVOAuthManager callSucessHandler];
        }];
    }
}

- (void)oauthAuthorizeFailed:(NSNotification *)notification {
    [self.parent dismissViewControllerAnimated:NO completion:^{
        [CLVOAuthManager callFailureHandler];
    }];
}

@end
