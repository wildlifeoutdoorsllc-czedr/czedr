//
//  CzedrSwiftLauncher.h
//  Hosts SwiftUI root when CZEDR_USE_SWIFTUI is enabled.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CzedrSwiftLauncher : NSObject

/** Clear Keychain + in-memory session before UI (required after force-quit). */
+ (void)prepareColdLaunch;

+ (void)presentInWindow:(UIWindow *)window;

@end

NS_ASSUME_NONNULL_END
