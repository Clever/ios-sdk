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

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailLabel;

@end

@implementation CLVLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.navigationBar.translucent = NO;
    
    // Create a "Log in with Clever" button (optional)
    CLVLoginButton *loginButton = [CLVLoginButton createLoginButton];
    
    CGRect frame = loginButton.frame;
    CGSize size = [UIScreen mainScreen].bounds.size;
    [loginButton setOrigin:CGPointMake((size.width - frame.size.width) / 2,
                                            self.detailLabel.frame.origin.y + self.detailLabel.frame.size.height + 50)];
    [self.view addSubview:loginButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
