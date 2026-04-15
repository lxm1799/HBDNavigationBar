#import "HBDAppearanceHelper.h"

@implementation HBDAppearanceHelper

+ (UINavigationBarAppearance *)appearanceWithBarTintColor:(nullable UIColor *)color
                                            backgroundImage:(nullable UIImage *)image
                                                 barAlpha:(CGFloat)alpha
                                            shadowHidden:(BOOL)shadowHidden
                                        titleAttributes:(nullable NSDictionary *)titleAttributes {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];

    if (alpha < 1.0 - FLT_EPSILON) {
        [appearance configureWithTransparentBackground];
        if (color) {
            appearance.backgroundColor = [color colorWithAlphaComponent:alpha];
        }
    } else if (image) {
        [appearance configureWithOpaqueBackground];
        appearance.backgroundImage = image;
    } else {
        if (color) {
            CGFloat r = 0, g = 0, b = 0, a = 0;
            [color getRed:&r green:&g blue:&b alpha:&a];
            if (a < 1.0 - FLT_EPSILON) {
                [appearance configureWithTransparentBackground];
                appearance.backgroundColor = color;
            } else {
                [appearance configureWithOpaqueBackground];
                appearance.backgroundColor = color;
            }
        } else {
            [appearance configureWithTransparentBackground];
        }
    }

    if (shadowHidden) {
        appearance.shadowColor = UIColor.clearColor;
    }

    if (titleAttributes) {
        appearance.titleTextAttributes = titleAttributes;
    }

    return appearance;
}

+ (void)applyAppearance:(UINavigationBarAppearance *)appearance
        toNavigationBar:(UINavigationBar *)navigationBar {
    if (!appearance || !navigationBar) return;

    navigationBar.standardAppearance = appearance;
    navigationBar.scrollEdgeAppearance = appearance;
}

+ (UINavigationBarAppearance *)transparentAppearance {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithTransparentBackground];
    appearance.backgroundColor = UIColor.clearColor;
    appearance.shadowColor = UIColor.clearColor;
    return appearance;
}

+ (UINavigationBarAppearance *)currentAppearanceForNavigationBar:(UINavigationBar *)navigationBar {
    if (!navigationBar) return nil;
    UINavigationBarAppearance *appearance = [navigationBar.standardAppearance copy];
    if (!appearance) {
        appearance = [[UINavigationBarAppearance alloc] init];
    }
    return appearance;
}

+ (UINavigationBarAppearance *)appearanceByBlendingFromColor:(UIColor *)fromColor
                                                    toColor:(UIColor *)toColor
                                                   progress:(CGFloat)progress
                                                shadowHidden:(BOOL)shadowHidden
                                            titleAttributes:(NSDictionary *)titleAttributes {
    UIColor *blendedColor = [self blendColorFrom:fromColor to:toColor progress:progress];
    return [self appearanceWithBarTintColor:blendedColor
                              backgroundImage:nil
                                   barAlpha:1.0
                              shadowHidden:shadowHidden
                          titleAttributes:titleAttributes];
}

+ (UIColor *)blendColorFrom:(UIColor *)fromColor to:(UIColor *)toColor progress:(CGFloat)progress {
    progress = fmaxf(0, fminf(1, (float)progress));

    if (!fromColor && !toColor) return UIColor.clearColor;
    if (!fromColor) return toColor;
    if (!toColor) return fromColor;
    if (progress <= 0) return fromColor;
    if (progress >= 1) return toColor;

    CGFloat fromR = 0, fromG = 0, fromB = 0, fromA = 1;
    [fromColor getRed:&fromR green:&fromG blue:&fromB alpha:&fromA];

    CGFloat toR = 0, toG = 0, toB = 0, toA = 1;
    [toColor getRed:&toR green:&toG blue:&toB alpha:&toA];

    CGFloat r = fromR + (toR - fromR) * progress;
    CGFloat g = fromG + (toG - fromG) * progress;
    CGFloat b = fromB + (toB - fromB) * progress;
    CGFloat a = fromA + (toA - fromA) * progress;

    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

@end
