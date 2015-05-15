# Clever iOS SDK 

CleverSDK is a simple iOS library that makes it easy for iOS developers to integrate Clever Instant Login into their application.
You can read more about integrating Clever Instant Login in your app [here](https://dev.clever.com/).

## Usage

Configure your application to support the mobile redirect URL.
You can find your mobile redirect URL by going to https://account.clever.com/partner/applications and clicking View / Edit on your application.
Once you find the mobile redirect URL, you can add it to your application as a custom URL scheme.
If you are not sure how to do so, check out this tutorial: https://dev.twitter.com/cards/mobile/url-schemes

Once you have the redirect URI setup, go to the AppDelegate file, and call `startWithClientId:` as follows:
```obj-C
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Start the CleverSDK with your clientID
    // Replace CLIENT_ID with your client ID
    [CLVOAuthManager startWithClientId:@"CLIENT_ID"];
    ...
```

Besides the above change, you also need to add some code to handle the mobile redirect URI.
This is done by implementing the `application:openURL:sourceApplication:annotation:` method of the AppDelegate:
```obj-C
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Clever's URL handler
    return [CLVOAuthManager handleURL:url sourceApplication:sourceApplication annotation:annotation];
}
```

Next step is to add the Clever Instant Login button.
In the `UIViewController` where you plan to add the button, you can call the following code:
```obj-C
self.loginButton = [CLVLoginButton buttonInViewController:self successHander:^(NSString *accessToken) {
// success handler
} failureHandler:^(NSError *error) {
// failure handler
}];
CGPoint origin = CGPointMake(10, 10);
[self.loginButton setOrigin:origin];
[self.view addSubview:self.loginButton];
```
The button is instantiated with a particular width and height.
You can update the width of the button by calling `setWidth:` method on the button.
For example:
```obj-C
[self.loginButton setWidth:300.0];
```

The `UIViewController` passed to the button is used to present another `UIViewController` that displays the login flow.


To run the example project, clone the repo, and run `pod install` from the Example/SimpleLogin directory first.

## Installation

CleverSDK is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```
pod "CleverSDK"
```

## License

CleverSDK is available under the MIT license. See the LICENSE file for more info.
