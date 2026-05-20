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

/** Convenience: refresh chrome from any logged-in view controller. */
+ (void)refreshSessionBarForViewController:(UIViewController *)host;

+ (CGFloat)topChromeBottomYForView:(UIView *)view;
+ (CGFloat)topChromeBottomYForDrawer:(MMDrawerController *)drawer;
+ (void)applyChromeContentInsetsForDrawer:(MMDrawerController *)drawer;

/** Push legacy XIB content below toolbar + logo; hide duplicate page headers. */
+ (void)layoutLoggedInContentForViewController:(UIViewController *)viewController drawer:(MMDrawerController *)drawer;

+ (UIView *)installSessionBarInViewController:(UIViewController *)host;

+ (void)logoutFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)minimizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)maximizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)exitFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;

@end
