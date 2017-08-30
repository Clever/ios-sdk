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

@property (strong) SFAuthenticationSession *session;

@end

@implementation CLVLoginHandler

+ (CLVLoginHandler *)loginInViewController:(UIViewController *)viewController
                            withDistrictId:(NSString *)districtId
                             successHander:(void (^)(NSString *))successHandler
                            failureHandler:(void (^)(NSString *))failureHandler {
    CLVLoginHandler *login = [[CLVLoginHandler alloc] init];
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
    return [CLVLoginHandler loginInViewController:viewController withDistrictId:nil successHander:successHandler failureHandler:failureHandler];
}

- (void)login {
    NSString *state = [CLVOAuthManager generateRandomString:32];
    [CLVOAuthManager setState:state];


    NSString *urlString = [NSString stringWithFormat:@"https://clever.com/oauth/authorize?response_type=code&client_id=%@&redirect_uri=%@&state=%@",
                           [CLVOAuthManager clientId], [CLVOAuthManager redirectUri], [CLVOAuthManager state]];

    if (self.districtId) {
        urlString = [NSString stringWithFormat:@"%@&district_id=%@", urlString, self.districtId];
    }

    // Xcode 9 introduces the @available macro, which we could instead use here. However, to maintain backwards
    // compatability with earlier versions of Xcode, we use the SYSTEM_VERSION macros. As such, we can ignore
    // warnings about it, as long as it is wrapped in macro use
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
        // Switch to native Clever app if possible
        NSURL *cleverAppURL = [NSURL URLWithString:[NSString stringWithFormat:@"com.clever://oauth?client_id=%@&redirect_uri=%@&state=%@",
                                                    [CLVOAuthManager clientId], [CLVOAuthManager redirectUri], [CLVOAuthManager state]]];
        if ([[UIApplication sharedApplication] canOpenURL:cleverAppURL]) {
            [[UIApplication sharedApplication] openURL:cleverAppURL];
            return;
        }
        
        // Fallback to SFAuthenticationSession if native Clever app not installed
        self.session = [[SFAuthenticationSession alloc] initWithURL:[NSURL URLWithString:urlString] callbackURLScheme:NULL
                                                  completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
                                                      [CLVOAuthManager handleURL:callbackURL sourceApplication:@"safari" annotation:NULL];
                                                  }];
        [self.session start];
        return;
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:urlString] entersReaderIfAvailable:NO];
        [self.parent presentViewController:svc animated:YES completion:nil];
        return;
    } else {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:urlString]];
    }
}

- (void)accessTokenReceived:(NSNotification *)notification {
    if (@available(iOS 11.0, *)) {
        NSLog(@"");
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
        [CLVOAuthManager callSucessHandler];
    } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        // Must dismiss SFSafariViewController
        [self.parent dismissViewControllerAnimated:NO completion:^{
            [CLVOAuthManager callSucessHandler];
        }];
    } else {
        [CLVOAuthManager callSucessHandler];
    }
}

- (void)oauthAuthorizeFailed:(NSNotification *)notification {
    [self.parent dismissViewControllerAnimated:NO completion:^{
        [CLVOAuthManager callFailureHandler];
    }];
}

@end
