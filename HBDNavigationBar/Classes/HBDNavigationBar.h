#import <UIKit/UIKit.h>

@class UINavigationBarAppearance;

@interface HBDNavigationBar : UINavigationBar

@property(nonatomic, strong, readonly) UIImageView *shadowImageView;
@property(nonatomic, strong, readonly) UIVisualEffectView *fakeView;
@property(nonatomic, strong, readonly) UIImageView *backgroundImageView;
@property(nonatomic, strong, readonly) UILabel *backButtonLabel;
@property(nonatomic, strong, readonly) UIView *hbd_backgroundView;

@property(nonatomic, strong, readonly) UINavigationBarAppearance *hbd_currentAppearance API_AVAILABLE(ios(13.0));

- (void)hbd_setContentHidden:(BOOL)hidden;

- (void)hbd_applyAppearanceWithBarTintColor:(nullable UIColor *)color
                            backgroundImage:(nullable UIImage *)image
                                 barAlpha:(CGFloat)alpha
                            shadowHidden:(BOOL)shadowHidden
                        titleAttributes:(nullable NSDictionary *)titleAttributes API_AVAILABLE(ios(13.0));

@end


@interface UILabel (NavigationBarTransition)

@property(nonatomic, strong) UIColor *hbd_specifiedTextColor;

@end
