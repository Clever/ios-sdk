# Clever iOS SDK 

CleverSDK is a simple iOS library that makes it easy for iOS developers to integrate Clever Instant Login into their application.
You can read more about integrating Clever Instant Login in your app [here](https://dev.clever.com/).

## Usage

Configure your application to support the iOS redirect URL.

You can create an iOS redirect URL by going to https://apps.clever.com/partner/applications and clicking View / Edit on your application.

Click on the "Enable iOS Platform" button (contact Clever Support if option is not available).

You will then get access to a client ID and redirect URI you can use for your iOS app.

You can also set a "fallback URL" where users will be redirected if they don't have your app installed.

Once you have the custom redirect URL, you can add it to your application as a custom URL scheme.
If you are not sure how to do so, check out this tutorial: https://dev.twitter.com/cards/mobile/url-schemes

Once you have the redirect URI setup, go the `UIViewController` where you plan to handle login success/failure, and call `startWithClientId:` as follows:
```obj-C
- (void)viewDidLoad {
    [super viewDidLoad];
    ...
    CLVLoginHandler *login = [CLVLoginHandler loginInViewController:self successHander:^(NSString *accessToken) {
        // success handler
        ...
    } failureHandler:^(NSString *errorMessage) {
        // failure handler
        ...
    }];

    // Start the CleverSDK with your client
    // Do not forget to replace CLIENT_ID with your client_id
    [CLVOAuthManager startWithClientId:@"CLIENT_ID" clvLoginHandler:login];
```

Besides the above change, you also need to add some code to handle the iOS redirect URI.
This is done by implementing the `application:openURL:sourceApplication:annotation:` method of the AppDelegate:
```obj-C
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Clever's URL handler
    return [CLVOAuthManager handleURL:url sourceApplication:sourceApplication annotation:annotation];
}
```

You can optionally add the Clever Instant Login button.
In the `UIViewController` where you set the login success/failure handlers, add the button:
```obj-C
// Create a "Log in with Clever" button
loginButton = [CLVLoginButton createLoginButton];
[self.view addSubview:loginButton];
```

The button is instantiated with a particular width and height.
You can update the width of the button by calling `setWidth:` method on the button.
For example:
```obj-C
[self.loginButton setWidth:300.0];
```

To run the example project, clone the repo, and run `pod install` from the Example/SimpleLogin directory first.

## Installation

CleverSDK is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```
pod "CleverSDK"
```

## License

Apache 2.0
