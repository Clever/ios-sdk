#import "CLVAppDelegate.h"
#import "CLVLoginViewController.h"
#import "CLVSuccessViewController.h"
#import "CLVCleverSDK.h"

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
    [CLVOAuthManager startWithClientId:@"CLIENT_ID" RedirectURI:@"http://example.com" successHandler:^(NSString *code, BOOL validState) {
        CLVSuccessViewController *vc = [[CLVSuccessViewController alloc] initWithCode:code];
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.navigationController pushViewController:vc animated:YES];
    } failureHandler:^(NSString *errorMessage) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message: errorMessage
                                     preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [vc presentViewController:alert animated:YES completion:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
        return;
    }];

    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [CLVOAuthManager handleURL:url];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity {
    return [CLVOAuthManager handleURL:userActivity.webpageURL];
}
@end
