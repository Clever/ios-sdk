//
//  CLVLoginViewController.m
//  SimpleLogin
//
//  Created by Nikhil Pandit on 4/9/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import "CLVLoginViewController.h"
#import <CleverSDK/CLVCleverSDK.h>
#import "CLVSuccessViewController.h"

@interface CLVLoginViewController ()

@property (nonatomic, strong) CLVLoginButton *loginButton;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailLabel;

@end

@implementation CLVLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.navigationBar.translucent = NO;
    
    __weak typeof(self) weakSelf = self;
    self.loginButton = [CLVLoginButton buttonInViewController:self successHander:^(NSString *accessToken) {
        // success handler
        __strong typeof(self) strongSelf = weakSelf;
        CLVSuccessViewController *vc = [[CLVSuccessViewController alloc] initWithAccessToken:accessToken];
        [strongSelf.navigationController pushViewController:vc animated:YES];
    } failureHandler:^(NSString *errorMessage) {
        // failure handler
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:errorMessage
                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];
    
    CGRect frame = self.loginButton.frame;
    CGSize size = [UIScreen mainScreen].bounds.size;
    [self.loginButton setOrigin:CGPointMake((size.width - frame.size.width) / 2,
                                            self.detailLabel.frame.origin.y + self.detailLabel.frame.size.height + 50)];
    
    [self.view addSubview:self.loginButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
