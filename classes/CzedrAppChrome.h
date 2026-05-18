//
//  CzedrAppChrome.h
//  Top navigation and window-style controls for logged-in screens.
//

#import <UIKit/UIKit.h>

@class MMDrawerController;

/** Posted after sign-in when returning to the home screen (pop navigation, no drawer rebuild). */
FOUNDATION_EXPORT NSString * const CzedrUserDidLoginNotification;

@interface CzedrAppChrome : NSObject

+ (BOOL)isLoggedIn;
+ (void)clearLocalSession;

/** Suppress top-bar layout during drawer transitions (avoids post-login crashes). */
+ (void)suspendSessionBarRefreshForSeconds:(NSTimeInterval)seconds;
+ (BOOL)sessionBarRefreshSuspended;

/** Top bar: menu, back/forward, centered logo, minimize / maximize. */
+ (void)refreshSessionBarForDrawer:(MMDrawerController *)drawer;

+ (CGFloat)topChromeBottomYForView:(UIView *)view;
+ (void)hideLegacyPageHeadersInView:(UIView *)rootView;

+ (UIView *)installSessionBarInViewController:(UIViewController *)host;

+ (void)logoutFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)minimizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)maximizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)exitFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;

@end
