//
//  CLVAppDelegate.m
//  SimpleLogin
//
//  Created by Nikhil Pandit on 4/2/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import "CLVAppDelegate.h"
#import "CLVLoginViewController.h"
#import "CLVSuccessViewController.h"
#import <CleverSDK/CLVCleverSDK.h>

@interface CLVAppDelegate ()

@property (nonatomic, strong) UINavigationController* navigationController;

@end

@implementation CLVAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    CLVLoginViewController *vc = [[CLVLoginViewController alloc] initWithNibName:nil bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = self.navigationController;

    // Start the CleverSDK with your client
    // Do not forget to replace CLIENT_ID with your client_id
    [CLVOAuthManager startWithClientId:@"CLIENT_ID"];
    [CLVOAuthManager setDelegate:self];

    // Alternatively, you can initialize the CLVOAuthManager with success and failure blocks.
    // If non-null blocks are used, signInToClever:withError: will not be called
//    [CLVOAuthManager startWithClientId:@"CLIENT_ID" successHandler:^(NSString * _Nonnull accessToken) {
//        NSLog(@"success");
//    } failureHandler:^(NSString * _Nonnull errorMessage) {
//        NSLog(@"failure");
//    }];
    
    // If on iOS 8, you must always set the UIDelegate, regardless of whether you use
    // blocks or a delegate for completion.
    [CLVOAuthManager setUIDelegate:vc];

    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Clever's URL handler
    return [CLVOAuthManager handleURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)signInToClever:(NSString *)accessToken withError:(NSString *)error {
    UINavigationController *navigationController = self.navigationController;
    if (error) {
        // handle failure
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:error
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil
                                  ];
        [navigationController popToRootViewControllerAnimated:YES];
        [alertView show];
        return;
    }
    // success
    CLVSuccessViewController *vc = [[CLVSuccessViewController alloc] initWithAccessToken:accessToken];
    [navigationController popToRootViewControllerAnimated:NO];
    [navigationController pushViewController:vc animated:YES];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
