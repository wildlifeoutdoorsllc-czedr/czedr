//
//  ViewController.m
//  payooxe
//
//  Created by Renu on 01/01/09.
//  Copyright (c) 2009 Renu. All rights reserved.
//

#import "ViewController.h"
#import "forgotViewController.h"
#import "loginViewController.h"
#import "leftSwipeViewController.h"
#import "AppDelegate.h"
#import "SharedServiceController.h"
#import "GeneratePinViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    user_infodata=[[NSMutableArray alloc]init];
    
    NSString *strEmail = NSLocalizedString(@"email address", Nil);
    _email.placeholder = strEmail;
    
    NSString *strPwd = NSLocalizedString(@"password", Nil);
    _password.placeholder = strPwd;
    
    NSString *strLogin = NSLocalizedString(@"LOGIN", Nil);
    [loginbutton setTitle: strLogin forState: UIControlStateNormal];

    NSString *strForgotPwd = NSLocalizedString(@"forgot password?", Nil);
    [forgetbutton setTitle: strForgotPwd forState: UIControlStateNormal];

    NSString *strSignUpNw = NSLocalizedString(@"SIGN UP NOW!", Nil);
    [signupbutton setTitle: strSignUpNw forState: UIControlStateNormal];
}

-(void)viewWillAppear:(BOOL)animated
{
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
    [_email setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_password setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
   loginbutton.titleLabel.font = [UIFont fontWithName:@"AVENIR" size:12.0];
    signupbutton.titleLabel.font = [UIFont fontWithName:@"AVENIR" size:12.0];
    forgetbutton.titleLabel.font = [UIFont fontWithName:@"AVENIR" size:12.0];
    [_email setValue:[UIFont fontWithName: @"AVENIR" size:14.0] forKeyPath:@"_placeholderLabel.font"];
    [_password setValue:[UIFont fontWithName: @"AVENIR" size:14.0] forKeyPath:@"_placeholderLabel.font"];
    _email.font=[UIFont fontWithName:@"AVENIR" size:14.0];
    _password.font=[UIFont fontWithName:@"AVENIR" size:14.0];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == _email)
    {
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -60, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
   else if (textField == _password) {
        
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -120, self.view.frame.size.width, self.view.frame.size.height);
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
    
    if (textField==_email) {
        [_password becomeFirstResponder];
    }
    else{
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
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
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
       NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
       NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
       int checkValue=[emailTest evaluateWithObject:_email.text];
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
               [self call_LoginService];
           }
       }
   }
//    GeneratePinViewController *OBJ=[[GeneratePinViewController alloc]initWithNibName:@"GeneratePinViewController" bundle:nil];
//    [self.navigationController pushViewController:OBJ animated:YES];
}

-(void)call_LoginService
{
    [_email resignFirstResponder];
    [_password resignFirstResponder];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int reach = [reachAbilty updateInterfaceWithReachability];
    if (reach==0){
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else
    {
        if ([SharedServiceController usesV1API]) {
            [SharedServiceController loginSecureWithEmail:_email.text
                                                 password:_password.text
                                                  success:^(NSDictionary *data) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [user_infodata addObject:data];
                NSString *userPin = [NSString stringWithFormat:@"%@", [data valueForKey:@"user_pin"]];
                [self parse_registerService];
                if ([userPin isEqualToString:@"0"]) {
                    GeneratePinViewController *OBJ = [[GeneratePinViewController alloc] initWithNibName:@"GeneratePinViewController" bundle:nil];
                    [self.navigationController pushViewController:OBJ animated:YES];
                } else {
                    leftSwipeViewController *left = [[leftSwipeViewController alloc] initWithNibName:@"leftSwipeViewController" bundle:nil];
                    [self.navigationController pushViewController:left animated:YES];
                }
            } failure:^(NSString *message) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }];
            return;
        }

        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:_email.text forKey:@"user_email"];
        [params setValue:_password.text forKey:@"user_pwd"];
       
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"login"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             
             response = [NSString stringWithFormat:@"%@",operation.responseString];
        
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 NSDictionary *data=[[response JSONValue] valueForKey:@"Data"];
                 [SharedServiceController saveLoginPayload:data];
                 [user_infodata addObject:data];
                 NSString *userPin=[NSString stringWithFormat:@"%@",[data valueForKey:@"user_pin"]];
                 [self parse_registerService];
                 if ([userPin isEqualToString:@"0"])
                 {
                     GeneratePinViewController *OBJ=[[GeneratePinViewController alloc]initWithNibName:@"GeneratePinViewController" bundle:nil];
                     [self.navigationController pushViewController:OBJ animated:YES];
                 }
                 else
                 {
                    leftSwipeViewController *left=[[leftSwipeViewController alloc]initWithNibName:@"leftSwipeViewController" bundle:nil];
                    [self.navigationController pushViewController:left animated:YES];
                 }
             }
             else
             {
                NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([Alertstatus isEqual:@"Please enter a valid password and try again."])
                     {
                        Alertstatus = @"Entrez un mot de passe valide et réessayez.";
                     }
                     else if ([Alertstatus isEqual:@"An account with the entered email address does not exist."])
                     {
                         Alertstatus = @"Un compte avec l'adresse e-mail saisie n'existe pas";
                     }
                     else if ([Alertstatus isEqual:@"Your Account Is not Active."])
                     {
                         Alertstatus = @"Votre compte n'est pas actif.";
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
