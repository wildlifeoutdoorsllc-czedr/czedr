//
//  forgotViewController.m
//  payoox
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import "forgotViewController.h"
#import "CzedrTheme.h"
#import "ViewController.h"
#import "SharedServiceController.h"
@interface forgotViewController ()

@end

@implementation forgotViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *strCancel = NSLocalizedString(@"Cancel", Nil);
    [_cancel setTitle: strCancel forState: UIControlStateNormal];
    _cancel.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    NSString *strForgotlbl = NSLocalizedString(@"forgot password?", Nil);
    forgotlbl.text = [strForgotlbl capitalizedString];
    
    NSString *strDontWry = NSLocalizedString(@"Don't worry!", Nil);
    textlbl.text = strDontWry;
    
    strEmailAdrs = NSLocalizedString(@"email address", Nil);
    _emailAddress.text = strEmailAdrs;
    
    NSString *strResetPwd = NSLocalizedString(@"RESET PASSWORD", Nil);
    [_ResetPassword setTitle: strResetPwd forState: UIControlStateNormal];
    _ResetPassword.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    
    if([[[NSUserDefaults standardUserDefaults] valueForKey:@"pin"] isEqualToString:@"forgot"])
    {
        NSString *strResetPin = NSLocalizedString(@"Reset Pin", Nil);
        [_ResetPassword setTitle: strResetPin forState: UIControlStateNormal];
        
        NSString *strDontWry = NSLocalizedString(@"Don't worry! Pin", Nil);
        textlbl.text = strDontWry;
        
        NSString *strForgotPin = NSLocalizedString(@"Forgot Pin", Nil);
//      forgotlbl.text=@"Forgot Pin?";
        forgotlbl.text = [NSString stringWithFormat:@"%@%@",strForgotPin,@"?"];
    }
  
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    _Viewdetail1.layer.cornerRadius = 10;
    _Viewdetail1.clipsToBounds = YES;
    _emailAddress.layer.cornerRadius=3;
    _emailAddress.clipsToBounds = YES;
    _ResetPassword.layer.cornerRadius=3;
    _ResetPassword.clipsToBounds = YES;
    [CzedrTheme applyPlaceholderAppearanceToTextField:_emailAddress color:[UIColor whiteColor] font:nil];
    [CzedrTheme applyDeckLookToView:self.view];
    [CzedrTheme applyAuthDarkScreen:self.view detailPanel:_Viewdetail1 logoView:nil];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField==_emailAddress)
    {
        _emailAddress.text = @"";
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.view.frame = CGRectMake(0, -170, self.view.frame.size.width, self.view.frame.size.height);
        } completion:nil];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_emailAddress resignFirstResponder];
    
    if ([textField.text  isEqual: @""])
    {
        _emailAddress.text = strEmailAdrs;
    }
    
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
        return YES;
}


- (IBAction)cancelButton:(id)sender {
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)resetPassword:(id)sender
{
    [_emailAddress resignFirstResponder];
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    if (_emailAddress.text.length==0)
    {
        NSString *strEnterEmail = NSLocalizedString(@"enter email", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strEnterEmail delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if([_emailAddress.text length] > 0 )
    {
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        int checkValue=[emailTest evaluateWithObject:_emailAddress.text];
        if (checkValue==0)
        {
            NSString *strAttention = NSLocalizedString(@"Attention", Nil);
            NSString *strAddress = NSLocalizedString(@"address is invalid", Nil);
            NSString *strOk = NSLocalizedString(@"OK", Nil);

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strAttention
                                                            message:strAddress
                                                           delegate:nil
                                                  cancelButtonTitle:strOk
                                                  otherButtonTitles: nil];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
            return;
        }
        else
        {
            NSString *rawString = [_emailAddress text];
        
            NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
            
            if ([trimmed length] == 0 )
            {
                NSString *strAttention = NSLocalizedString(@"Attention", Nil);
                NSString *strCorrectValues = NSLocalizedString(@"correct values", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strAttention message:strCorrectValues delegate:nil cancelButtonTitle:strOk otherButtonTitles: nil];
                [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
            }
            else
            {
                if([[[NSUserDefaults standardUserDefaults] valueForKey:@"pin"] isEqualToString:@"forgot"])
                {
                    
                    [self call_resetPinService];
                }
                else
                {
                     [self call_resetPasswordService];
                }
            }
        }
    }
   
}
-(void)call_resetPasswordService
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
        if ([SharedServiceController usesV1API] &&
            ![[[NSUserDefaults standardUserDefaults] valueForKey:@"pin"] isEqualToString:@"forgot"]) {
            NSString *email = [_emailAddress.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [SharedServiceController requestPasswordResetForEmail:email
                success:^(NSDictionary *data) {
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    [self presentV1PasswordResetDialogWithEmail:email response:data];
                }
                failure:^(NSString *message) {
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }];
            return;
        }

        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];//
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] forKey:@"auth_code"];
        [params setValue:_emailAddress.text forKey:@"user_email"];
      
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"forgotpwd"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 NSString *str = NSLocalizedString(@"password has been reset", Nil);
                 NSString *strOk = NSLocalizedString(@"OK", Nil);

                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                    [alert show];
                [self.navigationController popViewControllerAnimated:YES];
             }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([Alertstatus isEqual:@"The entered email address is not a valid registered user id. Please enter your registered email address."])
                     {
                         Alertstatus = @"L'adresse e-mail saisie n'est pas un identifiant utilisateur valide. Entrez votre adresse e-mail enregistrée.";
                     }
                     else if ([Alertstatus isEqual:@" A new password has been sent to your email. Please check email for further instructions."])
                     {
                         Alertstatus = @"Un nouveau mot de passe a été envoyé à votre email. Veuillez vérifier le courrier électronique pour plus d'instructions.";
                     }
                 }
                 
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                 [alert show];
                 return;
             }
         }
         
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
               
                  NSString *strErrorMsg = NSLocalizedString(@"error", Nil);
                  NSString *strOk = NSLocalizedString(@"OK", Nil);
                  
                  UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strErrorMsg delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                  [alert show];
              }];
    }
}

- (void)presentV1PasswordResetDialogWithEmail:(NSString *)email response:(NSDictionary *)data
{
    NSString *message = [data objectForKey:@"message"];
    if (message.length == 0) {
        message = @"If this email is registered, reset instructions were sent.";
    }
    NSString *devToken = [data objectForKey:@"reset_token"];
    if (devToken.length > 0) {
        message = [NSString stringWithFormat:@"%@\n\nDev reset code (local server only):\n%@", message, devToken];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset password"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Reset code from email";
        if (devToken.length > 0) {
            textField.text = devToken;
        }
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"New password (10+ characters)";
        textField.secureTextEntry = YES;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Set new password" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *token = alert.textFields.count > 0 ? alert.textFields[0].text : @"";
        NSString *newPassword = alert.textFields.count > 1 ? alert.textFields[1].text : @"";
        if (token.length == 0 || newPassword.length < 10) {
            UIAlertView *bad = [[UIAlertView alloc] initWithTitle:@"" message:@"Enter the reset code and a password of at least 10 characters." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [bad show];
            return;
        }
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [SharedServiceController completePasswordResetWithToken:token
                                                    newPassword:newPassword
                                                        success:^(NSDictionary *result) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSString *msg = [result objectForKey:@"message"] ?: @"Password has been reset. You can sign in now.";
            UIAlertView *ok = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [ok show];
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSString *err) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            UIAlertView *fail = [[UIAlertView alloc] initWithTitle:@"" message:err delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [fail show];
        }];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

-(void)call_resetPinService
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
    else{
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
         [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] forKey:@"auth_code"];
        [params setValue:_emailAddress.text forKey:@"user_email"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"forgotpin"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"pin"];
             [[NSUserDefaults standardUserDefaults] synchronize];
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 NSString *str = NSLocalizedString(@"Your pin has been reset", Nil);
                 NSString *strOk = NSLocalizedString(@"OK", Nil);

                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                 [alert show];
                 [self.navigationController popViewControllerAnimated:YES];
             }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([Alertstatus isEqual:@"The entered email address is not a valid registered user id. Please enter your registered email address."])
                     {
                         Alertstatus = @"L'adresse e-mail saisie n'est pas un identifiant utilisateur valide. Entrez votre adresse e-mail enregistrée.";
                     }
                     else if ([Alertstatus isEqual:@"A new pin has been sent to your email. Please check email for further instructions."])
                     {
                         Alertstatus = @"Une nouvelle épingle a été envoyée à votre email. Veuillez vérifier le courrier électronique pour plus d'instructions.";
                     }
                 }
                 
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                 [alert show];
                 return;
             }
         }
         
              failure:^(AFHTTPRequestOperation *operation, NSError *error)
        {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
                 
            NSString *strErrorMsg = NSLocalizedString(@"error", Nil);
            NSString *strOk = NSLocalizedString(@"OK", Nil);
            
            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strErrorMsg delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
            [alert show];
              }];
    }
}
@end
