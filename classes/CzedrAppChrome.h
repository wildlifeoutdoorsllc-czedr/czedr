//
//  CzedrAppChrome.h
//  Top navigation and window-style controls for logged-in screens.
//

#import <UIKit/UIKit.h>

@class MMDrawerController;

@interface CzedrAppChrome : NSObject

+ (BOOL)isLoggedIn;
+ (void)clearLocalSession;

/** Top bar: back/forward (left), minimize / maximize (upper right). */
+ (void)refreshSessionBarForDrawer:(MMDrawerController *)drawer;

+ (UIView *)installSessionBarInViewController:(UIViewController *)host;

+ (void)logoutFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)minimizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)maximizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)exitFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;

@end
