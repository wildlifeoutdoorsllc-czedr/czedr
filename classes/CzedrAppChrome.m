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
static const NSInteger kChromeMenuButtonTag = 88045;
static const NSInteger kChromeBrandLogoStripTag = 88047;
static const NSInteger kChromeBrandLogoImageTag = 88048;
static const CGFloat kCzedrTopChromeHeight = 50.0;
static BOOL sChromeRefreshInProgress = NO;

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
- (void)chromeMenu:(id)sender;
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

- (MMDrawerController *)resolvedDrawer
{
    if (self.drawer) {
        return self.drawer;
    }
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([root isKindOfClass:[MMDrawerController class]]) {
        return (MMDrawerController *)root;
    }
    return nil;
}

- (void)chromeBack:(id)sender
{
    (void)sender;
    MMDrawerController *drawer = [self resolvedDrawer];
    self.drawer = drawer;
    UINavigationController *nav = [self centerNavigation];
    if (!nav) {
        nav = (UINavigationController *)drawer.centerViewController;
    }
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
        [CzedrAppChrome refreshSessionBarForDrawer:drawer];
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

- (void)chromeMenu:(id)sender
{
    (void)sender;
    MMDrawerController *drawer = [self resolvedDrawer];
    self.drawer = drawer;
    if (drawer) {
        [drawer toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
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

+ (UINavigationController *)centerNavigationForDrawer:(MMDrawerController *)drawer
{
    if (!drawer) {
        return nil;
    }
    UIViewController *center = drawer.centerViewController;
    if ([center isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)center;
    }
    return nil;
}

+ (UIView *)chromeHostViewForDrawer:(MMDrawerController *)drawer
{
    UINavigationController *nav = [self centerNavigationForDrawer:drawer];
    return nav.view;
}

+ (void)attachChromeView:(UIView *)chrome toDrawer:(MMDrawerController *)drawer
{
    if (!chrome || !drawer) {
        return;
    }
    UIView *root = [self chromeHostViewForDrawer:drawer];
    if (!root) {
        return;
    }
    if (chrome.superview != root) {
        [chrome removeFromSuperview];
    }
    [root addSubview:chrome];
    [root bringSubviewToFront:chrome];
    chrome.layer.zPosition = 10000.0;
    chrome.userInteractionEnabled = YES;
}

+ (void)layoutTopChrome:(UIView *)bar inContainerView:(UIView *)containerView drawer:(MMDrawerController *)drawer
{
    if (!bar || !containerView) {
        return;
    }
    CGFloat barHeight = kCzedrTopChromeHeight;
    CGFloat topInset = 0.0;
    if (@available(iOS 11.0, *)) {
        topInset = containerView.safeAreaInsets.top;
    }
    CGFloat width = containerView.bounds.size.width;
    bar.frame = CGRectMake(0, topInset, width, barHeight);

    UIButton *menu = (UIButton *)[bar viewWithTag:kChromeMenuButtonTag];
    UIButton *back = (UIButton *)[bar viewWithTag:kChromeBackButtonTag];
    UIButton *forward = (UIButton *)[bar viewWithTag:kChromeForwardButtonTag];
    UIButton *minimize = (UIButton *)[bar viewWithTag:kChromeMinimizeButtonTag];
    UIButton *maximize = (UIButton *)[bar viewWithTag:kChromeMaximizeButtonTag];
    UIView *legacyToolbarLogo = [bar viewWithTag:88046];
    if (legacyToolbarLogo) {
        [legacyToolbarLogo removeFromSuperview];
    }

    CGFloat pad = 8.0;
    CGFloat navW = 36.0;
    CGFloat navH = 32.0;
    CGFloat navY = (barHeight - navH) / 2.0;
    CGFloat x = pad;
    if (menu) {
        menu.frame = CGRectMake(x, navY, navW, navH);
        x += navW + 4.0;
    }
    if (back) {
        back.frame = CGRectMake(x, navY, navW, navH);
        x += navW + 4.0;
    }
    if (forward) {
        forward.frame = CGRectMake(x, navY, navW, navH);
    }

    CGFloat winW = 36.0;
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
        back.userInteractionEnabled = YES;
    }
    if (menu) {
        menu.userInteractionEnabled = YES;
    }
    if (forward) {
        forward.enabled = (CzedrForwardStack().count > 0);
    }
}

+ (void)layoutBrandLogoStrip:(UIView *)strip inDrawerView:(UIView *)drawerView belowBar:(UIView *)bar compact:(BOOL)compact
{
    if (!strip || !drawerView || !bar) {
        return;
    }
    UIImageView *logo = (UIImageView *)[strip viewWithTag:kChromeBrandLogoImageTag];
    if (!logo) {
        return;
    }
    UIImage *img = logo.image ?: [CzedrTheme brandAuthLogoImage];
    if (!img) {
        strip.hidden = YES;
        return;
    }
    logo.image = img;
    logo.hidden = NO;
    strip.hidden = NO;

    CGFloat width = drawerView.bounds.size.width;
    CGFloat panelH = drawerView.bounds.size.height;
    CGSize size = compact
        ? [CzedrTheme brandAuthLogoCompactDisplaySizeForPanelWidth:width]
        : [CzedrTheme brandAuthLogoDisplaySizeForPanelWidth:width panelHeight:panelH];
    if (size.width < 1.0) {
        strip.hidden = YES;
        return;
    }

    const CGFloat topPad = compact ? 6.0 : 14.0;
    const CGFloat bottomPad = compact ? 6.0 : 10.0;
    CGFloat logoX = (width - size.width) / 2.0;
    logo.frame = CGRectMake(logoX, topPad, size.width, size.height);
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.backgroundColor = [UIColor clearColor];

    CGFloat barBottom = CGRectGetMaxY(bar.frame);
    CGFloat stripH = topPad + size.height + bottomPad;
    strip.frame = CGRectMake(0, barBottom, width, stripH);
    strip.backgroundColor = [CzedrTheme darkBackground];
    strip.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
}

+ (UIView *)buildTopChromeWithTarget:(CzedrTopChromeTarget *)target
{
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kCzedrTopChromeHeight)];
    bar.tag = kCzedrTopChromeTag;
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    bar.backgroundColor = [[CzedrTheme darkSurface] colorWithAlphaComponent:0.94];
    bar.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.35].CGColor;
    bar.layer.borderWidth = 0.0;
    bar.layer.shadowColor = [UIColor blackColor].CGColor;
    bar.layer.shadowOpacity = 0.25;
    bar.layer.shadowRadius = 3.0;
    bar.layer.shadowOffset = CGSizeMake(0, 2);

    UIButton *menu = [UIButton buttonWithType:UIButtonTypeCustom];
    menu.tag = kChromeMenuButtonTag;
    menu.accessibilityLabel = @"Menu";
    UIImage *menuIcon = [UIImage imageNamed:@"menu2.png"];
    if (!menuIcon) {
        menuIcon = [UIImage imageNamed:@"menu2@2x.png"];
    }
    [menu setImage:menuIcon forState:UIControlStateNormal];
    menu.imageView.contentMode = UIViewContentModeScaleAspectFit;
    menu.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15];
    menu.layer.cornerRadius = 4.0;
    menu.clipsToBounds = YES;
    [menu addTarget:target action:@selector(chromeMenu:) forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:menu];

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
    for (UIView *root in @[[self chromeHostViewForDrawer:drawer], drawer.view]) {
        if (!root) {
            continue;
        }
        UIView *bar = [root viewWithTag:kCzedrTopChromeTag];
        [bar removeFromSuperview];
        UIView *strip = [root viewWithTag:kChromeBrandLogoStripTag];
        [strip removeFromSuperview];
    }
    [CzedrForwardStack() removeAllObjects];
}

+ (void)refreshSessionBarForViewController:(UIViewController *)host
{
    if (!host) {
        return;
    }
    [self refreshSessionBarForDrawer:host.mm_drawerController];
}

+ (void)refreshSessionBarForDrawer:(MMDrawerController *)drawer
{
    if (!drawer) {
        return;
    }
    if (sChromeRefreshInProgress) {
        return;
    }
    if ([self sessionBarRefreshSuspended]) {
        return;
    }
    if (![self isLoggedIn]) {
        [self removeSessionBarFromDrawer:drawer];
        return;
    }

    sChromeRefreshInProgress = YES;
    @try {

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

    UIView *root = [self chromeHostViewForDrawer:drawer];
    if (!root) {
        return;
    }

    UIView *bar = [root viewWithTag:kCzedrTopChromeTag];
    if (!bar) {
        bar = [self buildTopChromeWithTarget:target];
        [self attachChromeView:bar toDrawer:drawer];
    } else {
        [self attachChromeView:bar toDrawer:drawer];
    }
    [self layoutTopChrome:bar inContainerView:root drawer:drawer];
    bar.hidden = NO;
    bar.userInteractionEnabled = YES;

    UIView *strip = [root viewWithTag:kChromeBrandLogoStripTag];
    if (!strip) {
        strip = [[UIView alloc] init];
        strip.tag = kChromeBrandLogoStripTag;
        UIImageView *logo = [[UIImageView alloc] initWithImage:[CzedrTheme brandAuthLogoImage]];
        logo.tag = kChromeBrandLogoImageTag;
        logo.contentMode = UIViewContentModeScaleAspectFit;
        logo.backgroundColor = [UIColor clearColor];
        [strip addSubview:logo];
        [self attachChromeView:strip toDrawer:drawer];
    } else {
        [self attachChromeView:strip toDrawer:drawer];
    }
    BOOL onHome = [topClass isEqualToString:@"leftSwipeViewController"];
    [self layoutBrandLogoStrip:strip inDrawerView:root belowBar:bar compact:!onHome];
    strip.userInteractionEnabled = NO;
    strip.hidden = onHome;

    [self attachChromeView:strip toDrawer:drawer];
    [self attachChromeView:bar toDrawer:drawer];
    [self applyChromeContentInsetsForDrawer:drawer];

    if (centerTop.isViewLoaded) {
        [self layoutLoggedInContentForViewController:centerTop drawer:drawer];
    }
    } @finally {
        sChromeRefreshInProgress = NO;
    }
}

+ (UIScrollView *)czedr_firstScrollViewInView:(UIView *)view
{
    if ([view isKindOfClass:[UIScrollView class]]) {
        return (UIScrollView *)view;
    }
    for (UIView *sub in view.subviews) {
        UIScrollView *found = [self czedr_firstScrollViewInView:sub];
        if (found) {
            return found;
        }
    }
    return nil;
}

+ (void)czedr_hideLegacyPageChromeInView:(UIView *)rootView scrollView:(UIScrollView *)scrollView
{
    for (UIView *sub in rootView.subviews) {
        if (sub == scrollView) {
            continue;
        }
        if (sub.tag == kCzedrTopChromeTag || sub.tag == kChromeBrandLogoStripTag) {
            continue;
        }
        if (CGRectGetMaxY(sub.frame) <= CGRectGetMinY(scrollView.frame) + 4.0 || sub.frame.origin.y < 120.0) {
            sub.hidden = YES;
        }
    }
}

+ (void)layoutLoggedInContentForViewController:(UIViewController *)viewController drawer:(MMDrawerController *)drawer
{
    if (!viewController.isViewLoaded || !drawer) {
        return;
    }
    NSString *topClass = NSStringFromClass([viewController class]);
    if ([topClass isEqualToString:@"leftSwipeViewController"]) {
        return;
    }

    CGFloat chromeBottom = [self topChromeBottomYForDrawer:drawer];
    if (chromeBottom < 1.0) {
        return;
    }

    UIView *root = viewController.view;
    CGFloat width = root.bounds.size.width;
    CGFloat height = root.bounds.size.height;
    CGFloat bottomInset = 0.0;
    if (@available(iOS 11.0, *)) {
        bottomInset = root.safeAreaInsets.bottom;
    }

    UIScrollView *scroll = [self czedr_firstScrollViewInView:root];
    if (scroll) {
        [self czedr_hideLegacyPageChromeInView:root scrollView:scroll];
        CGFloat contentH = MAX(scroll.contentSize.height, height - chromeBottom + 80.0);
        scroll.frame = CGRectMake(0.0, chromeBottom, width, height - chromeBottom - bottomInset);
        if (scroll.contentSize.height < contentH) {
            scroll.contentSize = CGSizeMake(width, contentH);
        }
        scroll.contentInset = UIEdgeInsetsZero;
        if (@available(iOS 11.0, *)) {
            scroll.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, bottomInset, 0);
        }
        return;
    }

    for (UIView *sub in root.subviews) {
        if (sub.tag == kCzedrTopChromeTag || sub.tag == kChromeBrandLogoStripTag) {
            continue;
        }
        if (sub.frame.origin.y < chromeBottom + 4.0) {
            sub.hidden = YES;
        }
    }
}

+ (UIView *)installSessionBarInViewController:(UIViewController *)host
{
    MMDrawerController *drawer = host.mm_drawerController;
    if (drawer) {
        [self refreshSessionBarForDrawer:drawer];
        UIView *host = [self chromeHostViewForDrawer:drawer];
        return [host viewWithTag:kCzedrTopChromeTag];
    }
    return nil;
}

+ (CGFloat)topChromeBottomYForView:(UIView *)view
{
    if (!view) {
        return 0;
    }
    CGFloat top = 0;
    if (@available(iOS 11.0, *)) {
        top = view.safeAreaInsets.top;
    }
    CGFloat chromeBottom = top;
    for (UIView *root in @[view]) {
        UIView *bar = [root viewWithTag:kCzedrTopChromeTag];
        if (bar && !bar.hidden && bar.superview) {
            chromeBottom = MAX(chromeBottom, CGRectGetMaxY(bar.frame));
        }
        UIView *strip = [root viewWithTag:kChromeBrandLogoStripTag];
        if (strip && !strip.hidden && strip.superview) {
            chromeBottom = MAX(chromeBottom, CGRectGetMaxY(strip.frame));
        }
    }
    return chromeBottom;
}

+ (CGFloat)topChromeBottomYForDrawer:(MMDrawerController *)drawer
{
    if (!drawer) {
        return 0;
    }
    UIView *host = [self chromeHostViewForDrawer:drawer];
    if (host) {
        return [self topChromeBottomYForView:host];
    }
    return [self topChromeBottomYForView:drawer.view];
}

+ (void)applyChromeContentInsetsForDrawer:(MMDrawerController *)drawer
{
    if (!drawer) {
        return;
    }
    UINavigationController *nav = nil;
    if ([drawer.centerViewController isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)drawer.centerViewController;
    }
    UIViewController *top = nav.topViewController;
    if (!top) {
        return;
    }
    NSString *topClass = NSStringFromClass([top class]);
    if ([topClass isEqualToString:@"leftSwipeViewController"]) {
        if (!UIEdgeInsetsEqualToEdgeInsets(top.additionalSafeAreaInsets, UIEdgeInsetsZero)) {
            top.additionalSafeAreaInsets = UIEdgeInsetsZero;
        }
        return;
    }
    if ([self czedr_firstScrollViewInView:top.view]) {
        if (!UIEdgeInsetsEqualToEdgeInsets(top.additionalSafeAreaInsets, UIEdgeInsetsZero)) {
            top.additionalSafeAreaInsets = UIEdgeInsetsZero;
        }
        return;
    }
    CGFloat chromeBottom = [self topChromeBottomYForDrawer:drawer];
    CGFloat baseTop = 0;
    if (@available(iOS 11.0, *)) {
        baseTop = top.view.safeAreaInsets.top;
    }
    CGFloat extraTop = MAX(0.0, chromeBottom - baseTop);
    UIEdgeInsets desired = UIEdgeInsetsMake(extraTop, 0, 0, 0);
    if (!UIEdgeInsetsEqualToEdgeInsets(top.additionalSafeAreaInsets, desired)) {
        top.additionalSafeAreaInsets = desired;
    }
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
    if (drawer && drawer.openSide != MMDrawerSideNone) {
        [drawer closeDrawerAnimated:NO completion:nil];
    }
    ViewController *login = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    login.additionalSafeAreaInsets = UIEdgeInsetsZero;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:login];
    nav.navigationBarHidden = YES;
    void (^showLoginNav)(void) = ^{
        if (drawer) {
            [drawer setCenterViewController:nav withCloseAnimation:NO completion:^(BOOL finished) {
                (void)finished;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([login isViewLoaded]) {
                        [login.view setNeedsLayout];
                        [login.view layoutIfNeeded];
                    }
                });
            }];
        } else if (host.navigationController) {
            [host.navigationController setViewControllers:@[login] animated:NO];
        } else {
            [host presentViewController:nav animated:YES completion:nil];
        }
    };
    showLoginNav();
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
