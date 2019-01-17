#import "LoginViewController.h"
#import "CleverSDK.h"

@interface LoginViewController ()

@property (nonatomic, weak) IBOutlet UILabel *detailLabel;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    
    // Creates the "Log in with Clever" button
    CleverLoginButton *loginButton = [CleverLoginButton createLoginButton];
    
    CGRect frame = loginButton.frame;
    CGSize size = [UIScreen mainScreen].bounds.size;
    [loginButton setOrigin:CGPointMake((size.width - frame.size.width) / 2, self.detailLabel.frame.origin.y + self.detailLabel.frame.size.height + 50)];
    [self.view addSubview:loginButton];
}

@end
