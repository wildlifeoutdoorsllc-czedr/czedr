//
//  CzedrAppChrome.h
//  Session controls: logout, minimize menu, maximize menu, exit to sign-in.
//

#import <UIKit/UIKit.h>

@class MMDrawerController;

@interface CzedrAppChrome : NSObject

/** Four-button bar pinned to the bottom of a view controller (Home screen). */
+ (UIView *)installSessionBarInViewController:(UIViewController *)host;

+ (void)logoutFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)minimizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)maximizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;
+ (void)exitFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer;

@end
