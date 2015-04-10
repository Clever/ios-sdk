//
//  CLVSuccessViewController.m
//  SimpleLogin
//
//  Created by Nikhil Pandit on 4/9/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import "CLVSuccessViewController.h"

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
