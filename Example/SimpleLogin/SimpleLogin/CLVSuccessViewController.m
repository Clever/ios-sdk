//
//  CLVSuccessViewController.m
//  SimpleLogin
//
//  Created by Nikhil Pandit on 4/9/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import "CLVSuccessViewController.h"
#import <CleverSDK/CLVCleverSDK.h>

@interface CLVSuccessViewController ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailLabel;
@property (nonatomic, weak) IBOutlet UILabel *accessTokenLabel;
@property (nonatomic, weak) IBOutlet UILabel *readMoreLabel;

@property (nonatomic, strong) NSString *accessToken;

@end

@implementation CLVSuccessViewController

- (id)initWithAccessToken:(NSString *)accessToken {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.accessToken = accessToken;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.accessTokenLabel.text = self.accessToken;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation
- (void)viewWillDisappear:(BOOL)animated {
    [CLVOAuthManager logout];
}
@end
