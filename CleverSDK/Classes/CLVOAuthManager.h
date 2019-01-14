#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLVOAuthManager : NSObject

+ (void)startWithClientId:(NSString *)clientId IosClientId:(NSString *)iosClientId RedirectURI:(NSString *)redirectUri successHandler:(void (^)(NSString *code, BOOL validState))successHandler failureHandler:(void (^)(NSString *errorMessage))failureHandler;

+ (BOOL)handleURL:(NSURL *)url;

+ (void)login;

@end

NS_ASSUME_NONNULL_END
