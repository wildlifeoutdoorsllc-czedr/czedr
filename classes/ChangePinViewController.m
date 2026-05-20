//
//  ChangePinViewController.m
//  payooxe
//
//  Created by Mind Roots New on 29/05/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import "ChangePinViewController.h"
#import "CzedrAppChrome.h"
#import "CzedrTheme.h"
#import "UIViewController+MMDrawerController.h"
#import "SharedServiceController.h"
@interface ChangePinViewController ()

@end

@implementation ChangePinViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *strChangeS3Pin = NSLocalizedString(@"CHANGE CZEDR PIN", Nil);
    changeS3Pin.text = strChangeS3Pin;
    
    NSString *strOldPin = NSLocalizedString(@"ENTER OLD PIN", Nil);
    oldPin.text = strOldPin;
    
    NSString *strNewPin = NSLocalizedString(@"ENTER NEW PIN", Nil);
    newPin.text = strNewPin;
    
    NSString *strConfirmPin = NSLocalizedString(@"CONFIRM YOUR PIN", Nil);
    confirmPin.text = strConfirmPin;

    NSString *strChangePin = NSLocalizedString(@"Change Pin", Nil);
    [changePin setTitle: strChangePin forState: UIControlStateNormal];
}

-(void)viewWillAppear:(BOOL)animated
{
    [CzedrAppChrome refreshSessionBarForViewController:self];
    _pin1.layer.cornerRadius=3;
    _pin1.clipsToBounds = YES;
    _pin2.layer.cornerRadius=3;
    _pin2.clipsToBounds = YES;
    _pin3.layer.cornerRadius=3;
    _pin3.clipsToBounds = YES;
    _pin4.layer.cornerRadius=3;
    _pin4.clipsToBounds = YES;
    
    _pin5.layer.cornerRadius=3;
    _pin5.clipsToBounds = YES;
    _pin6.layer.cornerRadius=3;
    _pin6.clipsToBounds = YES;
    _pin7.layer.cornerRadius=3;
    _pin7.clipsToBounds = YES;
    _pin8.layer.cornerRadius=3;
    _pin8.clipsToBounds = YES;
    _pin9.layer.cornerRadius=3;
    _pin9.clipsToBounds = YES;
    _pin10.layer.cornerRadius=3;
    _pin11.clipsToBounds = YES;
    _pin12.layer.cornerRadius=3;
    _pin12.clipsToBounds = YES;
    [CzedrTheme applyLoggedInDarkScreenToView:self.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField==_pin5)
    {
        [UIView animateWithDuration:0.3f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -80, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    else if (textField==_pin9)
    {
        [UIView animateWithDuration:0.3f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -190, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    if (textField == _pin1)
    {
        [_pin2 becomeFirstResponder];
    }
    else if (textField == _pin2)
    {
        [_pin3 becomeFirstResponder];
    }
    else if (textField == _pin3)
    {
        [_pin4 becomeFirstResponder];
    }
    if (textField == _pin4)
    {
        [_pin5 becomeFirstResponder];
    }
    else if (textField == _pin5)
    {
        [_pin6 becomeFirstResponder];
    }
    else if (textField == _pin6)
    {
        [_pin7 becomeFirstResponder];
    }
    if (textField == _pin7)
    {
        [_pin8 becomeFirstResponder];
    }
    else if (textField == _pin8)
    {
        [_pin9 becomeFirstResponder];
    }
    else if (textField == _pin9)
    {
        [_pin10 becomeFirstResponder];
    }
    return NO;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
}

- (BOOL) textView: (UITextView*) textView shouldChangeTextInRange: (NSRange) range
  replacementText: (NSString *) text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        [UIView animateWithDuration:0.3f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
        return NO;
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
        if (string.length > 0 && ![[NSScanner scannerWithString:string] scanInt:NULL])
            return NO;
        
        NSUInteger oldLength = [textField.text length];
        NSUInteger replacementLength = [string length];
        NSUInteger rangeLength = range.length;
        
        NSUInteger newLength = oldLength - rangeLength + replacementLength;
        
        // This 'tabs' to next field when entering digits
        if (newLength == 1) {
            if (textField == _pin1)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin2 afterDelay:0];
            }
            else if (textField == _pin2)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin3 afterDelay:0];
            }
            else if (textField == _pin3)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin4 afterDelay:0];
            }
            else if (textField == _pin4)
            {
                 [self performSelector:@selector(setNextResponder:) withObject:_pin5 afterDelay:1];
            }
            else if (textField == _pin5)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin6 afterDelay:0];
            }
            else if (textField == _pin6)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin7 afterDelay:0];
            }
            else if (textField == _pin7)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin8 afterDelay:0];
            }
            else if (textField == _pin8)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin9 afterDelay:0];
            }
            else if (textField == _pin9)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin10 afterDelay:0];
            }
            else if (textField == _pin10)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin11 afterDelay:0];
            }
            else if (textField == _pin11)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin12 afterDelay:0];
            }
            else if (textField == _pin12)
            {
                [self performSelector:@selector(setNextResponderfor4:) withObject:_pin12 afterDelay:0];
            }
        }
        //this goes to previous field as you backspace through them, so you don't have to tap into them individually
        else if (oldLength > 0 && newLength == 0) {
            if (textField == _pin12)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin11 afterDelay:0];
            }
            else if (textField == _pin11)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin10 afterDelay:0];
            }
            else if (textField == _pin10)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin9 afterDelay:0];
            }
            if (textField == _pin9)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin8 afterDelay:0];
            }
            else if (textField == _pin8)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin7 afterDelay:0];
            }
            else if (textField == _pin7)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin6 afterDelay:0];
            }
            if (textField == _pin6)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin5 afterDelay:0];
            }
            else if (textField == _pin5)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin4 afterDelay:0];
            }
            else if (textField == _pin4)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin3 afterDelay:0];
            }
            else if (textField == _pin3)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin2 afterDelay:0];
            }
            else if (textField == _pin2)
            {
                [self performSelector:@selector(setNextResponder:) withObject:_pin1 afterDelay:0];
            }
        }
        
        return newLength <= 1;
    
}
- (void)setNextResponder:(UITextField *)nextResponder
{
    if (nextResponder==_pin5)
    {
    if (_pin1.text.length==0||_pin2.text.length==0||_pin3.text.length==0)
    {
        NSString *str = NSLocalizedString(@"enter all Pin values", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        oldString=[NSString stringWithFormat:@"%@%@%@%@",_pin1.text,_pin2.text,_pin3.text,_pin4.text];
        [self check_pinAvalibilty];
    }
       
    }
    else
    {
       [nextResponder becomeFirstResponder];
    }
}
- (void)setNextResponderfor4:(UITextField *)nextResponder
{
    [_pin12 resignFirstResponder];
    [UIView animateWithDuration:0.2f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
}

-(IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)changepib_click:(id)sender
{
    [UIView animateWithDuration:0.2f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    if (oldString.length==0)
    {
        NSString *str = NSLocalizedString(@"enter old Pin values", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
     if (_pin5.text.length==0||_pin6.text.length==0||_pin7.text.length==0||_pin8.text.length==0)
    {
        NSString *str = NSLocalizedString(@"enter all Pin values", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if (_pin9.text.length==0||_pin10.text.length==0||_pin11.text.length==0||_pin12.text.length==0)
    {
        NSString *str = NSLocalizedString(@"enter all Pin values", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    NewPassString=[NSString stringWithFormat:@"%@%@%@%@",_pin5.text,_pin6.text,_pin7.text,_pin8.text];
    NSString *ConfirmPassString=[NSString stringWithFormat:@"%@%@%@%@",_pin9.text,_pin10.text,_pin11.text,_pin12.text];
    if ([NewPassString isEqualToString:ConfirmPassString])
    {
        [self change_pin];
    }
    else
    {
        NSString *str = NSLocalizedString(@"values are not confirmed", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }

}
-(void)check_pinAvalibilty
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
            [SharedServiceController verifyPinSecure:oldString
                                             success:^(NSDictionary *data) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [_pin5 becomeFirstResponder];
            } failure:^(NSString *message) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [_pin1 becomeFirstResponder];
                _pin1.text = @"";
                _pin2.text = @"";
                _pin3.text = @"";
                _pin4.text = @"";
                [alert show];
            }];
            return;
        }

        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
         NSString* authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:oldString forKey:@"user_pin"];
       
        
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"checkpin"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 [_pin5 becomeFirstResponder];
             }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([Alertstatus isEqual:@"The enter PIN number is not correct."])
                     {
                         Alertstatus = @"Le numéro PIN d'entrée est incorrect.";
                     }
                     else if ([Alertstatus isEqual:@"userpin matched"])
                     {
                         Alertstatus = @"Userpin apparié";
                     }
                 }
                 
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                 [_pin1 becomeFirstResponder];
                 _pin1.text=@"";
                 _pin2.text=@"";
                 _pin3.text=@"";
                 _pin4.text=@"";
                 
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

-(void)change_pin
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
    else
    {
        if ([SharedServiceController usesV1API]) {
            [SharedServiceController updatePinSecureOldPin:oldString
                                                    newPin:NewPassString
                                                   success:^(NSDictionary *data) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self.navigationController popViewControllerAnimated:YES];
            } failure:^(NSString *message) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }];
            return;
        }

        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        NSString *authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:NewPassString forKey:@"user_pin"];
      
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"updatepin"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 [self.navigationController popViewControllerAnimated:YES];
             }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
//                 NSLog(@"%@",Alertstatus);
                 
//                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
//                 
//                 if([language isEqual:@"fr"])
//                 {
//                     if ([Alertstatus isEqual:@"Please enter a valid password and try again."])
//                     {
//                         Alertstatus = @"Entrez un mot de passe valide et réessayez.";
//                     }
//                 }
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
