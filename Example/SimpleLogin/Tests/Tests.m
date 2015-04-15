//
//  SimpleLoginTests.m
//  SimpleLoginTests
//
//  Created by Nikhil Pandit on 04/09/2015.
//  Copyright (c) 2014 Nikhil Pandit. All rights reserved.
//

#import <CleverSDK/CLVCleverSDK.h>

SpecBegin(InitialSpecs)

describe(@"CLVLoginButton", ^{
    
    __block CLVLoginButton *button;
    
    before(^{
        UIViewController *vc = [[UIViewController alloc] init];
        button = [CLVLoginButton buttonInViewController:vc successHander:^(NSString *accessToken) {
        } failureHandler:^(NSString *errorMessage) {
        }];
    });

    it(@"can set origin", ^{
        expect(button.frame.origin.x).to.beCloseTo(0);
        expect(button.frame.origin.y).to.beCloseTo(0);
        [button setOrigin:CGPointMake(10.0, 20.0)];
        expect(button.frame.origin.x).to.beCloseTo(10);
        expect(button.frame.origin.y).to.beCloseTo(20);
    });

    it(@"can set width", ^{
        expect(button.frame.size.width).to.beCloseTo(248);
        expect(button.frame.size.height).to.beCloseTo(44);
        [button setWidth:300];
        expect(button.frame.size.width).to.beCloseTo(300);
        expect(button.frame.size.height).to.beCloseTo(44);
    });

});

describe(@"CLVOAuthManager", ^{
    
    before(^{
        [CLVOAuthManager startWithClientId:@"1234"];
    });
    
    it(@"sets clientId on start", ^{
        // start is called in the before, so no need to call it here again
        expect([CLVOAuthManager clientId]).to.equal(@"1234");
    });
    
    it (@"handles URL", ^{
        [CLVOAuthManager handleURL:[NSURL URLWithString:@"clever-1234://oauth#access_token=abcd"] sourceApplication:nil annotation:nil];
        expect([CLVOAuthManager accessToken]).to.equal(@"abcd");
    });
    
    it(@"clears accessToken on logout", ^{
        [CLVOAuthManager setAccessToken:@"abcd"];
        expect([CLVOAuthManager accessToken]).to.equal(@"abcd");
        [CLVOAuthManager logout];
        expect([CLVOAuthManager accessToken]).to.beNil;
    });
    
    it(@"returns access token in success handler", ^{
        [CLVOAuthManager handleURL:[NSURL URLWithString:@"clever-1234://oauth#access_token=qwerty"] sourceApplication:nil annotation:nil];
        [CLVLoginButton buttonInViewController:nil successHander:^(NSString *accessToken) {
            expect(accessToken).to.equal(@"qwerty");
        } failureHandler:^(NSString *errorMessage) {
        }];
        [CLVOAuthManager callSucessHandler];
    });
    
    it(@"displays error if oauth returns error to redirect URL", ^{
        [CLVOAuthManager handleURL:[NSURL URLWithString:@"clever-1234://oauth#error=Error&error_description=This is an error message"] sourceApplication:nil annotation:nil];
        [CLVLoginButton buttonInViewController:nil successHander:^(NSString *accessToken) {
        } failureHandler:^(NSString *errorMessage) {
            expect(errorMessage).to.equal(@"Error: This is an error message");
        }];
    });
    
});

describe(@"CLVApiRequest", ^{
    it(@"sets the bearer token", ^{
        [CLVOAuthManager setAccessToken:@"abcd"];
        CLVApiRequest *request = [CLVApiRequest sharedManager];
        expect(request.requestSerializer.HTTPRequestHeaders[@"Authorization"]).to.equal(@"Bearer abcd");
    });
});

SpecEnd
