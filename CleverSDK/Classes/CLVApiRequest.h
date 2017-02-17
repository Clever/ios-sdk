//
//  CLVApiRequest.h
//  CleverSDK
//
//  Created by Nikhil Pandit on 4/7/15.
//
//

#import <AFNetworking/AFHTTPSessionManager.h>

@interface CLVApiRequest : AFHTTPSessionManager

+ (instancetype)sharedManager;

+ (void)endpoint:(NSString *)endpoint params:(NSDictionary *)params
         success:(void (^)(NSURLSessionDataTask *task, id responseObject))successHandler
         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failureHandler;

@end
