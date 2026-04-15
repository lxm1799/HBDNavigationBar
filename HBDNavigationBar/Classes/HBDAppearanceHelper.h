#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface HBDAppearanceHelper : NSObject

+ (UINavigationBarAppearance *)appearanceWithBarTintColor:(nullable UIColor *)color
                                            backgroundImage:(nullable UIImage *)image
                                                 barAlpha:(CGFloat)alpha
                                            shadowHidden:(BOOL)shadowHidden
                                        titleAttributes:(nullable NSDictionary *)titleAttributes;

+ (void)applyAppearance:(UINavigationBarAppearance *)appearance
        toNavigationBar:(UINavigationBar *)navigationBar;

+ (UINavigationBarAppearance *)transparentAppearance;

+ (UINavigationBarAppearance *)currentAppearanceForNavigationBar:(UINavigationBar *)navigationBar;

+ (UINavigationBarAppearance *)appearanceByBlendingFromColor:(nullable UIColor *)fromColor
                                                    toColor:(nullable UIColor *)toColor
                                                   progress:(CGFloat)progress
                                                shadowHidden:(BOOL)shadowHidden
                                            titleAttributes:(nullable NSDictionary *)titleAttributes;

+ (UIColor *)blendColorFrom:(UIColor *)fromColor to:(UIColor *)toColor progress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
