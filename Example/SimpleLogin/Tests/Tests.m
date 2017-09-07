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
        button = [CLVLoginButton createLoginButton];
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
    
    // We don't set accessToken until after we post
    it(@"generates a state of length 32 if no code passed in", ^{
        [CLVOAuthManager setState:@"abcd"];
        expect([CLVOAuthManager state]).to.equal(@"abcd");
        [CLVOAuthManager handleURL:[NSURL URLWithString:@"clever-1234://oauth"] sourceApplication:@"" annotation:@{}];
        expect([CLVOAuthManager state]).notTo.equal(@"abcd");
        expect([CLVOAuthManager state]).to.haveCountOf(32);
    });

    it(@"does not generate a state if code is passed in", ^{
        [CLVOAuthManager setState:@"abcd"];
        expect([CLVOAuthManager state]).to.equal(@"abcd");
        [CLVOAuthManager handleURL:[NSURL URLWithString:@"clever-1234://oauth?code=somecode&state=abcd"] sourceApplication:@"" annotation:@{}];
        expect([CLVOAuthManager state]).to.equal(@"abcd");
    });
    
    it(@"errors if passed in state does not match stored state", ^{
        [CLVOAuthManager startWithClientId:@"1234" successHandler:^(NSString * _Nonnull accessToken) {
        } failureHandler:^(NSString * _Nonnull errorMessage) {
            expect(errorMessage).to.equal(@"Authorization failed. Please try logging in again.");
        }];
        [CLVOAuthManager setState:@"abcd"];
        expect([CLVOAuthManager state]).to.equal(@"abcd");
        [CLVOAuthManager handleURL:[NSURL URLWithString:@"clever-1234://oauth?code=somecode&state=abcD"] sourceApplication:@"" annotation:@{}];
        [CLVOAuthManager callFailureHandler];
    });
    
    it(@"clears accessToken on logout", ^{
        [CLVOAuthManager setAccessToken:@"abcd"];
        expect([CLVOAuthManager accessToken]).to.equal(@"abcd");
        [CLVOAuthManager logout];
        expect([CLVOAuthManager accessToken]).to.beNil;
    });

    // Update this test when we can mock out AFHTTPSessionManager
    // We want to check the access token in success handler after token
    it(@"returns access token in success handler", ^{
        [CLVOAuthManager startWithClientId:@"1234" successHandler:^(NSString * _Nonnull accessToken) {
            expect(accessToken).notTo.equal(nil);
            expect(accessToken).to.equal(@"access_token");
        } failureHandler:^(NSString * _Nonnull errorMessage) {
        }];
        [CLVOAuthManager startWithClientId:@"1234"];
        [CLVOAuthManager handleURL:[NSURL URLWithString:@"clever-1234://oauth?code=somecode&state=abcd"] sourceApplication:@"" annotation:@{}];
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
