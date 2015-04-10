//
//  CLVLoginButton.m
//  CleverSDK
//
//  Created by Nikhil Pandit on 4/3/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import "CLVLoginButton.h"
#import "CLVOAuthWebViewController.h"
#import "CLVOAuthManager.h"
#import <PocketSVG/PocketSVG.h>

@interface CLVLoginButton ()

@property (nonatomic, weak) UIViewController *parent;

@end

@implementation CLVLoginButton

+ (CLVLoginButton *)buttonInViewController:(UIViewController *)viewController
                             successHander:(void (^)(NSString *accessToken))successHandler
                            failureHandler:(void (^)(NSString *errorMessage))failureHandler {
    
    CLVLoginButton *button = [CLVLoginButton buttonWithType:UIButtonTypeCustom];
    
    button.frame = CGRectMake(0, 0, 248, 45.6);
    
    UIImage *bgImage = [CLVLoginButton backgroundImageForButton];
    [button setBackgroundImage:bgImage forState:UIControlStateNormal];
    [button setImage:[CLVLoginButton cleverIconWithSize:button.bounds.size] forState:UIControlStateNormal];
    [button setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, button.bounds.size.height / 2)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:@"Login with Clever" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:button.bounds.size.height / 2];
    
    button.parent = viewController;
    
    [button addTarget:button action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [CLVOAuthManager successHandler:successHandler failureHandler:failureHandler];
    
    return button;
}

- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (void)scale:(CGFloat)scaleFactor {
    CGRect frame = self.frame;
    CGFloat w = frame.size.width;
    CGFloat h = frame.size.height;
    w = w * scaleFactor;
    h = h * scaleFactor;
    frame.size = CGSizeMake(w, h);
    self.frame = frame;
}

- (void)scaleWithWidth:(CGFloat)width {
    CGRect frame = self.frame;
    CGFloat w = frame.size.width;
    CGFloat h = frame.size.height;
    CGFloat scaleFactor = width / w;
    w = width;
    h = h * scaleFactor;
    frame.size = CGSizeMake(w, h);
    self.frame = frame;
}

- (void)scaleWithHeight:(CGFloat)height {
    CGRect frame = self.frame;
    CGFloat w = frame.size.width;
    CGFloat h = frame.size.height;
    CGFloat scaleFactor = height / h;
    w = w * scaleFactor;
    h = height;
    frame.size = CGSizeMake(w, h);
    self.frame = frame;
}

- (void)loginButtonPressed:(id)loginButton {
    CLVOAuthWebViewController *vc = [[CLVOAuthWebViewController alloc] initWithParent:self.parent];
    [self.parent presentViewController:vc animated:YES completion:nil];
}

+ (UIImage *)backgroundImageForButton {
    UIColor *color = [UIColor colorWithRed:0.18 green:0.40 blue:0.66 alpha:1.0];
    CGFloat cornerRadius = 3.0;
    CGFloat scale = [UIScreen mainScreen].scale;
    
    CGFloat size = 1.0 + 2 * cornerRadius;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, cornerRadius + 1.0, 0.0);
    CGPathAddArcToPoint(path, NULL, size, 0.0, size, cornerRadius, cornerRadius);
    CGPathAddLineToPoint(path, NULL, size, cornerRadius + 1.0);
    CGPathAddArcToPoint(path, NULL, size, size, cornerRadius + 1.0, size, cornerRadius);
    CGPathAddLineToPoint(path, NULL, cornerRadius, size);
    CGPathAddArcToPoint(path, NULL, 0.0, size, 0.0, cornerRadius + 1.0, cornerRadius);
    CGPathAddLineToPoint(path, NULL, 0.0, cornerRadius);
    CGPathAddArcToPoint(path, NULL, 0.0, 0.0, cornerRadius, 0.0, cornerRadius);
    CGPathCloseSubpath(path);
    CGContextAddPath(context, path);
    CGPathRelease(path);
    CGContextFillPath(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image stretchableImageWithLeftCapWidth:cornerRadius topCapHeight:cornerRadius];
}

+ (UIImage *)cleverIconWithSize:(CGSize)size {
    // the size passed in is the size of the whole button
    // we mostly focus on the height of the button to get the size of the icon
    UIColor *color = [UIColor colorWithRed:0.18 green:0.40 blue:0.66 alpha:1.0];
    size.height = size.height * 0.6;
    size.width = size.height;
    CGFloat scale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform transformValue = CGAffineTransformMakeScale(size.width / 180.0, size.height / 180.0);
    const CGAffineTransform *transform = &transformValue;
    CGMutablePathRef path = CGPathCreateMutable();
    
    // white background for the icon
    CGFloat cornerRadius = 25.0;
    CGFloat side = 1.0 + 7 * cornerRadius;
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGPathMoveToPoint(path, transform, cornerRadius + 1.0, 0.0);
    CGPathAddArcToPoint(path, transform, side, 0.0, side, cornerRadius, cornerRadius);
    CGPathAddLineToPoint(path, transform, side, cornerRadius + 1.0);
    CGPathAddArcToPoint(path, transform, side, side, cornerRadius + 1.0, side, cornerRadius);
    CGPathAddLineToPoint(path, transform, cornerRadius, side);
    CGPathAddArcToPoint(path, transform, 0.0, side, 0.0, cornerRadius + 1.0, cornerRadius);
    CGPathAddLineToPoint(path, transform, 0.0, cornerRadius);
    CGPathAddArcToPoint(path, transform, 0.0, 0.0, cornerRadius, 0.0, cornerRadius);
    CGPathCloseSubpath(path);
    CGContextAddPath(context, path);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);
    
    // the Clever C
    CGPathRef cleverC = [PocketSVG pathFromSVGString:@"d=\"M76.125,147.269c-39.326,0-68.534-30.354-68.534-68.725v-0.382c0-37.99,28.636-69.107,69.68-69.107c25.199,0,40.28,8.4,52.689,20.618l-18.708,21.572c-10.309-9.354-20.808-15.081-34.171-15.081c-22.526,0-38.753,18.708-38.753,41.617v0.382c0,22.908,15.845,41.999,38.753,41.999c15.272,0,24.626-6.109,35.126-15.654l18.708,18.899C117.169,138.105,101.897,147.269,76.125,147.269z\""];
    cleverC = CGPathCreateCopyByTransformingPath(cleverC, transform);
    CGAffineTransform moveTransform = CGAffineTransformFromString(@"{1,0,0,1,2,1.8}");
    cleverC = CGPathCreateCopyByTransformingPath(cleverC, &moveTransform);
    CGContextAddPath(context, cleverC);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillPath(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
