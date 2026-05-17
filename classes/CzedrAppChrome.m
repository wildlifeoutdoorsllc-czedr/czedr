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

static const NSInteger kCzedrSessionBarTag = 88040;

@interface CzedrSessionBarTarget : NSObject
@property (nonatomic, weak) MMDrawerController *drawer;
- (void)sessionLogout:(id)sender;
- (void)sessionMinimize:(id)sender;
- (void)sessionMaximize:(id)sender;
- (void)sessionExit:(id)sender;
@end

@implementation CzedrSessionBarTarget

- (UIViewController *)actionHost
{
    if (!self.drawer) {
        return nil;
    }
    UIViewController *host = self.drawer.centerViewController;
    if ([host isKindOfClass:[UINavigationController class]]) {
        host = [(UINavigationController *)host topViewController] ?: host;
    }
    return host;
}

- (void)sessionLogout:(id)sender
{
    (void)sender;
    UIViewController *host = [self actionHost];
    if (host) {
        [CzedrAppChrome logoutFromViewController:host drawer:self.drawer];
    }
}

- (void)sessionMinimize:(id)sender
{
    (void)sender;
    UIViewController *host = [self actionHost];
    if (host) {
        [CzedrAppChrome minimizeFromViewController:host drawer:self.drawer];
    }
}

- (void)sessionMaximize:(id)sender
{
    (void)sender;
    UIViewController *host = [self actionHost];
    if (host) {
        [CzedrAppChrome maximizeFromViewController:host drawer:self.drawer];
    }
}

- (void)sessionExit:(id)sender
{
    (void)sender;
    UIViewController *host = [self actionHost];
    if (host) {
        [CzedrAppChrome exitFromViewController:host drawer:self.drawer];
    }
}

@end

@implementation CzedrAppChrome

static CzedrSessionBarTarget *CzedrSessionBarTargetShared(void)
{
    static CzedrSessionBarTarget *target = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        target = [[CzedrSessionBarTarget alloc] init];
    });
    return target;
}

+ (BOOL)isLoggedIn
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"auth_codeSaved"].length > 0;
}

+ (UIButton *)sessionButton:(NSString *)title action:(SEL)action target:(id)target
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [CzedrTheme avenir:11.0 weight:@"heavy"];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.65;
    button.titleLabel.numberOfLines = 1;
    button.layer.cornerRadius = 5.0;
    button.clipsToBounds = YES;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25].CGColor;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

+ (void)layoutSessionBar:(UIView *)bar inContainerView:(UIView *)containerView
{
    if (!bar || !containerView) {
        return;
    }
    CGFloat height = 48.0;
    CGFloat horizontalInset = 10.0;
    CGFloat bottomInset = 6.0;
    if (@available(iOS 11.0, *)) {
        bottomInset += containerView.safeAreaInsets.bottom;
    }
    CGFloat width = containerView.bounds.size.width;
    CGFloat y = containerView.bounds.size.height - height - bottomInset;
    bar.frame = CGRectMake(horizontalInset, y, width - horizontalInset * 2.0, height);

    NSArray *buttons = bar.subviews;
    if (buttons.count == 0) {
        return;
    }
    CGFloat gap = 6.0;
    CGFloat buttonWidth = (bar.bounds.size.width - gap * ((CGFloat)buttons.count - 1.0)) / (CGFloat)buttons.count;
    for (NSUInteger i = 0; i < buttons.count; i++) {
        UIView *sub = buttons[i];
        if (![sub isKindOfClass:[UIButton class]]) {
            continue;
        }
        sub.frame = CGRectMake(i * (buttonWidth + gap), 4.0, buttonWidth, height - 8.0);
    }
}

+ (UIView *)buildSessionBarWithTarget:(CzedrSessionBarTarget *)target
{
    CGFloat height = 48.0;
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, height)];
    bar.tag = kCzedrSessionBarTag;
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    bar.backgroundColor = [[CzedrTheme darkSurface] colorWithAlphaComponent:0.96];
    bar.layer.cornerRadius = 8.0;
    bar.layer.borderWidth = 1.0;
    bar.layer.borderColor = [[CzedrTheme redPrimary] colorWithAlphaComponent:0.55].CGColor;
    bar.layer.shadowColor = [UIColor blackColor].CGColor;
    bar.layer.shadowOpacity = 0.35;
    bar.layer.shadowRadius = 4.0;
    bar.layer.shadowOffset = CGSizeMake(0, -2);

    NSArray *titles = @[@"Logout", @"Minimize", @"Maximize", @"Exit"];
    NSArray *actions = @[@"sessionLogout:", @"sessionMinimize:", @"sessionMaximize:", @"sessionExit:"];
    for (NSUInteger i = 0; i < titles.count; i++) {
        UIButton *btn = [self sessionButton:titles[i] action:NSSelectorFromString(actions[i]) target:target];
        if ([titles[i] isEqualToString:@"Logout"] || [titles[i] isEqualToString:@"Exit"]) {
            [CzedrTheme styleRedPrimaryButton:btn];
        } else {
            [CzedrTheme styleCharcoalButton:btn];
        }
        [bar addSubview:btn];
    }
    return bar;
}

+ (void)removeSessionBarFromDrawer:(MMDrawerController *)drawer
{
    if (!drawer) {
        return;
    }
    UIView *bar = [drawer.view viewWithTag:kCzedrSessionBarTag];
    [bar removeFromSuperview];
}

+ (void)refreshSessionBarForDrawer:(MMDrawerController *)drawer
{
    if (!drawer) {
        return;
    }
    if (![self isLoggedIn]) {
        [self removeSessionBarFromDrawer:drawer];
        return;
    }

    CzedrSessionBarTarget *target = CzedrSessionBarTargetShared();
    target.drawer = drawer;

    UIView *bar = [drawer.view viewWithTag:kCzedrSessionBarTag];
    if (!bar) {
        bar = [self buildSessionBarWithTarget:target];
        [drawer.view addSubview:bar];
    }
    [self layoutSessionBar:bar inContainerView:drawer.view];
    bar.hidden = NO;
    bar.userInteractionEnabled = YES;
    [drawer.view bringSubviewToFront:bar];
}

+ (UIView *)installSessionBarInViewController:(UIViewController *)host
{
    MMDrawerController *drawer = host.mm_drawerController;
    if (drawer) {
        [self refreshSessionBarForDrawer:drawer];
        return [drawer.view viewWithTag:kCzedrSessionBarTag];
    }
    if (![self isLoggedIn]) {
        return nil;
    }
    UIView *bar = [host.view viewWithTag:kCzedrSessionBarTag];
    if (!bar) {
        CzedrSessionBarTarget *target = CzedrSessionBarTargetShared();
        target.drawer = drawer;
        bar = [self buildSessionBarWithTarget:target];
        [host.view addSubview:bar];
    }
    [self layoutSessionBar:bar inContainerView:host.view];
    [host.view bringSubviewToFront:bar];
    return bar;
}

+ (void)clearLocalSession
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"auth_codeSaved"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userDataArray"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"profile_pic"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
