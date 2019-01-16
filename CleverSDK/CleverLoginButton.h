#import <UIKit/UIKit.h>

@interface CleverLoginButton : UIButton

+ (CleverLoginButton *)createLoginButton;

- (void)setOrigin:(CGPoint)origin;

- (void)setWidth:(CGFloat)width;

@end
