#import "HBDNavigationBar.h"
#import "HBDAppearanceHelper.h"
#import <objc/runtime.h>

static CGFloat HBDHairlineWidthForView(UIView *view) {
    if (@available(iOS 13.0, *)) {
        UIScreen *screen = view.window.windowScene.screen;
        if (screen.scale > 0) {
            return 1.f / screen.scale;
        }
    }
    if (view.traitCollection.displayScale > 0) {
        return 1.f / view.traitCollection.displayScale;
    }
    return 1.f;
}

static void hbd_exchangeImplementations(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static BOOL HBDIsiOS26OrLater(void) {
    if (@available(iOS 26.0, *)) {
        return YES;
    }
    return NO;
}

@interface HBDNavigationBar ()

@property(nonatomic, strong, readwrite) UIImageView *shadowImageView;
@property(nonatomic, strong, readwrite) UIVisualEffectView *fakeView;
@property(nonatomic, strong, readwrite) UIImageView *backgroundImageView;
@property(nonatomic, strong, readwrite) UINavigationBarAppearance *hbd_currentAppearance;

@end

@implementation HBDNavigationBar

#pragma mark - iOS 26 Appearance

- (UINavigationBarAppearance *)hbd_currentAppearance {
    if (@available(iOS 13.0, *)) {
        if (!_hbd_currentAppearance) {
            _hbd_currentAppearance = [[UINavigationBarAppearance alloc] init];
            [_hbd_currentAppearance configureWithTransparentBackground];
            _hbd_currentAppearance.backgroundColor = UIColor.clearColor;
            _hbd_currentAppearance.shadowColor = UIColor.clearColor;
        }
        return _hbd_currentAppearance;
    }
    return nil;
}

- (void)hbd_applyAppearanceWithBarTintColor:(UIColor *)color
                            backgroundImage:(UIImage *)image
                                 barAlpha:(CGFloat)alpha
                            shadowHidden:(BOOL)shadowHidden
                        titleAttributes:(NSDictionary *)titleAttributes {
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [HBDAppearanceHelper appearanceWithBarTintColor:color
                                                                                backgroundImage:image
                                                                                     barAlpha:alpha
                                                                                shadowHidden:shadowHidden
                                                                            titleAttributes:titleAttributes];
        self.hbd_currentAppearance = appearance;
        [HBDAppearanceHelper applyAppearance:appearance toNavigationBar:self];
    }
}

#pragma mark - hitTest

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.isUserInteractionEnabled || self.isHidden || self.alpha < 0.01) {
        return nil;
    }

    UIView *view = [super hitTest:point withEvent:event];
    NSString *viewName = [[[view classForCoder] description] stringByReplacingOccurrencesOfString:@"_" withString:@""];

    NSArray *exactMatchArray = @[
        @"UINavigationBarContentView",
        @"UIButtonBarStackView",
        @"UIKit.NavigationBarContentView",
        NSStringFromClass([self class])
    ];

    BOOL matched = [exactMatchArray containsObject:viewName];
    if (!matched) {
        matched = [viewName containsString:@"ContentView"] || [viewName containsString:@"BarBackground"];
    }

    if (matched) {
        if (HBDIsiOS26OrLater()) {
            UINavigationBarAppearance *appearance = self.standardAppearance;
            if (appearance.backgroundImage) {
                if (self.alpha < 0.01) {
                    return nil;
                }
            } else {
                UIColor *bgColor = appearance.backgroundColor;
                if (bgColor) {
                    CGFloat r, g, b, a;
                    [bgColor getRed:&r green:&g blue:&b alpha:&a];
                    if (a < 0.01) {
                        return nil;
                    }
                } else if (self.alpha < 0.01) {
                    return nil;
                }
            }
        } else {
            if (self.backgroundImageView.image) {
                if (self.backgroundImageView.alpha < 0.01) {
                    return nil;
                }
            } else if (self.fakeView.alpha < 0.01) {
                return nil;
            }
        }
    }

    return view;
}

#pragma mark - layoutSubviews

- (void)layoutSubviews {
    [super layoutSubviews];
    if (HBDIsiOS26OrLater()) {
        return;
    }
    CGFloat hairlineWidth = HBDHairlineWidthForView(self);
    if (self.fakeView.superview) {
        self.fakeView.frame = self.fakeView.superview.bounds;
    }
    if (self.backgroundImageView.superview) {
        self.backgroundImageView.frame = self.backgroundImageView.superview.bounds;
    }
    if (self.shadowImageView.superview) {
        self.shadowImageView.frame = CGRectMake(0, CGRectGetHeight(self.shadowImageView.superview.bounds) - hairlineWidth, CGRectGetWidth(self.shadowImageView.superview.bounds), hairlineWidth);
    }
}

#pragma mark - Bar Tint Color

- (void)setBarTintColor:(UIColor *)barTintColor {
    if (HBDIsiOS26OrLater()) {
        if (@available(iOS 13.0, *)) {
            [self hbd_applyAppearanceWithBarTintColor:barTintColor
                                        backgroundImage:self.hbd_currentAppearance.backgroundImage
                                             barAlpha:1.0
                                        shadowHidden:self.hbd_currentAppearance.shadowColor == UIColor.clearColor
                                    titleAttributes:self.hbd_currentAppearance.titleTextAttributes];
        }
        return;
    }
    self.fakeView.subviews.lastObject.backgroundColor = barTintColor;
    [self makeSureFakeView];
}

#pragma mark - Fake View (Legacy, iOS 26 returns nil)

- (UIVisualEffectView *)fakeView {
    if (HBDIsiOS26OrLater()) {
        return nil;
    }
    if (!_fakeView) {
        UIView *firstSubview = self.subviews.firstObject;
        if (!firstSubview) return nil;
        [super setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        _fakeView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        _fakeView.userInteractionEnabled = NO;
        _fakeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [firstSubview insertSubview:_fakeView atIndex:0];
    }
    return _fakeView;
}

#pragma mark - Background Image View (Legacy, iOS 26 returns nil)

- (UIImageView *)backgroundImageView {
    if (HBDIsiOS26OrLater()) {
        return nil;
    }
    if (!_backgroundImageView) {
        UIView *firstSubview = self.subviews.firstObject;
        if (!firstSubview) return nil;
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.userInteractionEnabled = NO;
        _backgroundImageView.contentScaleFactor = 1;
        _backgroundImageView.contentMode = UIViewContentModeScaleToFill;
        _backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [firstSubview insertSubview:_backgroundImageView aboveSubview:self.fakeView];
    }
    return _backgroundImageView;
}

#pragma mark - Back Button Label

- (UILabel *)backButtonLabel {
    if (@available(iOS 11, *)); else return nil;
    UIView *navigationBarContentView = [self hbd_contentView];
    if (!navigationBarContentView) return nil;

    __block UILabel *backButtonLabel = nil;
    [navigationBarContentView.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView *_Nonnull subview, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([subview isKindOfClass:NSClassFromString(@"_UIButtonBarButton")]) {
            UIButton *titleButton = (UIButton *) [self getViewFromContext:subview withKeyPath:@"visualProvider.titleButton"];
            if (titleButton) {
                backButtonLabel = titleButton.titleLabel;
            }
            if (!backButtonLabel && [subview isKindOfClass:[UIButton class]]) {
                backButtonLabel = [(UIButton *)subview titleLabel];
            }
            *stop = YES;
        }
    }];
    return backButtonLabel;
}

#pragma mark - Content Hidden

- (void)hbd_setContentHidden:(BOOL)hidden {
    UIView *contentView = [self hbd_contentView];
    if (contentView) {
        contentView.alpha = hidden ? 0.0 : 1.0;
    }
}

#pragma mark - Content View

- (UIView *)hbd_contentView {
    UIView *contentView = [self getViewFromContext:self withKeyPath:@"visualProvider.contentView"];
    if (contentView) {
        return contentView;
    }

    for (UIView *subview in self.subviews) {
        NSString *viewName = NSStringFromClass(subview.class);
        if ([viewName containsString:@"ContentView"]) {
            return subview;
        }
    }

    if (HBDIsiOS26OrLater()) {
        return [self hbd_findContentViewByRecursiveSearch:self depth:3];
    }

    return nil;
}

- (UIView *)hbd_findContentViewByRecursiveSearch:(UIView *)view depth:(NSInteger)depth {
    if (depth <= 0) return nil;
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass(subview.class);
        if ([className containsString:@"ContentView"]) {
            return subview;
        }
        UIView *found = [self hbd_findContentViewByRecursiveSearch:subview depth:depth - 1];
        if (found) return found;
    }
    return nil;
}

#pragma mark - Background Image

- (void)setBackgroundImage:(UIImage *)backgroundImage forBarMetrics:(UIBarMetrics)barMetrics {
    if (HBDIsiOS26OrLater()) {
        if (@available(iOS 13.0, *)) {
            [self hbd_applyAppearanceWithBarTintColor:self.hbd_currentAppearance.backgroundColor
                                        backgroundImage:backgroundImage
                                             barAlpha:1.0
                                        shadowHidden:self.hbd_currentAppearance.shadowColor == UIColor.clearColor
                                    titleAttributes:self.hbd_currentAppearance.titleTextAttributes];
        }
        return;
    }
    self.backgroundImageView.image = backgroundImage;
    [self makeSureFakeView];
}

#pragma mark - Background View

- (UIView *)hbd_backgroundView {
    if (HBDIsiOS26OrLater()) {
        return nil;
    }
    return [self getViewFromContext:self withKeyPath:@"_backgroundView"];
}

#pragma mark - Translucent

- (void)setTranslucent:(BOOL)translucent {
    if (HBDIsiOS26OrLater()) {
        [super setTranslucent:YES];
        return;
    }
    [super setTranslucent:YES];
}

#pragma mark - Shadow Image

- (void)setShadowImage:(UIImage *)shadowImage {
    if (HBDIsiOS26OrLater()) {
        if (@available(iOS 13.0, *)) {
            [self hbd_applyAppearanceWithBarTintColor:self.hbd_currentAppearance.backgroundColor
                                        backgroundImage:self.hbd_currentAppearance.backgroundImage
                                             barAlpha:1.0
                                        shadowHidden:(shadowImage != nil)
                                    titleAttributes:self.hbd_currentAppearance.titleTextAttributes];
        }
        return;
    }
    self.shadowImageView.image = shadowImage;
    if (shadowImage) {
        self.shadowImageView.backgroundColor = nil;
    } else {
        self.shadowImageView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:77.0 / 255];
    }
}

#pragma mark - Shadow Image View (Legacy, iOS 26 returns nil)

- (UIImageView *)shadowImageView {
    if (HBDIsiOS26OrLater()) {
        return nil;
    }
    if (!_shadowImageView) {
        UIView *firstSubview = self.subviews.firstObject;
        if (!firstSubview) return nil;
        [super setShadowImage:[UIImage new]];
        _shadowImageView = [[UIImageView alloc] init];
        _shadowImageView.userInteractionEnabled = NO;
        _shadowImageView.contentScaleFactor = 1;
        _shadowImageView.layer.allowsEdgeAntialiasing = YES;
        [firstSubview insertSubview:_shadowImageView aboveSubview:self.backgroundImageView];
    }
    return _shadowImageView;
}

#pragma mark - Make Sure Fake View (Legacy, iOS 26 no-op)

- (void)makeSureFakeView {
    if (HBDIsiOS26OrLater()) {
        return;
    }
    [UIView setAnimationsEnabled:NO];
    UIView *firstSubview = self.subviews.firstObject;
    if (!firstSubview) {
        [UIView setAnimationsEnabled:YES];
        return;
    }

    if (!self.fakeView.superview) {
        [firstSubview insertSubview:_fakeView atIndex:0];
        self.fakeView.frame = self.fakeView.superview.bounds;
    }

    if (!self.shadowImageView.superview) {
        [firstSubview insertSubview:_shadowImageView aboveSubview:self.backgroundImageView];
        CGFloat hairlineWidth = HBDHairlineWidthForView(self);
        self.shadowImageView.frame = CGRectMake(0, CGRectGetHeight(self.shadowImageView.superview.bounds) - hairlineWidth, CGRectGetWidth(self.shadowImageView.superview.bounds), hairlineWidth);
    }

    if (!self.backgroundImageView.superview) {
        [firstSubview insertSubview:_backgroundImageView aboveSubview:self.fakeView];
        self.backgroundImageView.frame = self.backgroundImageView.superview.bounds;
    }
    [UIView setAnimationsEnabled:YES];
}

#pragma mark - getViewFromContext:withKeyPath: (iOS 26 Compatible)

- (UIView *)getViewFromContext:(id)context withKeyPath:(NSString *)keyPath {
    if (!context || !keyPath) {
        return nil;
    }

    if (@available(iOS 26.0, *)) {
        if ([context isKindOfClass:[UIView class]]) {
            UIView *view = (UIView *)context;
            __block UIView *contentView = nil;

            [view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([NSStringFromClass(item.class) containsString:@"ContentView"]) {
                    contentView = item;
                    *stop = YES;
                }
            }];

            if (contentView) return contentView;
        }

        NSArray *components = [keyPath componentsSeparatedByString:@"."];
        if (components.count > 0) {
            NSString *providerKey = components.firstObject;
            NSObject *provider = nil;
            @try {
                provider = [context valueForKey:providerKey];
            } @catch (NSException *exception) {
#ifdef DEBUG
                NSLog(@"[HBDNavigationBar] KVC valueForKey failed: %@ for key: %@", exception, providerKey);
#endif
                provider = nil;
            }

            if (provider && components.count > 1) {
                NSString *targetKey = components.lastObject;
                __block UIView *result = nil;

                unsigned int ivarCount = 0;
                Ivar *ivars = class_copyIvarList([provider class], &ivarCount);

                if (ivars) {
                    for (unsigned int i = 0; i < ivarCount && !result; i++) {
                        Ivar ivar = ivars[i];
                        const char *ivarName = ivar_getName(ivar);

                        if (ivarName) {
                            NSString *ivarNameString = [NSString stringWithUTF8String:ivarName];
                            if ([ivarNameString containsString:targetKey]) {
                                @try {
                                    result = object_getIvar(provider, ivar);
                                } @catch (NSException *exception) {
#ifdef DEBUG
                                    NSLog(@"[HBDNavigationBar] object_getIvar failed: %@", exception);
#endif
                                    result = nil;
                                }
                            }
                        }
                    }
                    free(ivars);
                }

                if (!result) {
                    result = [self hbd_findViewInSubviewsOf:provider withNameHint:targetKey depth:3];
                }

                return result;
            }
        }

        return nil;
    }

    UIView *result = nil;
    @try {
        result = [context valueForKeyPath:keyPath];
    } @catch (NSException *exception) {
#ifdef DEBUG
        NSLog(@"[HBDNavigationBar] KVC valueForKeyPath failed: %@ for keyPath: %@", exception, keyPath);
#endif
        result = nil;
    }
    return result;
}

- (UIView *)hbd_findViewInSubviewsOf:(UIView *)view withNameHint:(NSString *)hint depth:(NSInteger)depth {
    if (!view || depth <= 0 || !hint) return nil;
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass(subview.class);
        if ([className containsString:hint] || [className.lowercaseString containsString:hint.lowercaseString]) {
            return subview;
        }
        UIView *found = [self hbd_findViewInSubviewsOf:subview withNameHint:hint depth:depth - 1];
        if (found) return found;
    }
    return nil;
}

@end


@implementation UILabel (NavigationBarTransition)

- (UIColor *)hbd_specifiedTextColor {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHbd_specifiedTextColor:(UIColor *)color {
    objc_setAssociatedObject(self, @selector(hbd_specifiedTextColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)load {
    if (@available(iOS 11, *)); else return;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        hbd_exchangeImplementations(class, @selector(setAttributedText:), @selector(hbd_setAttributedText:));
    });
}

- (void)hbd_setAttributedText:(NSAttributedString *)attributedText {
    if (self.hbd_specifiedTextColor) {
        NSMutableAttributedString *mutableAttributedText = [attributedText isKindOfClass:NSMutableAttributedString.class] ? attributedText : [attributedText mutableCopy];
        [mutableAttributedText addAttributes:@{NSForegroundColorAttributeName: self.hbd_specifiedTextColor} range:NSMakeRange(0, mutableAttributedText.length)];
        attributedText = mutableAttributedText;
    }
    [self hbd_setAttributedText:attributedText];
}


@end
