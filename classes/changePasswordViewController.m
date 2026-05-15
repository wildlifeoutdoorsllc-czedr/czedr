//
//  changePasswordViewController.m
//  payooxe
//
//  Created by Mind Roots New on 30/05/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import "changePasswordViewController.h"
#include "SharedServiceController.h"
@interface changePasswordViewController ()

@end

@implementation changePasswordViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *strConfirmNewLbl = NSLocalizedString(@"Change Password", Nil);
    titleLbl.text = [strConfirmNewLbl uppercaseString];
    
    NSString *strOldpassword = NSLocalizedString(@"Enter old password", Nil);
    oldpassword.placeholder = strOldpassword;
    
    NSString *strConfirmpassword = NSLocalizedString(@"Enter confirm password", Nil);
    confirmpassword.placeholder = strConfirmpassword;
    
    NSString *strNewpassword = NSLocalizedString(@"Enter new password", Nil);
    newpassword.placeholder = strNewpassword;
    
    NSString *strUpdatePwd = NSLocalizedString(@"Update Password", Nil);
    [updatePwd setTitle: strUpdatePwd forState: UIControlStateNormal];
    updatePwd.titleLabel.adjustsFontSizeToFitWidth = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [oldpassword setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [newpassword setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [confirmpassword setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)changepasswordClick:(id)sender
{
    [UIView animateWithDuration:0.3f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    
    [confirmpassword resignFirstResponder];
    if (oldpassword.text.length==0)
    {
        NSString *str = NSLocalizedString(@"enter old password", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if (newpassword.text.length==0)
    {
        NSString *str = NSLocalizedString(@"enter new password", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if (confirmpassword.text.length==0)
    {
        NSString *str = NSLocalizedString(@"enter confirmed password", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if (![confirmpassword.text isEqualToString:newpassword.text])
    {
        NSString *str = NSLocalizedString(@"Password not confirmed", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else
    {
            NSString *rawString = [oldpassword text];
            NSString *rawString2 = [newpassword text];
            NSString *rawString3 = [confirmpassword text];
            NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
            NSString *trimmed2 = [rawString2 stringByTrimmingCharactersInSet:whitespace];
            NSString *trimmed3 = [rawString3 stringByTrimmingCharactersInSet:whitespace];
            if ([trimmed length] == 0 || [trimmed2 length] == 0|| [trimmed3 length] == 0)
            {
                NSString *strAttention = NSLocalizedString(@"Attention", Nil);
                NSString *strCorrectValues = NSLocalizedString(@"correct values", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strAttention message:strCorrectValues delegate:nil cancelButtonTitle:strOk otherButtonTitles: nil];
                [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
            }
            else
            {
                [self changepasswordService];
            }
        }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField==oldpassword)
    {
    }
   else if (textField==newpassword)
   {
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -30, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
   else if (textField==confirmpassword)
   {
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0, -60, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField==oldpassword)
    {
        [newpassword becomeFirstResponder];
    }
    if (textField==newpassword)
    {
         [confirmpassword becomeFirstResponder];
    }
    if (textField==confirmpassword)
    {
        [UIView animateWithDuration:0.5f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                  self.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
                              } completion:nil];
        [confirmpassword resignFirstResponder];
    }
    return YES;
}

-(void)changepasswordService
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
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] forKey:@"auth_code"];
        [params setValue:oldpassword.text forKey:@"user_pwd"];
        [params setValue:newpassword.text forKey:@"new_pwd"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"changepwd"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
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
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([Alertstatus isEqual:@"The entered old password does not match the existing password."])
                     {
                         Alertstatus = @"L'ancien mot de passe saisi ne correspond pas au mot de passe existant.";
                     }
                     else if ([Alertstatus isEqual:@"Password Changed"])
                     {
                         Alertstatus = @"Mot de passe changé";
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
@end
