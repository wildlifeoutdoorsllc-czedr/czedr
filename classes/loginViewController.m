//
//  loginViewController.m
//  Czedr
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import "loginViewController.h"
#import "CzedrTheme.h"
#import "ViewController.h"
#import "leftSwipeViewController.h"
#import "SharedServiceController.h"
@interface loginViewController ()
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation loginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *strNewUser = NSLocalizedString(@"Register new account", Nil);
    _lblNewUser.text = strNewUser;
    
    NSString *strFillOut = NSLocalizedString(@"Fill", Nil);
    _lblFillOut.text = strFillOut;
    
    NSString *strname = NSLocalizedString(@"name", Nil);
    _name.placeholder = strname;
    
    NSString *strEmail = NSLocalizedString(@"email address", Nil);
    _emailAddress.placeholder = strEmail;
    
    NSString *strPwd = NSLocalizedString(@"password", Nil);
    _password.placeholder = strPwd;
    
    NSString *strConfirmPwd = NSLocalizedString(@"confirm password", Nil);
    _confirmPassword.placeholder = strConfirmPwd;
    
    NSString *strMblNumbr = NSLocalizedString(@"mobile number", Nil);
    _mobileNumber.placeholder = strMblNumbr;
    
    NSString *strSignUp = NSLocalizedString(@"CREATE ACCOUNT", Nil);
    [_signUp setTitle:strSignUp forState:UIControlStateNormal];
    
    NSString *strCnclBtn = NSLocalizedString(@"Back to sign in", Nil);
    [_cancelButton setTitle:strCnclBtn forState:UIControlStateNormal];
    _cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    _scrollView.contentSize=CGSizeMake(_scrollView.frame.size.width,_scrollView.frame.size.height+40);
    _viewDetail.layer.cornerRadius =10;
    _viewDetail.clipsToBounds = YES;
    _emailAddress.layer.cornerRadius=3;
    _emailAddress.clipsToBounds = YES;
    _password.layer.cornerRadius=3;
    _password.clipsToBounds = YES;
    _name.layer.cornerRadius=3;
    _name.clipsToBounds = YES;
    _mobileNumber.layer.cornerRadius=3;
    _mobileNumber.clipsToBounds = YES;
    _confirmPassword.layer.cornerRadius=3;
    _confirmPassword.clipsToBounds = YES;
    
    _signUp.layer.cornerRadius=3;
    _signUp.clipsToBounds=YES;
    _cancelButton.layer.cornerRadius=3;
    _cancelButton.clipsToBounds=YES;
    UIColor *placeholderColor = [UIColor whiteColor];
    [CzedrTheme applyPlaceholderAppearanceToTextField:_emailAddress color:placeholderColor font:nil];
    [CzedrTheme applyPlaceholderAppearanceToTextField:_password color:placeholderColor font:nil];
    [CzedrTheme applyPlaceholderAppearanceToTextField:_name color:placeholderColor font:nil];
    [CzedrTheme applyPlaceholderAppearanceToTextField:_mobileNumber color:placeholderColor font:nil];
    [CzedrTheme applyPlaceholderAppearanceToTextField:_confirmPassword color:placeholderColor font:nil];
    [CzedrTheme styleEmailField:_emailAddress];
    [CzedrTheme stylePasswordField:_password];
    [CzedrTheme stylePasswordField:_confirmPassword];
    _scrollView.backgroundColor = [UIColor clearColor];
    [CzedrTheme applyAuthDarkScreen:self.view detailPanel:_viewDetail logoView:nil];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField==_name)
    {
        [_emailAddress becomeFirstResponder];
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -40, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    else if (textField==_emailAddress)
    {
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -85, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    else if (textField==_password) {
       
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -135, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    else if (textField==_confirmPassword) {
        
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -185, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    else if (textField==_mobileNumber) {
        [ _mobileNumber setKeyboardType:UIKeyboardTypeNumberPad];
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -200, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField==_name)
    {
        [_emailAddress becomeFirstResponder];
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -100, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
     if (textField==_emailAddress)
     {
        [_password becomeFirstResponder];
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -135, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    else if (textField==_password) {
        [_confirmPassword becomeFirstResponder];
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -150, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    else if (textField==_confirmPassword)
    {
        [_mobileNumber becomeFirstResponder];
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -200, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    else if (textField==_mobileNumber)
    {
        [textField resignFirstResponder];
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    //Dispose of any resources that can be recreated.
}

-(IBAction)SignUpButton:(id)sender
{
     [_name resignFirstResponder];
     [_emailAddress resignFirstResponder];
     [_password resignFirstResponder];
     [_confirmPassword resignFirstResponder];
     [_mobileNumber resignFirstResponder];
    
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    
    if (_name.text.length==0)
    {
        NSString *str = NSLocalizedString(@"Name is required", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
   else if (_emailAddress.text.length==0)
   {
        NSString *str = NSLocalizedString(@"Email address is required", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
   else if([_emailAddress.text length] > 0 )
   {
       if (_emailAddress.text.length > 0 && ![CzedrTheme isValidEmailAddress:_emailAddress.text])
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
    if (_password.text.length==0)
   {
       NSString *str = NSLocalizedString(@"Password is required", Nil);
       NSString *strOk = NSLocalizedString(@"OK", Nil);

       UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
       [alert show];
       return;
   }
   else if (_confirmPassword.text.length==0)
   {
       NSString *str = NSLocalizedString(@"Confirm password is required", Nil);
       NSString *strOk = NSLocalizedString(@"OK", Nil);

       UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
       [alert show];
       return;
   }
   else if (![_confirmPassword.text isEqualToString:_password.text])
   {
       UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:@"password not Confirmed!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       [alert show];
       return;
   }
   else if (_mobileNumber.text.length==0)
   {
       NSString *str = NSLocalizedString(@"Mobile number is required", Nil);
       NSString *strOk = NSLocalizedString(@"OK", Nil);

       UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
       [alert show];
       return;
   }
   else
   {
       NSString *rawString = [_name text];
       NSString *rawString2 = [_emailAddress text];
       NSString *rawString3 = [_password text];
       NSString *rawString4 = [_confirmPassword text];
       NSString *rawString5 = [_mobileNumber text];
       NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
       NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
       NSString *trimmed2 = [rawString2 stringByTrimmingCharactersInSet:whitespace];
       NSString *trimmed3 = [rawString3 stringByTrimmingCharactersInSet:whitespace];
       NSString *trimmed4 = [rawString4 stringByTrimmingCharactersInSet:whitespace];
       NSString *trimmed5 = [rawString5 stringByTrimmingCharactersInSet:whitespace];
       if ([trimmed length] == 0 || [trimmed2 length] == 0|| [trimmed3 length] == 0|| [trimmed4 length] == 0 || [trimmed5 length] == 0)
       {
           NSString *strAttention = NSLocalizedString(@"Attention", Nil);
           NSString *strCorrectValues = NSLocalizedString(@"correct values", Nil);
           NSString *strOk = NSLocalizedString(@"OK", Nil);
           
           UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strAttention message:strCorrectValues delegate:nil cancelButtonTitle:strOk otherButtonTitles: nil];
           [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
       }
       else
       {
//       leftSwipeViewController *left=[[leftSwipeViewController alloc]initWithNibName:@"leftSwipeViewController" bundle:nil];
//       [self.navigationController pushViewController:left animated:YES];
//       [[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"Avalue"];
//       
//       [[NSUserDefaults standardUserDefaults]synchronize];
           [self call_signupService];
       }
      }
     }
   }
}
-(void)call_signupService
{
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
    else{
     
        if ([SharedServiceController usesV1API]) {
            [SharedServiceController registerSecureWithName:_name.text
                                                    email:_emailAddress.text
                                                 password:_password.text
                                              mobileNumber:_mobileNumber.text
                                                  success:^(NSDictionary *data) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                NSString *str = NSLocalizedString(@"account is pending activation", Nil);
                if ([SharedServiceController usesV1API]) {
                    str = @"Account created. You can sign in now.";
                }
                NSString *strOk = NSLocalizedString(@"OK", Nil);
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                [alert show];
            } failure:^(NSString *message) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }];
            return;
        }

        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:_name.text forKey:@"user_name"];
        [params setValue:_emailAddress.text forKey:@"user_email"];
        [params setValue:_password.text forKey:@"user_pwd"];
        [params setValue:_mobileNumber.text forKey:@"mobile_no"];
         manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"signup"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
              [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             
             if ([status isEqualToString:@"true"])
             {
                 NSString *str = NSLocalizedString(@"account is pending activation", Nil);
                 NSString *strOk = NSLocalizedString(@"OK", Nil);

                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                 [alert show];
            }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([Alertstatus isEqual:@"This email already exists. Please enter another email address or try Forgot password to regenerate the password for your old account."])
                     {
                         Alertstatus = @"Ce courriel existe déjà. Veuillez entrer une autre adresse e-mail ou essayer Mot de passe oublié pour régénérer le mot de passe de votre ancien compte.";
                     }
                     else if ([Alertstatus isEqual:@"Please enter a valid password and try again."])
                     {
                         Alertstatus = @"Entrez un mot de passe valide et réessayez.";
                     }
                     else if ([Alertstatus isEqual:@" An account with the entered email address does not exist."])
                     {
                         Alertstatus = @"Un compte avec l'adresse électronique saisie n'existe pas.";
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
   [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancelButton:(id)sender
{
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
