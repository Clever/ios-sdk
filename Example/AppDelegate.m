#import "AppDelegate.h"
#import "LoginViewController.h"
#import "SuccessViewController.h"
#import "CleverSDK.h"

@interface AppDelegate ()

@property (nonatomic, strong) UINavigationController* navigationController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    LoginViewController *vc = [[LoginViewController alloc] initWithNibName:nil bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = self.navigationController;

    // Start the CleverSDK with your client
    // Do not forget to replace CLIENT_ID with your client_id
    [CleverSDK startWithClientId:@"CLIENT_ID" RedirectURI:@"http://example.com" successHandler:^(NSString *code, BOOL validState) {
        SuccessViewController *vc = [[SuccessViewController alloc] initWithCode:code];
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
    return [CleverSDK handleURL:url];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity {
    return [CleverSDK handleURL:userActivity.webpageURL];
}
@end
