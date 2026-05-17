//
//  CzedrAppChrome.h
//  Session controls: logout, minimize menu, maximize menu, exit to sign-in.
//

#import <UIKit/UIKit.h>

@class MMDrawerController;

@interface CzedrAppChrome : NSObject

/** Four-button bar on the main drawer (visible on every logged-in screen). */
+ (void)refreshSessionBarForDrawer:(MMDrawerController *)drawer;

/** Ensures the session bar is shown (uses drawer when available). */
+ (UIView *)installSessionBarInViewController:(UIViewController *)host;

+ (void)logoutFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)minimizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)maximizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)exitFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;

@end
