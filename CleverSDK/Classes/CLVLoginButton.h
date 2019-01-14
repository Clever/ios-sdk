#import <UIKit/UIKit.h>

@interface CLVLoginButton : UIButton

/**
 Create a `CLVLoginButton`
 */
+ (CLVLoginButton *)createLoginButton;

/**
 Set the origin of the button. This is the preferred method of manipulating the button frame.
 */
- (void)setOrigin:(CGPoint)origin;

/**
 Set the button width. The button height is always.
 The text will be always centered in the button, and the Clever C will be left aligned.
 */
- (void)setWidth:(CGFloat)width;

@end
