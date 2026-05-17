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

@implementation CzedrAppChrome

+ (UIButton *)sessionButton:(NSString *)title action:(SEL)action target:(id)target
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [CzedrTheme avenir:11.0 weight:@"heavy"];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.7;
    button.layer.cornerRadius = 4.0;
    button.clipsToBounds = YES;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

+ (UIView *)installSessionBarInViewController:(UIViewController *)host
{
    if ([host.view viewWithTag:kCzedrSessionBarTag]) {
        return [host.view viewWithTag:kCzedrSessionBarTag];
    }
    CGFloat height = 44.0;
    CGFloat inset = 8.0;
    CGFloat width = host.view.bounds.size.width;
    CGFloat y = host.view.bounds.size.height - height - inset;
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(inset, y, width - inset * 2, height)];
    bar.tag = kCzedrSessionBarTag;
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    bar.backgroundColor = [[CzedrTheme darkSurface] colorWithAlphaComponent:0.92];
    bar.layer.cornerRadius = 6.0;

    NSArray *titles = @[@"Logout", @"Minimize", @"Maximize", @"Exit"];
    NSArray *actions = @[@"sessionLogout:", @"sessionMinimize:", @"sessionMaximize:", @"sessionExit:"];
    CGFloat gap = 6.0;
    CGFloat buttonWidth = (bar.bounds.size.width - gap * 3.0) / 4.0;
    for (NSUInteger i = 0; i < titles.count; i++) {
        UIButton *btn = [self sessionButton:titles[i] action:NSSelectorFromString(actions[i]) target:host];
        btn.frame = CGRectMake(i * (buttonWidth + gap), 6.0, buttonWidth, height - 12.0);
        btn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        if ([titles[i] isEqualToString:@"Logout"] || [titles[i] isEqualToString:@"Exit"]) {
            [CzedrTheme styleRedPrimaryButton:btn];
        } else {
            [CzedrTheme styleCharcoalButton:btn];
        }
        [bar addSubview:btn];
    }
    [host.view addSubview:bar];
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
    [host.view endEditing:YES];
    if (drawer) {
        [drawer closeDrawerAnimated:YES completion:nil];
    }
}

+ (void)maximizeFromViewController:(UIViewController *)host drawer:(MMDrawerController *)drawer
{
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
