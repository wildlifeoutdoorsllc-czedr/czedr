//
//  ViewController.m
//  payooxe
//
//  Created by Renu on 01/01/09.
//  Copyright (c) 2009 Renu. All rights reserved.
//

#import "ViewController.h"
#import "CzedrTheme.h"
#import "forgotViewController.h"
#import "loginViewController.h"
#import "leftSwipeViewController.h"
#import "AppDelegate.h"
#import "SharedServiceController.h"
#import "GeneratePinViewController.h"
#import "CzedrRuntimeConfig.h"
#import "CzedrAppChrome.h"
#import "UIViewController+MMDrawerController.h"

@interface ViewController () <UITextFieldDelegate>
@property (nonatomic, weak) UIImageView *brandLogoView;
@end

@implementation ViewController

- (UIView *)hudHostView
{
    return self.view;
}

- (void)ensureUserInfoData
{
    if (!user_infodata) {
        user_infodata = [[NSMutableArray alloc] init];
    }
}

- (void)completeLoginWithPayload:(NSDictionary *)data
{
    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }
    [self ensureUserInfoData];
    [user_infodata removeAllObjects];
    [user_infodata addObject:data];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (loginbutton) {
            loginbutton.enabled = YES;
            [loginbutton setTitle:NSLocalizedString(@"Sign in", Nil) forState:UIControlStateNormal];
        }

        if ([[NSUserDefaults standardUserDefaults] stringForKey:@"auth_codeSaved"].length == 0) {
            [self czedr_showAlert:@"Sign-in succeeded but the session was not saved. Try again."];
            return;
        }

        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if ([app isKindOfClass:[AppDelegate class]]) {
            [app handleLoginSuccessWithPayload:data];
        }
    });
}

- (UIImageView *)czedr_brandLogoView
{
    if (self.brandLogoView) {
        return self.brandLogoView;
    }
    for (UIView *sub in _viewDetail.subviews) {
        if ([sub isKindOfClass:[UIImageView class]]) {
            self.brandLogoView = (UIImageView *)sub;
            return self.brandLogoView;
        }
    }
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (![self isMemberOfClass:[ViewController class]]) {
        return;
    }
    user_infodata=[[NSMutableArray alloc]init];
    _email.delegate = self;
    _password.delegate = self;
    
    NSString *strEmail = NSLocalizedString(@"email address", Nil);
    _email.placeholder = strEmail;
    
    NSString *strPwd = NSLocalizedString(@"password", Nil);
    _password.placeholder = strPwd;
    
    NSString *strLogin = NSLocalizedString(@"Sign in", Nil);
    [loginbutton setTitle:strLogin forState:UIControlStateNormal];

    NSString *strForgotPwd = NSLocalizedString(@"forgot password?", Nil);
    [forgetbutton setTitle: strForgotPwd forState: UIControlStateNormal];

    NSString *strRegister = NSLocalizedString(@"Register new account", Nil);
    [signupbutton setTitle:strRegister forState:UIControlStateNormal];
    signupbutton.titleLabel.numberOfLines = 2;
    signupbutton.titleLabel.textAlignment = NSTextAlignmentCenter;
    signupbutton.titleLabel.adjustsFontSizeToFitWidth = YES;

    UILabel *signInTitle = (UILabel *)[_viewDetail viewWithTag:8801];
    if (signInTitle) {
        signInTitle.hidden = YES;
    }

    _viewDetail.autoresizingMask = UIViewAutoresizingNone;
    _viewDetail.translatesAutoresizingMaskIntoConstraints = YES;
    for (UIView *sub in _viewDetail.subviews) {
        sub.autoresizingMask = UIViewAutoresizingNone;
        sub.translatesAutoresizingMaskIntoConstraints = YES;
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![self isMemberOfClass:[ViewController class]]) {
        return;
    }
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    _viewDetail.layer.cornerRadius = 0;
    _viewDetail.clipsToBounds = YES;
    loginbutton.layer.cornerRadius=3;
    loginbutton.clipsToBounds=YES;
    signupbutton.layer.cornerRadius=3;
    signupbutton.clipsToBounds=YES;
    _email.layer.cornerRadius=3;
    _email.clipsToBounds = YES;
    _password.layer.cornerRadius=3;
    _password.clipsToBounds = YES;
    UIFont *fieldFont = [UIFont fontWithName:@"AVENIR" size:14.0];
    [CzedrTheme applyPlaceholderAppearanceToTextField:_email color:[UIColor whiteColor] font:fieldFont];
    [CzedrTheme applyPlaceholderAppearanceToTextField:_password color:[UIColor whiteColor] font:fieldFont];
   loginbutton.titleLabel.font = [UIFont fontWithName:@"AVENIR" size:12.0];
    signupbutton.titleLabel.font = [UIFont fontWithName:@"AVENIR" size:12.0];
    forgetbutton.titleLabel.font = [UIFont fontWithName:@"AVENIR" size:12.0];
    _email.font = [CzedrTheme avenir:16.0 weight:@"roman"];
    _password.font = [CzedrTheme avenir:16.0 weight:@"roman"];
    _email.textAlignment = NSTextAlignmentLeft;
    _password.textAlignment = NSTextAlignmentLeft;
    _email.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    _email.leftViewMode = UITextFieldViewModeAlways;
    _password.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    _password.leftViewMode = UITextFieldViewModeAlways;
    [CzedrTheme styleEmailField:_email];
    [CzedrTheme stylePasswordField:_password];
    [CzedrTheme styleOrangeField:_email];
    [CzedrTheme styleOrangeField:_password];
    [CzedrTheme applyAuthDarkScreen:self.view detailPanel:_viewDetail logoView:[self czedr_brandLogoView]];
    [CzedrTheme styleRedPrimaryButton:loginbutton];
    [CzedrTheme styleCharcoalButton:signupbutton];
    [forgetbutton setTitleColor:[[CzedrTheme lightText] colorWithAlphaComponent:0.75] forState:UIControlStateNormal];

    _viewDetail.userInteractionEnabled = YES;
    self.view.userInteractionEnabled = YES;
    if (loginbutton) {
        loginbutton.enabled = YES;
        loginbutton.userInteractionEnabled = YES;
        [loginbutton setTitle:NSLocalizedString(@"Sign in", Nil) forState:UIControlStateNormal];
    }
    if (_email) {
        _email.userInteractionEnabled = YES;
    }
    if (_password) {
        _password.userInteractionEnabled = YES;
    }
    [self czedr_layoutFullScreenSignIn];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (![self isMemberOfClass:[ViewController class]]) {
        return;
    }
    [self czedr_layoutFullScreenSignIn];
}

- (UIView *)czedr_authDividerView
{
    for (UIView *sub in _viewDetail.subviews) {
        if (sub.frame.size.height <= 2 && sub.frame.size.width > 100) {
            return sub;
        }
    }
    return nil;
}

- (void)czedr_bringAuthControlsToFront
{
    UIImageView *logo = [self czedr_brandLogoView];
    if (logo) {
        [_viewDetail bringSubviewToFront:logo];
    }
    if (_email) {
        [_viewDetail bringSubviewToFront:_email];
    }
    if (_password) {
        [_viewDetail bringSubviewToFront:_password];
    }
    if (loginbutton) {
        [_viewDetail bringSubviewToFront:loginbutton];
    }
    if (forgetbutton) {
        [_viewDetail bringSubviewToFront:forgetbutton];
    }
    UIView *divider = [self czedr_authDividerView];
    if (divider) {
        [_viewDetail bringSubviewToFront:divider];
    }
    if (signupbutton) {
        [_viewDetail bringSubviewToFront:signupbutton];
    }
}

- (void)czedr_layoutFullScreenSignIn
{
    if (!_viewDetail) {
        return;
    }
    _viewDetail.autoresizingMask = UIViewAutoresizingNone;

    CGRect host = self.view.bounds;
    if (@available(iOS 11.0, *)) {
        host = UIEdgeInsetsInsetRect(host, self.view.safeAreaInsets);
    }
    _viewDetail.frame = host;
    _viewDetail.layer.cornerRadius = 0;
    _viewDetail.layer.borderWidth = 0;
    _viewDetail.layer.shadowOpacity = 0;

    CGFloat panelW = CGRectGetWidth(host);
    CGFloat panelH = CGRectGetHeight(host);
    CGFloat side = 24.0;
    CGFloat fieldW = panelW - side * 2.0;
    CGFloat fieldX = side;
    const CGFloat fieldH = 52.0;
    const CGFloat btnH = 52.0;
    const CGFloat rowGap = 20.0;
    const CGFloat bottomPad = 32.0;
    const CGFloat topPad = 16.0;

    UILabel *signInTitle = (UILabel *)[_viewDetail viewWithTag:8801];
    if (signInTitle) {
        signInTitle.hidden = YES;
    }

    CGFloat y = topPad;
    UIImageView *logo = [self czedr_brandLogoView];
    if (logo) {
        UIImage *img = logo.image ?: [CzedrTheme brandAuthLogoImage];
        if (img) {
            CGFloat maxW = panelW - 40.0;
            CGFloat maxLogoH = panelH * 0.26;
            CGFloat aspect = img.size.width / MAX(img.size.height, 1.0);
            CGFloat height = MIN(maxLogoH, maxW / MAX(aspect, 0.5));
            CGFloat width = height * aspect;
            logo.frame = CGRectMake((panelW - width) / 2.0, y, width, height);
            logo.contentMode = UIViewContentModeScaleAspectFit;
            logo.backgroundColor = [UIColor clearColor];
            logo.hidden = NO;
            y = CGRectGetMaxY(logo.frame);
        }
    }

    CGFloat registerY = panelH - bottomPad - btnH;
    const CGFloat formH = fieldH + rowGap + fieldH + rowGap + btnH + rowGap + 32.0 + rowGap + 1.0 + rowGap;
    CGFloat formStartY = y + MAX(36.0, (registerY - y - formH - 24.0) * 0.45);
    y = formStartY;

    if (_email) {
        _email.frame = CGRectMake(fieldX, y, fieldW, fieldH);
        _email.textAlignment = NSTextAlignmentLeft;
        y += fieldH + rowGap;
    }
    if (_password) {
        _password.frame = CGRectMake(fieldX, y, fieldW, fieldH);
        _password.textAlignment = NSTextAlignmentLeft;
        y += fieldH + rowGap;
    }
    if (loginbutton) {
        loginbutton.frame = CGRectMake(fieldX, y, fieldW, btnH);
        y += btnH + rowGap;
    }
    if (forgetbutton) {
        forgetbutton.frame = CGRectMake(fieldX, y, fieldW, 32.0);
        y += 32.0 + rowGap;
    }
    UIView *divider = [self czedr_authDividerView];
    if (divider) {
        divider.frame = CGRectMake(fieldX, y, fieldW, 1.0);
        y += 1.0 + rowGap;
    }
    if (signupbutton) {
        signupbutton.frame = CGRectMake(fieldX, registerY, fieldW, btnH);
    }

    [self czedr_bringAuthControlsToFront];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (![self isMemberOfClass:[ViewController class]]) {
        return;
    }
    [CzedrTheme applyAuthDarkScreen:self.view detailPanel:_viewDetail logoView:[self czedr_brandLogoView]];
    _viewDetail.layer.cornerRadius = 0;
    _viewDetail.layer.borderWidth = 0;
    _viewDetail.layer.shadowOpacity = 0;
    [self czedr_layoutFullScreenSignIn];
}

- (void)czedr_showAlert:(NSString *)message
{
    if (message.length == 0) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *presenter = self;
    if (!presenter.view.window) {
        presenter = self.navigationController ?: (UIViewController *)[UIApplication sharedApplication].delegate;
    }
    if (presenter) {
        [presenter presentViewController:alert animated:YES completion:nil];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _email) {
        [_password becomeFirstResponder];
    } else {
        [_password resignFirstResponder];
    }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)loginButton:(id)sender
{
    (void)sender;
    if (_email.text.length==0)
    {
        NSString *strEnterEmail = NSLocalizedString(@"enter email", Nil);
        [self czedr_showAlert:strEnterEmail];
        return;
    }
    else if (_password.text.length==0)
    {
        NSString *strEntrPwd = NSLocalizedString(@"enter password", Nil);
        [self czedr_showAlert:strEntrPwd];
        return;
    }
   else if([_email.text length] > 0)
   {
       NSString *rawString = [_email text];
       NSString *rawString2 = [_password text];
       NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
       NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
       NSString *trimmed2 = [rawString2 stringByTrimmingCharactersInSet:whitespace];
       if ([trimmed length] == 0 || [trimmed2 length] == 0)
       {
           NSString *strCorrectValues = NSLocalizedString(@"correct values", Nil);
           [self czedr_showAlert:strCorrectValues];
       }
       else
       {
           _email.text = trimmed;
           _password.text = trimmed2;
           [self call_LoginService];
       }
   }
}

-(void)call_LoginService
{
    if (_email) {
        [_email resignFirstResponder];
    }
    if (_password) {
        [_password resignFirstResponder];
    }

    NSString *apiBase = [CzedrEffectiveAPIBase() stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (apiBase.length == 0) {
        [self czedr_showAlert:@"This build has no API server configured. Reinstall from TestFlight or contact support."];
        return;
    }
    CzedrSetAPIBaseOverride(apiBase);

    if (loginbutton) {
        loginbutton.enabled = NO;
        [loginbutton setTitle:@"Signing in…" forState:UIControlStateNormal];
    }
    [self performLoginRequest];
}

- (void)performLoginRequest
{
    __weak typeof(self) weakSelf = self;
    if ([SharedServiceController usesV1API]) {
        [SharedServiceController loginSecureWithEmail:self.email.text
                                             password:self.password.text
                                              success:^(NSDictionary *data) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            [strongSelf completeLoginWithPayload:data];
        } failure:^(NSString *message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                if (loginbutton) {
                    loginbutton.enabled = YES;
                    [loginbutton setTitle:NSLocalizedString(@"Sign in", Nil) forState:UIControlStateNormal];
                }
                [strongSelf czedr_showAlert:message];
            });
        }];
        return;
    }

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:self.email.text forKey:@"user_email"];
    [params setValue:self.password.text forKey:@"user_pwd"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:[NSString stringWithFormat:@"%s/%s", base_url, "login"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [MBProgressHUD hideHUDForView:strongSelf.view animated:NO];
        NSString *response = [NSString stringWithFormat:@"%@", operation.responseString];
        NSString *status = [NSString stringWithFormat:@"%@", [[response JSONValue] valueForKey:@"Status"]];
        if ([status isEqualToString:@"true"]) {
            NSDictionary *data = [[response JSONValue] valueForKey:@"Data"];
            [SharedServiceController saveLoginPayload:data];
            [strongSelf completeLoginWithPayload:data];
        } else {
            NSString *Alertstatus = [NSString stringWithFormat:@"%@", [[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0] valueForKey:@"result"]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        (void)operation;
        (void)error;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [MBProgressHUD hideHUDForView:[strongSelf hudHostView] animated:NO];
        NSString *strErrorMsg = NSLocalizedString(@"error", Nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:strErrorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }];
}

- (IBAction)forgotPassword:(id)sender
{
    forgotViewController *forgot=[[forgotViewController alloc]initWithNibName:@"forgotViewController" bundle:nil];
    [self.navigationController pushViewController:forgot animated:YES];
}

- (IBAction)SignUp:(id)sender
{
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    loginViewController *login=[[loginViewController alloc]initWithNibName:@"loginViewController" bundle:nil];
    [self.navigationController pushViewController:login
                                         animated:YES];
}

-(void)parse_registerService
{
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int reach = [reachAbilty updateInterfaceWithReachability];
    if (reach==0)
    {
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else
    {
        if ([SharedServiceController usesV1API]) {
            return;
        }

        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] forKey:@"auth_code"];
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"objectId"] forKey:@"obj_token"];
        [params setValue:@"ios" forKey:@"type"];
        
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"registeredtoken"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             [MBProgressHUD hideHUDForView:self.view animated:YES];
         }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
              }];
    }
}
@end
