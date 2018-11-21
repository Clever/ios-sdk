# Clever iOS SDK

CleverSDK is a simple iOS library that makes it easy for iOS developers to integrate Clever Instant Login into their application.
You can read more about integrating Clever Instant Login in your app [here](https://dev.clever.com/).

## Usage

### Configure your Clever application to support the iOS redirect URL.

You can create an iOS redirect URL by going to https://apps.clever.com/partner/applications and clicking View / Edit on your application.

Click on the "Enable iOS Platform" button (contact Clever Support if option is not available).

You will then get access to a client ID and redirect URI you can use for your iOS app.

You can also set a "fallback URL" where users will be redirected if they don't have your app installed.

### Configure your iOS app
Once you have the custom redirect URL, add it to your application as a custom URL scheme.
If you are not sure how to do so, follow the steps below:
1. Open your app's `Info.plist` file.
2. Look for a key named "URL types". If you don't see one, then add the key to `Info.plist`.
3. Expand "URL types" and add a row called "URL Schemes" under "URL types".
4. Expand "URL Schemes" and you will see a key called "Item 0" (if it doesn't exist, add a key named "Item 0"). Put the custom redirect URL as the value to this Key.

For example, if your custom redirect URL is `clever-1234`, then the structure should look something like this:
<img src="https://user-images.githubusercontent.com/59177/42003240-5071d51c-7a1f-11e8-83a0-88892c4e0c87.png" width=600 />

Finally, add `com.clever` to your LSApplicationQueriesSchemes in your Info.plist, so you can redirect directly to the Clever app.
More information on LSApplicationQueriesSchemes can be found [here](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html#//apple_ref/doc/uid/TP40009250-SW14).

### Sign in with Clever
Once the app configuration has been updated, add the following code to the `application:didFinishLaunchingWithOptions:` method in AppDelegate.m:
```obj-C
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Start the CleverSDK with your client
    // Do not forget to replace CLIENT_ID with your client_id
    [CLVOAuthManager startWithClientId:@"CLIENT_ID" successHandler:^(NSString * _Nonnull accessToken) {
        NSLog(@"success");
    } failureHandler:^(NSString * _Nonnull errorMessage) {
        NSLog(@"failure");
    }];
    
    // To support iOS 9/10, you must set the UIDelegate to the UIViewController 
    // that will be displayed when the user is logging in.
    MyLoginViewController *vc = [[MyLoginViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = vc;
    [CLVOAuthManager setUIDelegate:vc]

    // Alternatively, you can initialize CLVOAuthManager without success/failure blocks and instead use the delegate pattern.
    // See "Delegate Pattern" below for handling completion when using the delegate pattern
    // [CLVOAuthManager startWithClientId:@"CLIENT_ID"];
    // [CLVOAuthManager setDelegate:self];
}]
```

Besides the above change, you also need to add some code to handle the iOS redirect URI.
This is done by implementing the `application:openURL:sourceApplication:annotation:` method of the AppDelegate:
```obj-C
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Clever's URL handler
    return [CLVOAuthManager handleURL:url sourceApplication:sourceApplication annotation:annotation];
}
```

### Log in with Clever Button
You can also set up a Log in with Clever Button. In the `UIViewController` set as the UIDelegate, add the following code to the `viewDidLoad` method:
```obj-C
// Create a "Log in with Clever" button
loginButton = [CLVLoginButton createLoginButton];
[self.view addSubview:loginButton];
```

The button is instantiated with a particular width and height.
You can update the width of the button by calling `setWidth:` method on the button:
```obj-C
[self.loginButton setWidth:300.0];
```

#### Delegate Pattern
If you are using the delegate pattern instead of completion blocks, add the following method to your AppDelegate.m:
```obj-C
// If non-null blocks are provided, signInToClever:withError: will not be called
- (void)signInToClever:(NSString *)accessToken withError:(NSString *)error {
    if (error) {
        // error
    }
    // success
}
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
