#import <Foundation/Foundation.h>
#import "CleverLoginButton.h"

#define SDK_VERSION @"iOS-2.0.0"

@interface CleverSDK : NSObject

+ (void)startWithClientId:(NSString *)clientId LegacyIosClientId:(NSString *)legacyIosClientId RedirectURI:(NSString *)redirectUri successHandler:(void (^)(NSString *code, BOOL validState))successHandler failureHandler:(void (^)(NSString *errorMessage))failureHandler;

+ (void)startWithClientId:(NSString *)clientId RedirectURI:(NSString *)redirectUri successHandler:(void (^)(NSString *code, BOOL validState))successHandler failureHandler:(void (^)(NSString *errorMessage))failureHandler;

+ (BOOL)handleURL:(NSURL *)url;

+ (void)login;

+ (void)loginWithDistrictId:(NSString *)districtId;

@end
