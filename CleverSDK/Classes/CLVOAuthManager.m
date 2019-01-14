#import "CLVOAuthManager.h"
#import <SafariServices/SafariServices.h>
#import "CLVCleverSDK.h"

@interface CLVOAuthManager ()

@property (nonatomic, strong) NSString *clientId;
@property (nonatomic, strong) NSString *iosClientId;
@property (nonatomic, strong) NSString *redirectUri;

@property (nonatomic, strong) NSString *state;
@property (atomic, assign) BOOL alreadyMissedCode;

@property (nonatomic, copy) void (^successHandler)(NSString *, BOOL);
@property (nonatomic, copy) void (^failureHandler)(NSString *);

+ (instancetype)sharedManager;

@end

@implementation CLVOAuthManager

+ (instancetype)sharedManager {
    static CLVOAuthManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

+ (void) startWithClientId:(NSString *)clientId IosClientId:(NSString *)iosClientId RedirectURI:(NSString *)redirectUri successHandler:(void (^)(NSString *code, BOOL validState))successHandler failureHandler:(void (^)(NSString *errorMessage))failureHandler {
//    [self startWithClientId:clientId IosClientId: iosClientId RedirectURI: redirectUri];
    CLVOAuthManager *manager = [self sharedManager];
    manager.clientId = clientId;
    manager.alreadyMissedCode = NO;
    manager.iosClientId = iosClientId;
    manager.redirectUri = redirectUri;
    manager.successHandler = successHandler;
    manager.failureHandler = failureHandler;
}

+ (NSString *)generateRandomString:(int)length {
    NSAssert(length % 2 == 0, @"Must generate random string with even length");
    NSMutableData *data = [NSMutableData dataWithLength:length / 2];
    NSAssert(SecRandomCopyBytes(kSecRandomDefault, length, [data mutableBytes]) == 0, @"Failure in SecRandomCopyBytes: %d", errno);
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(length)];
    const unsigned char *dataBytes = [data bytes];
    for (int i = 0; i < length / 2; ++i)
    {
        [hexString appendFormat:@"%02x", (unsigned int)dataBytes[i]];
    }
    return [NSString stringWithString:hexString];
}

+ (void)login {
    CLVOAuthManager *manager = [self sharedManager];
    manager.state = [self generateRandomString:32];
    
    
    NSString *iosRedirectURI = [NSString stringWithFormat:@"clever-%@://oauth", manager.iosClientId];

    NSString *universalLinkURLString = [NSString stringWithFormat:@"https://clever.com/oauth/authorize?response_type=code&client_id=%@&redirect_uri=%@&state=%@", manager.clientId, manager.redirectUri, manager.state];
    NSString *cleverAppURLString = [NSString stringWithFormat:@"com.clever://oauth/authorize?response_type=code&client_id=%@&redirect_uri=%@&state=%@&sdk_version=%@", manager.iosClientId, iosRedirectURI, manager.state, SDK_VERSION];

    
    // Switch to native Clever app if possible
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:cleverAppURLString]]) {
        if (@available(iOS 10, *)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cleverAppURLString] options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cleverAppURLString]];
        }
        
        return;
    }
    
    if (@available(iOS 10, *)) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:universalLinkURLString] options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:universalLinkURLString]];
    }

    
}

+ (BOOL)handleURL:(NSURL *)url {
    CLVOAuthManager *manager = [self sharedManager];
    if (!( // TODO add some path checking too maybe?
        [url.scheme isEqualToString:[NSString stringWithFormat:@"clever-%@", manager.iosClientId]] ||
          ([url.scheme isEqualToString:@"https"] && [url.host isEqualToString:@"clever.com"])
    )) {
        return NO;
    }
    
    NSString *query = url.query;
    NSMutableDictionary *kvpairs = [NSMutableDictionary dictionaryWithCapacity:1];
    NSArray *components = [query componentsSeparatedByString:@"&"];
    for (NSString *component in components) {
        NSArray *kv = [component componentsSeparatedByString:@"="];
        kvpairs[kv[0]] = kv[1];
    }

    // if code is missing, then this is a Clever Portal initiated login, and we should kick off the Oauth flow
    NSString *code = kvpairs[@"code"];
    if (!code) {
        CLVOAuthManager* manager = [self sharedManager];
        if (manager.alreadyMissedCode) {
            manager.alreadyMissedCode = NO;
            manager.failureHandler([NSString localizedStringWithFormat:@"Authorization failed. Please try logging in again."]);
            return YES;
        }
        manager.alreadyMissedCode = YES;
        [self login];
        return YES;
    }
    
    BOOL validState = NO;
    
    NSString *state = kvpairs[@"state"];
    if ([state isEqualToString:manager.state]) {
        validState = YES;
    }
    
    manager.successHandler(code, validState);
    return YES;
}

@end
