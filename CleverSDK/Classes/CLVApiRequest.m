//
//  CLVApiRequest.m
//  CleverSDK
//
//  Created by Nikhil Pandit on 4/7/15.
//
//

#import "CLVCleverSDK.h"
#import "CLVApiRequest.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "CLVOAuthManager.h"

@implementation CLVApiRequest

+ (instancetype)sharedManager {
    static CLVApiRequest *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
        _sharedManager = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.clever.com/"]];
        _sharedManager.requestSerializer = [AFJSONRequestSerializer serializer];
        _sharedManager.responseSerializer = [AFJSONResponseSerializer serializer];
    });
    [_sharedManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [CLVOAuthManager accessToken]] forHTTPHeaderField:@"Authorization"];
    [_sharedManager.requestSerializer setValue:[NSString stringWithFormat:SDK_VERSION] forHTTPHeaderField:@"X-Clever-SDK-Version"];
    return _sharedManager;
}

+ (void)endpoint:(NSString *)endpoint params:(NSDictionary *)params
         success:(void (^)(NSURLSessionDataTask *task, id responseObject))successHandler
         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failureHandler {

    [[self sharedManager] GET:endpoint parameters:params progress:nil success:successHandler failure:failureHandler];
}

@end
