//
//  GeneratePinViewController.m
//  payooxe
//
//  Created by Mind Roots New on 29/05/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import "GeneratePinViewController.h"
#import "CzedrTheme.h"
#import "SharedServiceController.h"
#import "CzedrAppChrome.h"
#import "leftSwipeViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "AppDelegate.h"
@interface GeneratePinViewController () <UITextFieldDelegate>

@end

@implementation GeneratePinViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem *dons=[[UIBarButtonItem alloc]init];
    dons.style=UIBarButtonItemStylePlain;
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStylePlain target:self  action:@selector(doneClicked:)];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:dons,flexBarButton,doneButton, nil]];
      _pin1.inputAccessoryView = keyboardDoneButtonView;
      _pin2.inputAccessoryView = keyboardDoneButtonView;
      _pin3.inputAccessoryView = keyboardDoneButtonView;
      _pin4.inputAccessoryView = keyboardDoneButtonView;
      _pin5.inputAccessoryView = keyboardDoneButtonView;
      _pin6.inputAccessoryView = keyboardDoneButtonView;
      _pin7.inputAccessoryView = keyboardDoneButtonView;
      _pin8.inputAccessoryView = keyboardDoneButtonView;
    
    
    NSString *strTitleLbl = NSLocalizedString(@"GENRATE NEW PIN", Nil);
    _titleLbl.text = strTitleLbl;
    
    NSString *strFillOut = NSLocalizedString(@"ENTER NEW CZEDR PIN", Nil);
    _enterNewLbl.text = strFillOut;
    
    NSString *strConfirmNewLbl = NSLocalizedString(@"CONFIRM YOUR CZEDR PIN", Nil);
    _confirmNewLbl.text = strConfirmNewLbl;
    
    NSString *strGenerate = NSLocalizedString(@"GENRATE NEW PIN", Nil);
    [_generateBtn setTitle:[strGenerate capitalizedString]forState: UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)doneClicked:(id)sender
{
    [self.view endEditing:YES];
    [UIView commitAnimations];
    self.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
}

-(void)viewWillAppear:(BOOL)animated
{
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
    [CzedrTheme applyLoggedInDarkScreenToView:self.view];
    [CzedrAppChrome refreshSessionBarForDrawer:self.mm_drawerController];
}

-(IBAction)save_click:(id)sender
{
    if (_pin1.text.length==0||_pin2.text.length==0||_pin3.text.length==0||_pin4.text.length==0)
    {
        NSString *str = NSLocalizedString(@"enter all Pin values", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if (_pin5.text.length==0||_pin6.text.length==0||_pin7.text.length==0||_pin8.text.length==0)
    {
        NSString *str = NSLocalizedString(@"enter all Pin values", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    NewPassString=[NSString stringWithFormat:@"%@%@%@%@",_pin1.text,_pin2.text,_pin3.text,_pin4.text];
    NSString *ConfirmPassString=[NSString stringWithFormat:@"%@%@%@%@",_pin5.text,_pin6.text,_pin7.text,_pin8.text];
    if ([NewPassString isEqualToString:ConfirmPassString])
    {
      [self call_savepinService];
    }
    else{
        NSString *str = NSLocalizedString(@"values are not confirmed", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
}

-(IBAction)backclick:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [UIView animateWithDuration:0.3f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, -80, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
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
  replacementText: (NSString*) text
{
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        [UIView animateWithDuration:0.5f
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
    
    //This 'tabs' to next field when entering digits
    if (newLength == 1)
    {
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
            [self performSelector:@selector(setNextResponder:) withObject:_pin5 afterDelay:0];
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
            [self performSelector:@selector(setNextResponderfor4:) withObject:_pin8 afterDelay:0];
        }
    }
    //this goes to previous field as you backspace through them, so you don't have to tap into them individually
    else if (oldLength > 0 && newLength == 0)
    {
        if(textField == _pin8)
        {
            [self performSelector:@selector(setNextResponder:) withObject:_pin7 afterDelay:0];
        }
        else if(textField == _pin7)
        {
            [self performSelector:@selector(setNextResponder:) withObject:_pin6 afterDelay:0];
        }
        if(textField == _pin6)
        {
            [self performSelector:@selector(setNextResponder:) withObject:_pin5 afterDelay:0];
        }
        else if(textField == _pin5)
        {
            [self performSelector:@selector(setNextResponder:) withObject:_pin4 afterDelay:0];
        }
        else if(textField == _pin4)
        {
            [self performSelector:@selector(setNextResponder:) withObject:_pin3 afterDelay:0];
        }
        else if(textField == _pin3)
        {
            [self performSelector:@selector(setNextResponder:) withObject:_pin2 afterDelay:0];
        }
        else if(textField == _pin2)
        {
            [self performSelector:@selector(setNextResponder:) withObject:_pin1 afterDelay:0];
        }
    }
    return newLength <= 1;
}

- (void)setNextResponder:(UITextField *)nextResponder
{
    [nextResponder becomeFirstResponder];
}

- (void)setNextResponderfor4:(UITextField *)nextResponder
{
    [_pin8 resignFirstResponder];
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
                          } completion:nil];
}

-(void)call_savepinService
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int reach = [reachAbilty updateInterfaceWithReachability];
    if (reach==0)
    {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else
    {
        if ([SharedServiceController usesV1API]) {
            [SharedServiceController setPinSecure:NewPassString
                                          success:^(NSDictionary *data) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                NSMutableDictionary *stored = [[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] mutableCopy];
                if ([stored isKindOfClass:[NSMutableDictionary class]] || [stored isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *updated = [stored mutableCopy];
                    [updated setObject:@"1" forKey:@"user_pin"];
                    [[NSUserDefaults standardUserDefaults] setValue:updated forKey:@"userDataArray"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                [self navigateToHomeAfterPin];
            } failure:^(NSString *message) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if ([message rangeOfString:@"PIN already set" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    NSMutableDictionary *stored = [[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] mutableCopy];
                    if ([stored isKindOfClass:[NSDictionary class]]) {
                        NSMutableDictionary *updated = [stored mutableCopy];
                        [updated setObject:@"1" forKey:@"user_pin"];
                        [[NSUserDefaults standardUserDefaults] setValue:updated forKey:@"userDataArray"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    [self navigateToHomeAfterPin];
                    return;
                }
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }];
            return;
        }

        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] forKey:@"auth_code"];
        [params setValue:NewPassString forKey:@"user_pin"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"userpin"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 [self navigateToHomeAfterPin];
             }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([Alertstatus isEqual:@"Data is missing"])
                     {
                         Alertstatus = @"Données manquantes";
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

- (void)navigateToHomeAfterPin
{
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    NSMutableDictionary *stored = [[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] mutableCopy];
    if ([stored isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *updated = [stored mutableCopy];
        [updated setObject:@"1" forKey:@"user_pin"];
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if ([app isKindOfClass:[AppDelegate class]]) {
            [app handleLoginSuccessWithPayload:updated];
        }
    }
}

@end
