#import "CLVLoginViewController.h"
#import "CLVCleverSDK.h"
#import "CLVSuccessViewController.h"

@interface CLVLoginViewController ()

@property (nonatomic, weak) IBOutlet UILabel *detailLabel;

@end

@implementation CLVLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    
    // Creates the "Log in with Clever" button
    CLVLoginButton *loginButton = [CLVLoginButton createLoginButton];
    
    CGRect frame = loginButton.frame;
    CGSize size = [UIScreen mainScreen].bounds.size;
    [loginButton setOrigin:CGPointMake((size.width - frame.size.width) / 2, self.detailLabel.frame.origin.y + self.detailLabel.frame.size.height + 50)];
    [self.view addSubview:loginButton];
}

@end
