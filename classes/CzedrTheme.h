//
//  CzedrTheme.h
//  Czedr — visual style (orange fields, red actions, charcoal secondary).
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CzedrTheme : NSObject

/** Orange form fields and nav bars (#F58220). */
+ (UIColor *)orangeField;
/** Red primary actions — LOGIN, SIGN UP, VALIDATE, PIN boxes (#E31E24). */
+ (UIColor *)redPrimary;
/** Dark grey secondary button — SIGN UP NOW! (#58595B). */
+ (UIColor *)charcoalButton;
/** Home grid tiles — dark red-orange (#C94A1F). */
+ (UIColor *)gridTile;
/** Tagline / accent red. */
+ (UIColor *)taglineRed;
/** Body / label grey. */
+ (UIColor *)mutedText;
/** Splash / auth screen background (#2A2A2C). */
+ (UIColor *)darkBackground;
/** Elevated panel on dark UI (#353538). */
+ (UIColor *)darkSurface;
/** Secondary text on dark backgrounds. */
+ (UIColor *)lightText;
/** Caption / ID line on dark screens (light grey). */
+ (UIColor *)captionOnDark;
/** Available balance amount on home (#32CD5A). */
+ (UIColor *)balanceGreen;

+ (UIFont *)avenir:(CGFloat)size weight:(NSString *)weight;

/** Accepts test addresses like alice@test.czedr (TLD longer than 4 chars). */
+ (BOOL)isValidEmailAddress:(NSString *)email;

+ (void)applyGlobalAppearance;

/** Walk view hierarchy and replace legacy green/blue accent colors with deck palette. */
+ (void)applyDeckLookToView:(UIView *)view;

/** Logged-in screens: deck palette + charcoal background (no white panels). */
+ (void)applyLoggedInDarkScreenToView:(UIView *)view;

+ (void)styleHomeBalanceCaptionLabel:(UILabel *)label;
+ (void)styleHomeBalanceAmountLabel:(UILabel *)label;

+ (void)styleOrangeField:(UITextField *)field;
/** Safe placeholder styling (avoids private _placeholderLabel KVC, which crashes on iOS 13+). */
+ (void)applyPlaceholderAppearanceToTextField:(UITextField *)field
                                        color:(UIColor *)color
                                         font:(nullable UIFont *)font;
+ (void)styleOrangeTextView:(UITextView *)textView;
+ (void)styleRedPrimaryButton:(UIButton *)button;
+ (void)styleCharcoalButton:(UIButton *)button;
+ (void)stylePinField:(UITextField *)field;
/** Czedr IDs use letters and digits (e.g. CZAB79D695) — not number-only keyboard. */
+ (void)styleCzedrIdField:(UITextField *)field;
+ (void)styleEmailField:(UITextField *)field;
+ (void)stylePasswordField:(UITextField *)field;
+ (void)styleNavigationHeader:(UIView *)headerView;
+ (void)styleGridTile:(UIView *)tileView;

/** Dark auth screens: charcoal background, clear card, light labels. */
+ (UIImage *)brandSplashImage;
+ (UIImage *)brandAuthLogoImage;
/** Same dimensions as the sign-in screen logo (panel height × 26%, width − 40pt). */
+ (CGSize)brandAuthLogoDisplaySizeForPanelWidth:(CGFloat)panelW panelHeight:(CGFloat)panelH;
/** Smaller logo for inner pages (fits under toolbar without covering forms). */
+ (CGSize)brandAuthLogoCompactDisplaySizeForPanelWidth:(CGFloat)panelW;
+ (CGFloat)layoutAuthLogoInPanel:(UIView *)detailPanel logoView:(UIImageView *)logoView;
+ (void)applyAuthDarkScreen:(UIView *)rootView detailPanel:(nullable UIView *)detailPanel logoView:(nullable UIImageView *)logoView;

@end

NS_ASSUME_NONNULL_END
