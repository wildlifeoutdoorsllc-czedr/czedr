//
//  CzedrSwiftLauncher.m
//

#import "CzedrSwiftLauncher.h"

#if __has_include("Czedr-Swift.h")
#import "Czedr-Swift.h"
#endif

@implementation CzedrSwiftLauncher

+ (void)prepareColdLaunch
{
#if __has_include("Czedr-Swift.h")
    [CzedrSwiftBootstrap clearSessionOnColdLaunch];
#endif
}

+ (void)presentInWindow:(UIWindow *)window
{
#if __has_include("Czedr-Swift.h")
    [CzedrSwiftBootstrap presentIn:window];
#else
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor blackColor];
    window.rootViewController = vc;
#endif
}

@end
