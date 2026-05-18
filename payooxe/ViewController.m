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
#import "CzedrLanAPIFinder.h"
#import "CzedrAppChrome.h"
#import "UIViewController+MMDrawerController.h"

@interface ViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *apiBaseTextField;
@property (nonatomic, assign) BOOL apiDiscoveryInFlight;
@end

@implementation ViewController

- (UIView *)hudHostView
{
    // Keep HUD on the login view only (window/keyWindow HUD + drawer swaps caused crashes on device).
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Sign-in succeeded but the session was not saved. Try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return;
        }

        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if ([app isKindOfClass:[AppDelegate class]]) {
            [app handleLoginSuccessWithPayload:data];
        }
    });
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
    if (!signInTitle) {
        signInTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 198, 230, 22)];
        signInTitle.tag = 8801;
        signInTitle.textAlignment = NSTextAlignmentCenter;
        signInTitle.font = [CzedrTheme avenir:15.0 weight:@"heavy"];
        signInTitle.textColor = [CzedrTheme lightText];
        [_viewDetail addSubview:signInTitle];
    }
    signInTitle.text = NSLocalizedString(@"Sign in", Nil);

    if (!self.apiBaseTextField) {
        UITextField *apiField = [[UITextField alloc] initWithFrame:CGRectMake(20, 186, 230, 28)];
        apiField.delegate = self;
        apiField.textAlignment = NSTextAlignmentCenter;
        apiField.backgroundColor = _email.backgroundColor;
        apiField.textColor = [UIColor whiteColor];
        apiField.font = [UIFont fontWithName:@"AVENIR" size:12.0];
        apiField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        apiField.autocorrectionType = UITextAutocorrectionTypeNo;
        apiField.keyboardType = UIKeyboardTypeURL;
        apiField.returnKeyType = UIReturnKeyNext;
        apiField.clearButtonMode = UITextFieldViewModeWhileEditing;
        apiField.layer.cornerRadius = 3;
        apiField.clipsToBounds = YES;
        apiField.text = CzedrEffectiveAPIBase();
        apiField.placeholder = @"API server (http://…:8080)";
        [CzedrTheme applyPlaceholderAppearanceToTextField:apiField color:[UIColor whiteColor] font:apiField.font];
        [_viewDetail addSubview:apiField];
        self.apiBaseTextField = apiField;

        const CGFloat shift = 36;
        for (UIView *field in @[_email, _password, loginbutton, forgetbutton, signupbutton]) {
            CGRect frame = field.frame;
            frame.origin.y += shift;
            field.frame = frame;
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![self isMemberOfClass:[ViewController class]]) {
        return;
    }
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    _viewDetail.layer.cornerRadius =10;
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
    if (self.apiBaseTextField) {
        self.apiBaseTextField.layer.cornerRadius = 3;
        self.apiBaseTextField.clipsToBounds = YES;
        [CzedrTheme applyPlaceholderAppearanceToTextField:self.apiBaseTextField color:[UIColor whiteColor] font:self.apiBaseTextField.font];
    }
   loginbutton.titleLabel.font = [UIFont fontWithName:@"AVENIR" size:12.0];
    signupbutton.titleLabel.font = [UIFont fontWithName:@"AVENIR" size:12.0];
    forgetbutton.titleLabel.font = [UIFont fontWithName:@"AVENIR" size:12.0];
    _email.font=[UIFont fontWithName:@"AVENIR" size:14.0];
    _password.font=[UIFont fontWithName:@"AVENIR" size:14.0];
    [CzedrTheme applyDeckLookToView:self.view];
    [CzedrTheme styleEmailField:_email];
    [CzedrTheme stylePasswordField:_password];
    [CzedrTheme applyAuthDarkScreen:self.view detailPanel:_viewDetail logoView:nil];
    [CzedrTheme styleRedPrimaryButton:loginbutton];
    [CzedrTheme styleCharcoalButton:signupbutton];
    [forgetbutton setTitleColor:[[CzedrTheme lightText] colorWithAlphaComponent:0.75] forState:UIControlStateNormal];
    [self discoverAPIServerAutomatically];
}

- (void)discoverAPIServerAutomatically
{
    if (!self.apiBaseTextField || self.apiDiscoveryInFlight) {
        return;
    }
    self.apiDiscoveryInFlight = YES;
    self.apiBaseTextField.placeholder = @"Finding server on Wi‑Fi…";
    __weak typeof(self) weakSelf = self;
    [CzedrLanAPIFinder resolveWithCompletion:^(NSString *baseURL, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.apiDiscoveryInFlight = NO;
        if (baseURL.length > 0) {
            strongSelf.apiBaseTextField.text = baseURL;
            strongSelf.apiBaseTextField.placeholder = @"API server (found automatically)";
        } else {
            strongSelf.apiBaseTextField.placeholder = @"API server (http://…:8080)";
        }
    }];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    CGFloat offset = 0;
    if (textField == self.apiBaseTextField) {
        offset = -40;
    } else if (textField == _email) {
        offset = -80;
    } else if (textField == _password) {
        offset = -120;
    }
    if (offset != 0) {
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, offset, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    return YES;
}
    
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    
    if (textField == self.apiBaseTextField) {
        [_email becomeFirstResponder];
    } else if (textField == _email) {
        [_password becomeFirstResponder];
    } else {
        [_password resignFirstResponder];
    }
    // if (textField==_password) {
    //    [_password resignFirstResponder];
    //    [self loginButton:nil];
    // }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButton:(id)sender
{
    (void)sender;
    if (_email.text.length==0)
    {
        NSString *strEnterEmail = NSLocalizedString(@"enter email", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strEnterEmail delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if (_password.text.length==0)
    {
        NSString *strEntrPwd = NSLocalizedString(@"enter password", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strEntrPwd delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
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
           NSString *strAttention = NSLocalizedString(@"Attention", Nil);
           NSString *strCorrectValues = NSLocalizedString(@"correct values", Nil);
           NSString *strOk = NSLocalizedString(@"OK", Nil);
           UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strAttention message:strCorrectValues delegate:nil cancelButtonTitle:strOk otherButtonTitles: nil];
           [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
       }
       else
       {
           _email.text = trimmed;
           _password.text = trimmed2;
           [self call_LoginService];
       }
   }
//    GeneratePinViewController *OBJ=[[GeneratePinViewController alloc]initWithNibName:@"GeneratePinViewController" bundle:nil];
//    [self.navigationController pushViewController:OBJ animated:YES];
}

-(void)call_LoginService
{
    if (_email) {
        [_email resignFirstResponder];
    }
    if (_password) {
        [_password resignFirstResponder];
    }
    if (self.apiBaseTextField && self.apiBaseTextField.superview) {
        [self.apiBaseTextField resignFirstResponder];
    }

    NSString *apiBase = @"";
    if (self.apiBaseTextField) {
        apiBase = [self.apiBaseTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if (apiBase.length == 0) {
        apiBase = [CzedrEffectiveAPIBase() stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if (apiBase.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Enter the API server URL (e.g. http://192.168.x.x:8080 on a physical iPhone)." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    if (![apiBase hasPrefix:@"http://"] && ![apiBase hasPrefix:@"https://"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"API server must start with http:// or https://" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
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
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
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

//Login registter:-(for paser notification register device on server)
// Push token registration uses Czedr API via SharedServiceController

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
        
        //[[NSUserDefaults standardUserDefaults] valueForKey:@"objectId"]
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"registeredtoken"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 
             }
             else
             {
                 
             }
         }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
                 
              }];
    }
}
@end
