//
//  CzedrAppChrome.m
//

#import "CzedrAppChrome.h"
#import "CzedrTheme.h"
#import "SharedServiceController.h"
#import "ViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "MMDrawerController.h"
#import "MBProgressHUD.h"

static const NSInteger kCzedrTopChromeTag = 88040;
static const NSInteger kChromeBackButtonTag = 88041;
static const NSInteger kChromeForwardButtonTag = 88042;
static const NSInteger kChromeMinimizeButtonTag = 88043;
static const NSInteger kChromeMaximizeButtonTag = 88044;

static NSMutableArray<UIViewController *> *CzedrForwardStack(void)
{
    static NSMutableArray<UIViewController *> *stack = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stack = [NSMutableArray array];
    });
    return stack;
}

@interface CzedrTopChromeTarget : NSObject
@property (nonatomic, weak) MMDrawerController *drawer;
- (void)chromeBack:(id)sender;
- (void)chromeForward:(id)sender;
- (void)chromeMinimize:(id)sender;
- (void)chromeMaximize:(id)sender;
@end

@implementation CzedrTopChromeTarget

- (UINavigationController *)centerNavigation
{
    if (!self.drawer) {
        return nil;
    }
    UIViewController *center = self.drawer.centerViewController;
    if ([center isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)center;
    }
    return nil;
}

- (UIViewController *)actionHost
{
    UINavigationController *nav = [self centerNavigation];
    return nav.topViewController ?: nav;
}

- (void)chromeBack:(id)sender
{
    (void)sender;
    UINavigationController *nav = [self centerNavigation];
    if (!nav || nav.viewControllers.count <= 1) {
        return;
    }
    UIViewController *leaving = nav.topViewController;
    if (leaving) {
        [CzedrForwardStack() removeAllObjects];
        [CzedrForwardStack() addObject:leaving];
    }
    [nav popViewControllerAnimated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [CzedrAppChrome refreshSessionBarForDrawer:self.drawer];
    });
}

- (void)chromeForward:(id)sender
{
    (void)sender;
    UINavigationController *nav = [self centerNavigation];
    if (!nav || CzedrForwardStack().count == 0) {
        return;
    }
    UIViewController *next = CzedrForwardStack().lastObject;
    [CzedrForwardStack() removeLastObject];
    if (next) {
        [nav pushViewController:next animated:YES];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [CzedrAppChrome refreshSessionBarForDrawer:self.drawer];
    });
}

- (void)chromeMinimize:(id)sender
{
    (void)sender;
    UIViewController *host = [self actionHost];
    if (host) {
        [CzedrAppChrome minimizeFromViewController:host drawer:self.drawer];
    }
}

- (void)chromeMaximize:(id)sender
{
    (void)sender;
    UIViewController *host = [self actionHost];
    if (host) {
        [CzedrAppChrome maximizeFromViewController:host drawer:self.drawer];
    }
}

@end

NSString * const CzedrUserDidLoginNotification = @"CzedrUserDidLogin";

@implementation CzedrAppChrome

static NSDate *sSessionBarResumeAfter = nil;

+ (void)suspendSessionBarRefreshForSeconds:(NSTimeInterval)seconds
{
    sSessionBarResumeAfter = [NSDate dateWithTimeIntervalSinceNow:MAX(0.1, seconds)];
}

+ (BOOL)sessionBarRefreshSuspended
{
    return sSessionBarResumeAfter != nil && [sSessionBarResumeAfter timeIntervalSinceNow] > 0;
}

static CzedrTopChromeTarget *CzedrTopChromeTargetShared(void)
{
    static CzedrTopChromeTarget *target = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        target = [[CzedrTopChromeTarget alloc] init];
    });
    return target;
}

+ (BOOL)isLoggedIn
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"auth_codeSaved"].length > 0;
}

+ (UIButton *)chromeButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.35] forState:UIControlStateDisabled];
    button.titleLabel.font = [CzedrTheme avenir:18.0 weight:@"heavy"];
    button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15];
    button.layer.cornerRadius = 4.0;
    button.clipsToBounds = YES;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

+ (UIButton *)chromeWindowButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    UIButton *button = [self chromeButtonWithTitle:title target:target action:action];
    button.titleLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightLight];
    button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    return button;
}

+ (void)layoutTopChrome:(UIView *)bar inContainerView:(UIView *)containerView drawer:(MMDrawerController *)drawer
{
    if (!bar || !containerView) {
        return;
    }
    CGFloat barHeight = 44.0;
    CGFloat topInset = 0.0;
    if (@available(iOS 11.0, *)) {
        topInset = containerView.safeAreaInsets.top;
    }
    CGFloat width = containerView.bounds.size.width;
    bar.frame = CGRectMake(0, topInset, width, barHeight);

    UIButton *back = (UIButton *)[bar viewWithTag:kChromeBackButtonTag];
    UIButton *forward = (UIButton *)[bar viewWithTag:kChromeForwardButtonTag];
    UIButton *minimize = (UIButton *)[bar viewWithTag:kChromeMinimizeButtonTag];
    UIButton *maximize = (UIButton *)[bar viewWithTag:kChromeMaximizeButtonTag];

    CGFloat pad = 10.0;
    CGFloat navW = 40.0;
    CGFloat navH = 32.0;
    CGFloat navY = (barHeight - navH) / 2.0;
    if (back) {
        back.frame = CGRectMake(pad, navY, navW, navH);
    }
    if (forward) {
        forward.frame = CGRectMake(pad + navW + 6.0, navY, navW, navH);
    }

    CGFloat winW = 40.0;
    CGFloat winH = 32.0;
    CGFloat winGap = 4.0;
    CGFloat winY = (barHeight - winH) / 2.0;
    if (maximize) {
        maximize.frame = CGRectMake(width - pad - winW, winY, winW, winH);
    }
    if (minimize) {
        minimize.frame = CGRectMake(width - pad - winW * 2.0 - winGap, winY, winW, winH);
    }

    UINavigationController *nav = nil;
    if ([drawer.centerViewController isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)drawer.centerViewController;
    }
    if (back) {
        back.enabled = (nav != nil && nav.viewControllers.count > 1);
    }
    if (forward) {
        forward.enabled = (CzedrForwardStack().count > 0);
    }
}

+ (UIView *)buildTopChromeWithTarget:(CzedrTopChromeTarget *)target
{
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    bar.tag = kCzedrTopChromeTag;
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    bar.backgroundColor = [[CzedrTheme darkSurface] colorWithAlphaComponent:0.94];
    bar.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.35].CGColor;
    bar.layer.borderWidth = 0.0;
    bar.layer.shadowColor = [UIColor blackColor].CGColor;
    bar.layer.shadowOpacity = 0.25;
    bar.layer.shadowRadius = 3.0;
    bar.layer.shadowOffset = CGSizeMake(0, 2);

    UIButton *back = [self chromeButtonWithTitle:@"\u2190" target:target action:@selector(chromeBack:)];
    back.tag = kChromeBackButtonTag;
    back.accessibilityLabel = @"Back";
    [bar addSubview:back];

    UIButton *forward = [self chromeButtonWithTitle:@"\u2192" target:target action:@selector(chromeForward:)];
    forward.tag = kChromeForwardButtonTag;
    forward.accessibilityLabel = @"Forward";
    [bar addSubview:forward];

    UIButton *minimize = [self chromeWindowButtonWithTitle:@"\u2212" target:target action:@selector(chromeMinimize:)];
    minimize.tag = kChromeMinimizeButtonTag;
    minimize.accessibilityLabel = @"Minimize";
    [bar addSubview:minimize];

    UIButton *maximize = [self chromeWindowButtonWithTitle:@"+" target:target action:@selector(chromeMaximize:)];
    maximize.tag = kChromeMaximizeButtonTag;
    maximize.accessibilityLabel = @"Maximize";
    maximize.titleLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightLight];
    [bar addSubview:maximize];

    return bar;
}

+ (void)removeSessionBarFromDrawer:(MMDrawerController *)drawer
{
    if (!drawer) {
        return;
    }
    UIView *bar = [drawer.view viewWithTag:kCzedrTopChromeTag];
    [bar removeFromSuperview];
    [CzedrForwardStack() removeAllObjects];
}

+ (void)refreshSessionBarForDrawer:(MMDrawerController *)drawer
{
    if (!drawer) {
        return;
    }
    if ([self sessionBarRefreshSuspended]) {
        return;
    }
    if (![self isLoggedIn]) {
        [self removeSessionBarFromDrawer:drawer];
        return;
    }

    UIViewController *centerTop = nil;
    if ([drawer.centerViewController isKindOfClass:[UINavigationController class]]) {
        centerTop = [(UINavigationController *)drawer.centerViewController topViewController];
    }
    NSString *topClass = NSStringFromClass([centerTop class]);
    if ([topClass isEqualToString:@"ViewController"] || [topClass isEqualToString:@"GeneratePinViewController"]) {
        [self removeSessionBarFromDrawer:drawer];
        return;
    }

    CzedrTopChromeTarget *target = CzedrTopChromeTargetShared();
    target.drawer = drawer;

    static __weak UINavigationController *lastCenterNav = nil;
    UINavigationController *nav = nil;
    if ([drawer.centerViewController isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)drawer.centerViewController;
    }
    if (nav != lastCenterNav) {
        [CzedrForwardStack() removeAllObjects];
        lastCenterNav = nav;
    }

    if (!drawer.view.window) {
        return;
    }

    UIView *bar = [drawer.view viewWithTag:kCzedrTopChromeTag];
    if (!bar) {
        bar = [self buildTopChromeWithTarget:target];
        [drawer.view addSubview:bar];
    }
    [self layoutTopChrome:bar inContainerView:drawer.view drawer:drawer];
    bar.hidden = NO;
    bar.userInteractionEnabled = YES;
    [drawer.view bringSubviewToFront:bar];
}

+ (UIView *)installSessionBarInViewController:(UIViewController *)host
{
    MMDrawerController *drawer = host.mm_drawerController;
    if (drawer) {
        [self refreshSessionBarForDrawer:drawer];
        return [drawer.view viewWithTag:kCzedrTopChromeTag];
    }
    return nil;
}

+ (void)clearLocalSession
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"auth_codeSaved"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userDataArray"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"profile_pic"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [CzedrForwardStack() removeAllObjects];
}

+ (void)showLoginFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer
{
    [self removeSessionBarFromDrawer:drawer];
    [self clearLocalSession];
    ViewController *login = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:login];
    nav.navigationBarHidden = YES;
    if (drawer) {
        [drawer setCenterViewController:nav withCloseAnimation:YES completion:nil];
    } else if (host.navigationController) {
        [host.navigationController setViewControllers:@[login] animated:YES];
    } else {
        [host presentViewController:nav animated:YES completion:nil];
    }
}

+ (void)logoutFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer
{
    [MBProgressHUD showHUDAddedTo:host.view animated:YES];
    [SharedServiceController logoutWithSuccess:^{
        [MBProgressHUD hideHUDForView:host.view animated:YES];
        [self showLoginFromViewController:host drawer:drawer];
    } failure:^(NSString *message) {
        [MBProgressHUD hideHUDForView:host.view animated:YES];
        (void)message;
        [self showLoginFromViewController:host drawer:drawer];
    }];
}

+ (void)minimizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer
{
    (void)host;
    if (drawer) {
        [drawer closeDrawerAnimated:YES completion:nil];
    }
}

+ (void)maximizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer
{
    (void)host;
    if (drawer) {
        [drawer openDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    }
}

+ (void)exitFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Exit Czedr?"
                                                                   message:@"Return to the sign-in screen?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *a) {
        [self logoutFromViewController:host drawer:drawer];
    }]];
    [host presentViewController:alert animated:YES completion:nil];
}

@end
