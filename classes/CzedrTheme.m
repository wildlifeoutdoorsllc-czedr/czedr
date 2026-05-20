//
//  CzedrTheme.m
//

#import "CzedrTheme.h"

@implementation CzedrTheme

+ (UIColor *)orangeField {
    return [UIColor colorWithRed:245.0/255.0 green:130.0/255.0 blue:32.0/255.0 alpha:1.0];
}

+ (UIColor *)redPrimary {
    return [UIColor colorWithRed:227.0/255.0 green:30.0/255.0 blue:36.0/255.0 alpha:1.0];
}

+ (UIColor *)charcoalButton {
    return [UIColor colorWithRed:88.0/255.0 green:89.0/255.0 blue:91.0/255.0 alpha:1.0];
}

+ (UIColor *)gridTile {
    return [UIColor colorWithRed:201.0/255.0 green:74.0/255.0 blue:31.0/255.0 alpha:1.0];
}

+ (UIColor *)taglineRed {
    return [self redPrimary];
}

+ (UIColor *)mutedText {
    return [UIColor colorWithRed:98.0/255.0 green:100.0/255.0 blue:104.0/255.0 alpha:1.0];
}

+ (UIColor *)darkBackground {
    return [UIColor colorWithRed:42.0/255.0 green:42.0/255.0 blue:44.0/255.0 alpha:1.0];
}

+ (UIColor *)darkSurface {
    return [UIColor colorWithRed:53.0/255.0 green:53.0/255.0 blue:56.0/255.0 alpha:1.0];
}

+ (UIColor *)lightText {
    return [UIColor colorWithRed:231.0/255.0 green:236.0/255.0 blue:243.0/255.0 alpha:1.0];
}

+ (UIColor *)captionOnDark {
    return [UIColor colorWithRed:176.0/255.0 green:181.0/255.0 blue:188.0/255.0 alpha:1.0];
}

+ (UIColor *)balanceGreen {
    return [UIColor colorWithRed:50.0/255.0 green:205.0/255.0 blue:90.0/255.0 alpha:1.0];
}

+ (UIFont *)avenir:(CGFloat)size weight:(NSString *)weight {
    NSString *name = [weight isEqualToString:@"heavy"] ? @"Avenir-Heavy" : @"Avenir-Roman";
    UIFont *font = [UIFont fontWithName:name size:size];
    return font ?: [UIFont systemFontOfSize:size];
}

+ (BOOL)isValidEmailAddress:(NSString *)email
{
    NSString *trimmed = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return NO;
    }
    NSRange at = [trimmed rangeOfString:@"@"];
    if (at.location == NSNotFound || at.location == 0 || at.location >= trimmed.length - 1) {
        return NO;
    }
    NSString *domain = [trimmed substringFromIndex:at.location + 1];
    return [domain rangeOfString:@"."].location != NSNotFound;
}

+ (void)applyGlobalAppearance {
    UIColor *dark = [self darkBackground];
    [[UINavigationBar appearance] setBarTintColor:[self orangeField]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [self avenir:16.0 weight:@"heavy"],
    }];
    [[UITableView appearance] setBackgroundColor:dark];
    [[UITableViewCell appearance] setBackgroundColor:[self darkSurface]];
    [[UILabel appearance] setBackgroundColor:[UIColor clearColor]];
}

+ (BOOL)_isLegacyGreen:(UIColor *)color {
    if (!color || CGColorGetNumberOfComponents(color.CGColor) < 3) {
        return NO;
    }
    const CGFloat *c = CGColorGetComponents(color.CGColor);
    return c[0] > 0.45 && c[0] < 0.65 && c[1] > 0.72 && c[1] < 0.85 && c[2] > 0.32 && c[2] < 0.48;
}

+ (BOOL)_isLegacyBlue:(UIColor *)color {
    if (!color || CGColorGetNumberOfComponents(color.CGColor) < 3) {
        return NO;
    }
    const CGFloat *c = CGColorGetComponents(color.CGColor);
    return c[0] < 0.08 && c[1] > 0.18 && c[1] < 0.30 && c[2] > 0.40 && c[2] < 0.55;
}

+ (BOOL)_isWhiteishBackground:(UIColor *)color {
    if (!color || CGColorGetNumberOfComponents(color.CGColor) < 3) {
        return NO;
    }
    const CGFloat *c = CGColorGetComponents(color.CGColor);
    return c[0] > 0.92 && c[1] > 0.92 && c[2] > 0.92;
}

+ (BOOL)_isLegacyGreyButton:(UIColor *)color {
    if (!color || CGColorGetNumberOfComponents(color.CGColor) < 3) {
        return NO;
    }
    const CGFloat *c = CGColorGetComponents(color.CGColor);
    return c[0] > 0.35 && c[0] < 0.42 && c[1] > 0.35 && c[1] < 0.42 && c[2] > 0.38 && c[2] < 0.44;
}

+ (void)styleOrangeField:(UITextField *)field {
    field.backgroundColor = [self orangeField];
    field.textColor = [UIColor whiteColor];
    field.layer.cornerRadius = 6.0;
    field.clipsToBounds = YES;
    field.font = [self avenir:14.0 weight:@"roman"];
    if ([field respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        NSString *ph = field.placeholder ?: @"";
        field.attributedPlaceholder = [[NSAttributedString alloc]
            initWithString:ph
                attributes:@{
                    NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.85],
                    NSFontAttributeName: [self avenir:14.0 weight:@"roman"],
                }];
    }
}

+ (void)applyPlaceholderAppearanceToTextField:(UITextField *)field
                                        color:(UIColor *)color
                                         font:(UIFont *)font
{
    if (!field) {
        return;
    }
    NSString *placeholder = field.placeholder ?: @"";
    if (placeholder.length == 0) {
        return;
    }
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    if (color) {
        attributes[NSForegroundColorAttributeName] = color;
    }
    if (font) {
        attributes[NSFontAttributeName] = font;
    }
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder
                                                                attributes:attributes];
}

+ (void)styleOrangeTextView:(UITextView *)textView {
    textView.backgroundColor = [self orangeField];
    textView.textColor = [UIColor whiteColor];
    textView.layer.cornerRadius = 6.0;
    textView.clipsToBounds = YES;
    textView.font = [self avenir:14.0 weight:@"roman"];
}

+ (void)styleRedPrimaryButton:(UIButton *)button {
    button.backgroundColor = [self redPrimary];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [self avenir:14.0 weight:@"heavy"];
    button.layer.cornerRadius = 6.0;
    button.clipsToBounds = YES;
}

+ (void)styleCharcoalButton:(UIButton *)button {
    button.backgroundColor = [self charcoalButton];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [self avenir:14.0 weight:@"heavy"];
    button.layer.cornerRadius = 6.0;
    button.clipsToBounds = YES;
}

+ (void)stylePinField:(UITextField *)field {
    field.backgroundColor = [self redPrimary];
    field.textColor = [UIColor whiteColor];
    field.textAlignment = NSTextAlignmentCenter;
    field.layer.cornerRadius = 4.0;
    field.clipsToBounds = YES;
    field.font = [self avenir:18.0 weight:@"heavy"];
    field.secureTextEntry = YES;
    field.keyboardType = UIKeyboardTypeNumberPad;
}

+ (void)styleCzedrIdField:(UITextField *)field {
    if (!field) {
        return;
    }
    field.keyboardType = UIKeyboardTypeASCIICapable;
    field.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.secureTextEntry = NO;
}

+ (void)styleEmailField:(UITextField *)field {
    if (!field) {
        return;
    }
    field.keyboardType = UIKeyboardTypeEmailAddress;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.secureTextEntry = NO;
}

+ (void)stylePasswordField:(UITextField *)field {
    if (!field) {
        return;
    }
    field.keyboardType = UIKeyboardTypeASCIICapable;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.secureTextEntry = YES;
}

+ (void)styleNavigationHeader:(UIView *)headerView {
    headerView.backgroundColor = [self orangeField];
}

+ (void)styleGridTile:(UIView *)tileView {
    tileView.backgroundColor = [self gridTile];
}

+ (void)styleHomeBalanceCaptionLabel:(UILabel *)label {
    if (!label) {
        return;
    }
    label.textColor = [self captionOnDark];
    label.backgroundColor = [UIColor clearColor];
}

+ (void)styleHomeBalanceAmountLabel:(UILabel *)label {
    if (!label) {
        return;
    }
    label.textColor = [self balanceGreen];
    label.backgroundColor = [UIColor clearColor];
}

+ (UIImage *)brandSplashImage {
    UIImage *splash = [UIImage imageNamed:@"Czedr-splash-dark.png"];
    if (!splash) {
        splash = [UIImage imageNamed:@"Czedr-splash-dark"];
    }
    return splash;
}

+ (UIImage *)brandAuthLogoImage {
    UIImage *logo = [UIImage imageNamed:@"Czedr-auth-logo.png"];
    if (!logo) {
        logo = [UIImage imageNamed:@"Czedr-auth-logo"];
    }
    if (!logo) {
        logo = [UIImage imageNamed:@"Czedr-logo-tagline.png"];
    }
    if (!logo) {
        logo = [self brandSplashImage];
    }
    return logo;
}

+ (CGFloat)layoutAuthLogoInPanel:(UIView *)detailPanel logoView:(UIImageView *)logoView {
    if (!detailPanel || !logoView) {
        return 0;
    }
    UIImage *logo = logoView.image;
    if (!logo) {
        return 0;
    }
    CGFloat panelW = detailPanel.bounds.size.width;
    CGFloat maxW = MAX(panelW - 36.0, 180.0);
    CGFloat aspect = logo.size.width / MAX(logo.size.height, 1.0);
    CGFloat height = MIN(118.0, maxW / MAX(aspect, 0.5));
    CGFloat width = height * aspect;
    CGFloat x = (panelW - width) / 2.0;
    logoView.frame = CGRectMake(x, 14.0, width, height);
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    logoView.backgroundColor = [UIColor clearColor];
    logoView.layer.cornerRadius = 0;
    logoView.clipsToBounds = NO;
    return CGRectGetMaxY(logoView.frame);
}

+ (UIImageView *)_logoImageViewInView:(UIView *)view {
    for (UIView *sub in view.subviews) {
        if ([sub isKindOfClass:[UIImageView class]]) {
            return (UIImageView *)sub;
        }
    }
    return nil;
}

+ (void)_styleLabelsForDarkInView:(UIView *)view {
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        UIColor *color = label.textColor;
        if (!color) {
            return;
        }
        CGFloat r = 0, g = 0, b = 0, a = 0;
        if ([color getRed:&r green:&g blue:&b alpha:&a]) {
            if (r < 0.55 && g < 0.55 && b < 0.55) {
                label.textColor = [self lightText];
            }
        }
    } else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        UIColor *titleColor = [button titleColorForState:UIControlStateNormal];
        CGFloat r = 0, g = 0, b = 0, a = 0;
        if (titleColor && [titleColor getRed:&r green:&g blue:&b alpha:&a] && r < 0.55 && g < 0.55 && b < 0.55) {
            [button setTitleColor:[[self lightText] colorWithAlphaComponent:0.75] forState:UIControlStateNormal];
        }
    }
    for (UIView *sub in view.subviews) {
        [self _styleLabelsForDarkInView:sub];
    }
}

+ (void)applyAuthDarkScreen:(UIView *)rootView detailPanel:(UIView *)detailPanel logoView:(UIImageView *)logoView {
    rootView.backgroundColor = [self darkBackground];
    for (UIView *sub in rootView.subviews) {
        if (sub == detailPanel || sub == logoView) {
            continue;
        }
        if ([sub isKindOfClass:[UIImageView class]]) {
            sub.hidden = YES;
        }
    }
    if (detailPanel) {
        detailPanel.backgroundColor = [self darkBackground];
        detailPanel.layer.cornerRadius = 14.0;
        detailPanel.layer.borderWidth = 1.0;
        detailPanel.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.06].CGColor;
        detailPanel.layer.shadowColor = [UIColor blackColor].CGColor;
        detailPanel.layer.shadowOpacity = 0.35;
        detailPanel.layer.shadowRadius = 12.0;
        detailPanel.layer.shadowOffset = CGSizeMake(0, 6);
        if (!logoView) {
            logoView = [self _logoImageViewInView:detailPanel];
        }
        [self _styleLabelsForDarkInView:detailPanel];
    }
    UIImage *logo = [self brandAuthLogoImage];
    if (logoView && logo) {
        logoView.image = logo;
        logoView.hidden = NO;
        if (detailPanel) {
            [self layoutAuthLogoInPanel:detailPanel logoView:logoView];
        }
    }
    [self _styleLabelsForDarkInView:rootView];
}

+ (void)_applyDarkSurfacesInView:(UIView *)view {
    if (!view) {
        return;
    }
    UIColor *bg = view.backgroundColor;
    if ([self _isWhiteishBackground:bg] || [self _isLegacyGreen:bg]) {
        if ([view isKindOfClass:[UITableView class]] || [view isKindOfClass:[UIScrollView class]]) {
            view.backgroundColor = [self darkBackground];
        } else if (view.subviews.count > 2) {
            view.backgroundColor = [self darkBackground];
        } else {
            view.backgroundColor = [self darkSurface];
        }
    }
    for (UIView *sub in view.subviews) {
        [self _applyDarkSurfacesInView:sub];
    }
}

+ (void)applyLoggedInDarkScreenToView:(UIView *)view {
    if (!view) {
        return;
    }
    view.backgroundColor = [self darkBackground];
    [self applyDeckLookToView:view];
    [self _applyDarkSurfacesInView:view];
    [self _styleLabelsForDarkInView:view];
}

+ (void)applyDeckLookToView:(UIView *)view {
    if (!view) {
        return;
    }

    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)view;
        if (tf.secureTextEntry && tf.keyboardType == UIKeyboardTypeNumberPad) {
            [self stylePinField:tf];
        } else if (!tf.secureTextEntry && tf.keyboardType == UIKeyboardTypeNumberPad) {
            [self styleCzedrIdField:tf];
            if ([self _isLegacyGreen:tf.backgroundColor] || [self _isLegacyBlue:tf.backgroundColor]) {
                [self styleOrangeField:tf];
            }
        } else if ([self _isLegacyGreen:tf.backgroundColor] || [self _isLegacyBlue:tf.backgroundColor]) {
            [self styleOrangeField:tf];
        } else if (tf.secureTextEntry && ([self _isLegacyGreen:tf.backgroundColor] || tf.backgroundColor == nil)) {
            [self styleOrangeField:tf];
        }
    } else if ([view isKindOfClass:[UITextView class]]) {
        UITextView *tv = (UITextView *)view;
        if ([self _isLegacyGreen:tv.backgroundColor]) {
            [self styleOrangeTextView:tv];
        }
    } else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton *)view;
        UIColor *bg = btn.backgroundColor;
        NSString *title = [btn titleForState:UIControlStateNormal] ?: @"";
        if ([self _isLegacyGreyButton:bg]) {
            [self styleCharcoalButton:btn];
        } else if ([self _isLegacyBlue:bg] || [self _isLegacyGreen:bg]) {
            if (([[title uppercaseString] containsString:@"SIGN UP"] && [[title uppercaseString] containsString:@"NOW"])
                || [[title uppercaseString] containsString:@"REGISTER"]) {
                [self styleCharcoalButton:btn];
            } else {
                [self styleRedPrimaryButton:btn];
            }
        }
    } else {
        UIColor *bg = view.backgroundColor;
        if ([self _isLegacyGreen:bg]) {
            if (view.frame.size.height > 0 && view.frame.size.height <= 90 && view.frame.size.width > 200) {
                [self styleNavigationHeader:view];
            } else if (view.subviews.count >= 2) {
                BOOL hasButton = NO;
                for (UIView *sub in view.subviews) {
                    if ([sub isKindOfClass:[UIButton class]] || [sub isKindOfClass:[UIImageView class]]) {
                        hasButton = YES;
                        break;
                    }
                }
                if (hasButton && view.frame.size.height > 100 && view.frame.size.width > 100) {
                    [self styleGridTile:view];
                } else {
                    view.backgroundColor = [self darkBackground];
                }
            } else {
                view.backgroundColor = [self darkBackground];
            }
        } else if ([self _isLegacyBlue:bg]) {
            [self styleGridTile:view];
        }
    }

    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if ([self _isWhiteishBackground:label.backgroundColor]) {
            label.backgroundColor = [UIColor clearColor];
        }
    }

    for (UIView *sub in view.subviews) {
        [self applyDeckLookToView:sub];
    }
}

@end
