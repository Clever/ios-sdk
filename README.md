# CleverSDK

CleverSDK is a simple iOS library that makes it easy for iOS developers to integrate Clever Instant Login into their application.
You can read more about integrating Clever Instant Login in your app [here](https://dev.clever.com/docs/il-native-ios).

## Project Status

This SDK is no longer maintained and will be unpublished at a later date. Please see our Developer Docs for the latest information on how to integrate your app with Clever on iOS: [https://dev.clever.com/docs/il-native-ios](https://dev.clever.com/docs/il-native-ios)

## Installation

CleverSDK is available through [CocoaPods](https://cocoapods.org/pods/CleverSDK).
To install it, simply add the following line to your Podfile:

```
pod "CleverSDK"
```

to import the SDK into your codebase simply add the following header

```obj-c
#import <CleverSDK/CleverSDK.h>
```

## Usage

The `CleverSDK` utilizes [universal links](https://developer.apple.com/documentation/uikit/core_app/allowing_apps_and_websites_to_link_to_your_content) to open your application during the login flow.
In order to use `CleverSDK` you will first have to configure your application to support universal links.
Specifically you'll need to configure your application to handle your primary Clever redirect URI via universal links.
This means that if your users are directed to your redirect URI during the login flow (either from the Clever Portal or a [Log in with Clever button](https://dev.clever.com/docs/identity-api#section-log-in-with-clever)) your application will open and can complete the login.

Once your application is configured to handle your primary redirect URI you can instantiate the `CleverSDK`.

```obj-C
[CleverSDK startWithClientId:@"YOUR_CLIENT_ID" // Your Clever client ID
            RedirectURI:@"http://example.com" // A valid Clever redirect URI (that your app is configured to open with universal links)
            successHandler:^(NSString *code, BOOL validState) {
                // At this point your application has a code, which it should send to your backend to exchange for whatever information
                // is needed to complete the login into your application.
                // Additionally you're given the "validState" param which indicates that the CleverSDK initiated the login and that the
                // state param was validated. The Clever SDK generates and validates the state param when it initiates a login.
                // However if the login comes from the Clever Portal it will not have a state param. If your application needs extra
                // guarantees that the user who is logging in is who they say they are you can start another login in the case that
                // validState is false. This will result in a slower and more disruptive login experience (since users will be redirected
                // back to Clever), but will provide an extra layer of security during the login flow. You can learn more about this here
                // https://dev.clever.com/docs/il-design#section-protecting-against-cross-site-request-forgery-csrf
            }
            failureHandler:^(NSString *errorMessage) {
                // If an unexpected error happened during the login you'll receive it here.
            }
];
```

You'll also need to configure your application to call the `CleverSDK` when it receives a universal link.
This is done by implementing the `application:continueUserActivity:restorationHandler:` method of the AppDelegate:

```obj-C
- (BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    // handleURL returns a boolean indicating if the url was handled by Clever. If your application has other universal links you
    // can check to see if Clever handled the url with this boolean, and if it's false continue to handle the url in your application.
    return [CleverSDK handleURL:[userActivity webpageURL]];
}
```

Once the `CleverSDK` is instantiated you can start a login by calling the `login` method.

```obj-C
[CleverSDK login];
```

Alternatively if you know the Clever district ID of the user before the log in you can simplify their login experience by providing it when beginning the login.

```obj-C
[CleverSDK loginWithDistrictId:@"CLEVER_DISTRICT_ID"];
```

### Log in with Clever Button

To render a [Log in with Clever Button](https://dev.clever.com/docs/identity-api#section-log-in-with-clever) you can use the provided `CleverLoginButton` class.
In a `UIViewController` simply add the following code to the `viewDidLoad` method:

```obj-C
loginButton = [CleverLoginButton createLoginButton];
[self.view addSubview:loginButton];
```

The button is instantiated with a particular width and height.
You can update the width of the button by calling `setWidth:` method on the button and the height will be adjusted automatically to preserve the design.

```obj-C
[self.loginButton setWidth:300.0];
```

### Supporting Legacy iOS Instant Login

Before Clever released v2.0.0 of the `CleverSDK` Instant Login on iOS was powered using custom protocol urls (such as `com.clever://oauth/authorize`), not universal links.
If your application made use of these custom urls (or the old version of the `CleverSDK`) v2.0.0 of the SDK has additional features you can use to stay backwards compatible.

When you instantiate the SDK you should also provide the `LegacyIosClientId` client ID (this is the client ID you used specifically in your iOS app).

```obj-C
[CleverSDK startWithClientId:@"YOUR_CLIENT_ID" // Your Clever client ID
            LegacyIosClientId:@"YOUR_IOS_SPECIFIC_LEGACY_CLIENT_ID"
            RedirectURI:@"http://example.com" // A valid Clever redirect URI (that your app is configured to open with universal links)
            successHandler:^(NSString *code, BOOL validState) {
                // ...
            }
            failureHandler:^(NSString *errorMessage) {
                // ...
            }
];
```

Besides the above change, you also need to add some code to handle the iOS redirect URI.
This is done by implementing the `application:openURL:sourceApplication:annotation:` method of the AppDelegate:

```obj-C
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [CleverSDK handleURL:url];
}
```

You'll also need to add some information to your `Info.plist` to support the custom URI schemes.

1. Add `com.clever` to your [LSApplicationQueriesSchemes](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html#//apple_ref/doc/uid/TP40009250-SW14) so you can redirect directly to the Clever app.
2. Add your custom clever redirect URI (should look like `clever-YOUR_CLIENT_ID`) to [URL types](https://developer.apple.com/documentation/uikit/core_app/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app?language=objc), so the Clever app can open your application.

## Example

The `CleverSDK` project comes with a simple example application to show usage of the SDK. You can view the code for this example in the [/Example](./Example) directory, or you can open the project in Xcode and run the `Example` target.

## License

Apache 2.0
