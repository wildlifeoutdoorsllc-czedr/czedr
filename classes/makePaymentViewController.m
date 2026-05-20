//
//  makePaymentViewController.m
//  payoox
//
//  Created by Renu on 13/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.

#import "makePaymentViewController.h"
#import "CzedrTheme.h"
#import "UIViewController+MMDrawerController.h"
#import "MMDrawerVisualState.h"
#import "MMDrawerBarButtonItem.h"
#import <QuartzCore/QuartzCore.h>
#import "SharedServiceController.h"
#import "CzedrAppChrome.h"
#import "pendingInvoicesViewController.h"

@implementation makePaymentViewController

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"makevalidID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"make_p"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem *dons = [[UIBarButtonItem alloc]init];
    dons.style = UIBarButtonItemStylePlain;
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStylePlain target:self action:@selector(doneClicked:)];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:dons,flexBarButton,doneButton, nil]];
    _pin1.inputAccessoryView = keyboardDoneButtonView;
    _pin2.inputAccessoryView = keyboardDoneButtonView;
    _pin3.inputAccessoryView = keyboardDoneButtonView;
    _pin4.inputAccessoryView = keyboardDoneButtonView;
    _czedrId.inputAccessoryView = keyboardDoneButtonView;
    _amount.inputAccessoryView = keyboardDoneButtonView;

    NSString *strMkPymntLbl = NSLocalizedString(@"MAKE PAYMENT", Nil);
    _titleLbl.text = strMkPymntLbl;
    
    strCzedrRecipientPlaceholder = NSLocalizedString(@"Recipient ID", Nil);
    _czedrId.text = strCzedrRecipientPlaceholder;
    
    strAmount = NSLocalizedString(@"Enter amount", Nil);
    _amount.text = strAmount;
    
    NSString *strEnterPin = NSLocalizedString(@"ENTER YOUR PIN", Nil);
    _enterPin.text = strEnterPin;
    
    NSString *strValidateBtn = NSLocalizedString(@"VALIDATE", Nil);
    [_validateButton setTitle: strValidateBtn forState: UIControlStateNormal];
    _validateButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    NSString *strMkPymntBtn = NSLocalizedString(@"MAKE PAYMENT", Nil);
    [_mkPymntBtn setTitle: strMkPymntBtn forState: UIControlStateNormal];
    _mkPymntBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)leftDrawerButtonPress:(id)sender
{
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"pmakepaymentclick"] isEqualToString:@"makepayment"]) {
        [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [CzedrAppChrome refreshSessionBarForDrawer:self.mm_drawerController];
    _scroll_view.contentSize=CGSizeMake(320, 568);
    _czedrId.layer.cornerRadius=3;
    _czedrId.clipsToBounds = YES;
    _amount.layer.cornerRadius=3;
    _amount.clipsToBounds = YES;
    _validateButton.layer.cornerRadius=3;
    _validateButton.clipsToBounds = YES;
    _pin1.layer.cornerRadius=3;
    _pin1.clipsToBounds = YES;
    _pin2.layer.cornerRadius=3;
    _pin2.clipsToBounds = YES;
    _pin3.layer.cornerRadius=3;
    _pin3.clipsToBounds = YES;
    _pin4.layer.cornerRadius=3;
    _pin4.clipsToBounds = YES;
    _sendInvoice.layer.cornerRadius=3;
    _sendInvoice.clipsToBounds = YES;
    _enterPin.textColor = [CzedrTheme taglineRed];
    [CzedrTheme applyLoggedInDarkScreenToView:self.view];
    [CzedrTheme styleCzedrIdField:_czedrId];
    
    payNowBool = false;
    
    UIColor *placeholderColor = [UIColor whiteColor];
    [CzedrTheme applyPlaceholderAppearanceToTextField:_czedrId color:placeholderColor font:nil];
    [CzedrTheme applyPlaceholderAppearanceToTextField:_amount color:placeholderColor font:nil];
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"pmakepaymentclick"] isEqualToString:@"makepayment"]) {
        [backbtn setImage:[UIImage imageNamed:@"menu2.png"] forState:UIControlStateNormal];
    }
     _pin4.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _pin3.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
    _pin2.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
    _pin1.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"make_p"] isEqualToString:@"paynow_for"])
    {
         NSString *myCzedrId=[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"];
        _czedrId.text=_paytoId;
        
        NSNumberFormatter *numberFormat = [[NSNumberFormatter alloc] init];
        numberFormat.usesGroupingSeparator = YES;
        numberFormat.groupingSeparator = @",";
        numberFormat.groupingSize = 3;
        numberFormat.roundingMode = NSNumberFormatterRoundUp;
        [numberFormat setDecimalSeparator:@"."];
        [numberFormat setNumberStyle:NSNumberFormatterDecimalStyle];
        [numberFormat setMaximumFractionDigits:2];
        [numberFormat setMinimumFractionDigits:2];
        
        NSString *str = [numberFormat stringFromNumber:[NSNumber numberWithFloat:[[dataArray1 valueForKey:@"amount"] floatValue]]];
        
        NSLocale *theLocale = [NSLocale currentLocale];
        NSString *symbol = [theLocale objectForKey:NSLocaleCurrencySymbol];
        
        _amount.text = [NSString stringWithFormat:@"%@%@",symbol,str];
        
        amtStrWithFormatter = [NSString stringWithFormat:@"%@",[dataArray1 valueForKey:@"amount"]];
        
        _makePayment.text=[dataArray1 valueForKey:@"description"];
        
        payNowBool = true;
        
        [self validate_serice];
    }
    else
    {
        NSString *strMakePayment = NSLocalizedString(@"Enter Description", Nil);
        [_makePayment setPlaceholderText:strMakePayment];
    }
  }

-(void)cancelNumberPad{
    [_amount resignFirstResponder];
    _amount.text = @"";
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_pin4 resignFirstResponder];
    [_pin3 resignFirstResponder];
    [_pin4 resignFirstResponder];
    [_pin4 resignFirstResponder];
}

- (IBAction)backButton:(id)sender
{
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField==_czedrId)
    {
        _czedrId.text = @"";
    }
   else if (textField==_amount)
   {
        _amount.text=@"";
       [UIView animateWithDuration:0.3f
                             delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                 self.view.frame = CGRectMake(0, -20, self.view.frame.size.width, self.view.frame.size.height);
                             } completion:nil];
        
    }
   else
   {
       [UIView animateWithDuration:0.3f
                             delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                                 self.view.frame = CGRectMake(0, -210, self.view.frame.size.width, self.view.frame.size.height);
                             } completion:nil];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField==_czedrId)
    {
        if ([textField.text  isEqual: @""])
        {
            _czedrId.text = strCzedrRecipientPlaceholder;
        }
    }
    else if (textField==_amount)
    {
       if([_amount.text length]==0)
       {
           _amount.text = strAmount;
       }
        else
        {
            amtStrWithFormatter = _amount.text;
            NSNumberFormatter *numberFormat = [[NSNumberFormatter alloc] init];
            numberFormat.usesGroupingSeparator = YES;
            numberFormat.groupingSeparator = @",";
            numberFormat.groupingSize = 3;
            numberFormat.roundingMode = NSNumberFormatterRoundUp;
            [numberFormat setDecimalSeparator:@"."];
            [numberFormat setNumberStyle:NSNumberFormatterDecimalStyle];
            [numberFormat setMaximumFractionDigits:2];
            [numberFormat setMinimumFractionDigits:2];
            
            NSString *str = [numberFormat stringFromNumber:[NSNumber numberWithFloat:[_amount.text floatValue]]];
            
            NSLocale *theLocale = [NSLocale currentLocale];
            NSString *symbol = [theLocale objectForKey:NSLocaleCurrencySymbol];
            
            _amount.text = [NSString stringWithFormat:@"%@%@",symbol,str];
        }
        }
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
    else if (textField == _czedrId)
    {
        [_czedrId resignFirstResponder];
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
    if ([text isEqualToString:@"\n"]) {
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
    if (textField== _czedrId||textField==_amount)
    {
        return YES;
    }
    else
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
            [self performSelector:@selector(setNextResponderfor4:) withObject:_pin5 afterDelay:0];
        }
    }
    //this goes to previous field as you backspace through them, so you don't have to tap into them individually
    else if (oldLength > 0 && newLength == 0)
    {
        if (textField == _pin4)
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
}

- (void)setNextResponder:(UITextField *)nextResponder
{
        [nextResponder becomeFirstResponder];
}

- (void)setNextResponderfor4:(UITextField *)nextResponder
{
     [_pin4 resignFirstResponder];
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
}

- (IBAction)make_Payment:(id)sender
{
    if ([_czedrId.text length]==0){
        NSString *str = NSLocalizedString(@"Please enter Id", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
   else if ([_amount.text length]==0 || [_amount.text isEqualToString:strAmount])
   {
       NSString *str = NSLocalizedString(@"enter valid amount", Nil);
       NSString *strOk = NSLocalizedString(@"OK", Nil);
       
       UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
       [alert show];
       return;
    }
   else if ([_makePayment.text length]==0) {
       NSString *str = NSLocalizedString(@"enter description", Nil);
       NSString *strOk = NSLocalizedString(@"OK", Nil);
       
       UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
       [alert show];
       return;
    }
   else if ([_pin1.text length]==0||[_pin2.text length]==0||[_pin3.text length]==0||[_pin4.text length]==0) {
       NSString *str = NSLocalizedString(@"enter your four digit pin", Nil);
       NSString *strOk = NSLocalizedString(@"OK", Nil);
       
       UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
       [alert show];
       return;
   }
    else
    {
        NSString *rawString = [_czedrId text];
        NSString *rawString2 = [_makePayment text];
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
            if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"makevalidID"] isEqualToString:@"ok"])
            {
                pinstring=[NSString stringWithFormat:@"%@%@%@%@",_pin1.text,_pin2.text,_pin3.text,_pin4.text];
                
                if (![_pin4.text isEqual: @""])
                {
                    [self makepayment_service];
                }
            }
            else
            {
                NSString *str = NSLocalizedString(@"validate your id", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);
                
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                [alert show];
            }
        }
    }
    [UIView animateWithDuration:0.5f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
}

-(void)makepayment_service
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
        if ([SharedServiceController usesV1API]) {
            float dollars = [amtStrWithFormatter floatValue];
            NSInteger cents = (NSInteger)lroundf(dollars * 100.0f);
            [SharedServiceController transferToCzedrId:czedrRecipientIdSave
                                             amountCents:cents
                                                    memo:_makePayment.text ?: @"Payment"
                                                     pin:pinstring
                                                 success:^(NSDictionary *data) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                NSString *str = NSLocalizedString(@"Payment is successful", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);
                NSString *txnId = [data objectForKey:@"id"] ?: @"";
                NSString *message1=[NSString stringWithFormat:@"%@ %@",str,txnId];
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:message1 delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
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
        NSString *authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        
        [params setValue:czedrRecipientIdSave forKey:@"rec_id"];
        [params setValue:values forKey:@"card_id_sender"];
        
       
        if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"make_p"] isEqualToString:@"paynow_for"])
        {
            [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"make_p"];
            [[NSUserDefaults standardUserDefaults] synchronize];
              [params setValue:[dataArray1 valueForKey:@"id"] forKey:@"invoice_id"];
        }
        else
        {
              [params setValue:@"" forKey:@"invoice_id"];
        }
        NSString *someString = amtStrWithFormatter;
        
        [params setValue:someString forKey:@"amount"];
        
        [params setValue:_makePayment.text forKey:@"trans_notes"];
        
        [params setValue:pinstring forKey:@"user_pin"];
        
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"transactiondetail"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             
             if ([status isEqualToString:@"true"])
             {
                 message=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] valueForKey:@"msg"] objectAtIndex:0]];
                 objid=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] valueForKey:@"objid"] objectAtIndex:0]];
                 check_type=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] valueForKey:@"type"] objectAtIndex:0]];
                 [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"makevalidID"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 
                 NSString *str = NSLocalizedString(@"Payment is successful", Nil);
                 NSString *strOk = NSLocalizedString(@"OK", Nil);

                 NSString *message1=[NSString stringWithFormat:@"%@ %@",str,[[[[response JSONValue] valueForKey:@"Data"] valueForKey:@"transaction_id"] objectAtIndex:0]];
                 
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:message1 delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                 [alert show];
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
                     else if([Alertstatus isEqual:@"The entered PIN number is not correct."])
                     {
                         Alertstatus = @"Le code PIN saisi n'est pas correct.";
                     }
                 }
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                 [alert show];
             }
             [MBProgressHUD hideHUDForView:self.view animated:YES];
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

- (IBAction)doneClicked:(id)sender
{
    [self.view endEditing:YES];
    [UIView commitAnimations];
    self.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (payNowBool == true)
    {
       pendingInvoicesViewController *obj=[[pendingInvoicesViewController alloc]initWithNibName:@"pendingInvoicesViewController" bundle:nil];
       [self.navigationController pushViewController:obj animated:YES];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:true];
    }
}

-(IBAction)validate_idclick:(id)sender
{
    if (_czedrId.text.length==0)
    {
        NSString *str = NSLocalizedString(@"Please enter Id", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    else
    {
        NSString *rawString = [_czedrId text];
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
        if ([trimmed length] == 0)
        {
            NSString *strAttention = NSLocalizedString(@"Attention", Nil);
            NSString *strCorrectValues = NSLocalizedString(@"correct values", Nil);
            NSString *strOk = NSLocalizedString(@"OK", Nil);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strAttention message:strCorrectValues delegate:nil cancelButtonTitle:strOk otherButtonTitles: nil];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        }
        else
        {
            if ([[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"]valueForKey:@"email "] isEqualToString:_czedrId.text]||[[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"]valueForKey:@"id"] isEqualToString:_czedrId.text])
            {
                NSString *str = NSLocalizedString(@"Please enter valid id", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);
                
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                [alert show];
                return;
            }
            else
            {
                [self validate_serice];
            }
        }
    }
}

-(void)validate_serice
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
        if ([SharedServiceController usesV1API]) {
            NSString *enteredId = [_czedrId.text copy];
            [SharedServiceController validateCzedrRecipient:enteredId
                success:^(NSString *displayName) {
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    [[NSUserDefaults standardUserDefaults] setValue:@"ok" forKey:@"makevalidID"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    czedrRecipientIdSave = enteredId;
                    _czedrId.text = displayName;
                    if (displayName.length > 0) {
                        NSString *msg = [NSString stringWithFormat:@"Recipient: %@", displayName];
                        UIAlertView *okAlert = [[UIAlertView alloc] initWithTitle:@""
                                                                           message:msg
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
                        [okAlert show];
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
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] forKey:@"auth_code"];
        [params setValue:_czedrId.text forKey:@"rec_czedr_id"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"valid_recipient"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 [[NSUserDefaults standardUserDefaults] setValue:@"ok" forKey:@"makevalidID"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 czedrRecipientIdSave=_czedrId.text;
                 _czedrId.text=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] valueForKey:@"result"] objectAtIndex:0]];
             }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([Alertstatus isEqual:@"Invalid Czedr Id"])
                     {
                         Alertstatus = @"Invalide Czedr Id";
                     }
                     else if ([Alertstatus isEqual:@"Invalid Email"])
                     {
                         Alertstatus = @"Email invalide";
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

-(void)notifiction_service
{
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
       
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:message forKey:@"msg"];
        [params setValue:objid forKey:@"obj_id"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        if ([objid isEqualToString:@""])
        {
            
        }
        else
        {
        if ([check_type isEqualToString:@"android"])
        {
          url=[NSURL URLWithString:@CZEDR_PUSH_NOTIFY_ANDROID];
         }
         else
         {
            url=[NSURL URLWithString:@CZEDR_PUSH_NOTIFY_IOS];
        }
        [manager POST:[NSString stringWithFormat:@"%@",url] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
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
}
@end
