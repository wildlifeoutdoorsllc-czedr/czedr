//
//  creditNewInvoiceViewController.m
//  payoox
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
#import "creditNewInvoiceViewController.h"
#import "SharedServiceController.h"
@interface creditNewInvoiceViewController ()
@end
@implementation creditNewInvoiceViewController
-(void)viewWillDisappear:(BOOL)animated{
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"validID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)viewDidLoad {
    [super viewDidLoad];
     array=[[NSMutableArray alloc]initWithObjects:@"card Type: *** ***321",@"card Type: *** ***322",@"card Type: *** ***323",@"card Type: *** ***324",@"card Type: *** ***325",@"card Type :*** ***326",@"card Type :*** ***327",nil];
    table.hidden=YES;
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem * dons=[[UIBarButtonItem alloc]init];
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
    _czedrId.inputAccessoryView = keyboardDoneButtonView;
    _amount.inputAccessoryView = keyboardDoneButtonView;
   
    NSString *strTitleLbl = NSLocalizedString(@"CREATE NEW INVOICE", Nil);
    _titleLbl.text = strTitleLbl;
    
    strCzedrRecipientPlaceholder = NSLocalizedString(@"Recipient ID", Nil);
    _czedrId.text = strCzedrRecipientPlaceholder;

    strAmount = NSLocalizedString(@"Enter amount", Nil);
    _amount.text = strAmount;

    NSString *strEnterPin = NSLocalizedString(@"ENTER YOUR PIN", Nil);
    _enterPin.text = strEnterPin;

    NSString *strValidateBtn = NSLocalizedString(@"VALIDATE", Nil);
    [_validateButton setTitle: strValidateBtn forState: UIControlStateNormal];
    _validateButton.titleLabel.adjustsFontSizeToFitWidth = YES;

     NSString *strSndInvoiceBtn = NSLocalizedString(@"SEND INVOICE", Nil);
    [_sendInvoiceBtn setTitle: strSndInvoiceBtn forState: UIControlStateNormal];
//    _sendInvoice.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (IBAction)doneClicked:(id)sender
{
    [self.view endEditing:YES];
    [UIView commitAnimations];
    self.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated
{
    NSString *strMakePayment = NSLocalizedString(@"Enter Description", Nil);
    [_makePayment setPlaceholderText:strMakePayment];
//  [_makePayment setPlaceholderText:@"Enter Description"];
//  [_makePayment setTextColor:[UIColor whiteColor]];
    _scrollView.contentSize=CGSizeMake(320, 568);
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
    [_czedrId setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_amount setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
  }

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField==_czedrId)
    {
        _czedrId.text = @"";
    }
    else if (textField==_amount) {
        _amount.text=@"";
        [UIView animateWithDuration:0.3f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.view.frame = CGRectMake(0, -60, self.view.frame.size.width, self.view.frame.size.height);
        } completion:nil];
    }
    else
    {
        [UIView animateWithDuration:0.3f
                              delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.view.frame = CGRectMake(0, -150, self.view.frame.size.width, self.view.frame.size.height);
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
    if (textField==_czedrId)
    {
        [_czedrId resignFirstResponder];
    }
    return NO;
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

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
}

- (BOOL) textView: (UITextView *) textView shouldChangeTextInRange: (NSRange) range
  replacementText: (NSString *) text
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
    if (textField== _czedrId||textField==_amount)
    {
        return YES;
    }
    else{
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
        else if (oldLength > 0 && newLength == 0) {
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

- (IBAction)sendInvoice:(id)sender
{
    [UIView animateWithDuration:0.3f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    if ([_czedrId.text length]==0) {
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
        
            if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"validID"] isEqualToString:@"ok"])
            {
                pinstring=[NSString stringWithFormat:@"%@%@%@%@",_pin1.text,_pin2.text,_pin3.text,_pin4.text];
                
                if (![_pin4.text isEqual: @""])
                {
                    [self createNewInvoice_serice];
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

- (IBAction)backButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    cell.backgroundColor = [UIColor colorWithRed: 67.0/255 green: 84.0/255 blue: 154.0/255 alpha: 1.0];
    cell.textColor=[UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = [array objectAtIndex:indexPath.row];
    return cell;
}

- (IBAction)select_Payment:(id)sender
{
    [_selectpayment resignFirstResponder];
    int tag=(int)_selectpayment.tag;
    if (tag==0)
    {
        table.hidden = NO;
        _selectpayment.tag=1;
    }
    else
    {
        _selectpayment.tag=0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    values = [array objectAtIndex:indexPath.row];
    _valueLabel.text=values;
    table.hidden=YES;
    _selectpayment.tag=0;
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
           // [[NSUserDefaults standardUserDefaults] setValue:[[response JSONValue] valueForKey:@"Data"] forKey:@"userDataArray"];
           
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
    else if ([SharedServiceController usesV1API])
    {
        [SharedServiceController validateCzedrRecipient:_czedrId.text
            success:^(NSString *displayName) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [[NSUserDefaults standardUserDefaults] setValue:@"ok" forKey:@"validID"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                czedrRecipientIdSave = _czedrId.text;
                _czedrId.text = displayName;
            }
            failure:^(NSString *message) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }];
    }
    else
    {
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
                 [[NSUserDefaults standardUserDefaults] setValue:@"ok" forKey:@"validID"];
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

-(void)createNewInvoice_serice
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
    else if ([SharedServiceController usesV1API])
    {
        NSString *someString = amtStrWithFormatter;
        [SharedServiceController createInvoiceToCzedrId:czedrRecipientIdSave
            amount:someString
            description:_makePayment.text
                pin:pinstring
            success:^(NSDictionary *data) {
                _pin1.text = @"";
                _pin2.text = @"";
                _pin3.text = @"";
                _pin4.text = @"";
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                _makePayment.text = @"";
                _amount.text = @"";
                _czedrId.text = @"";
                [[NSUserDefaults standardUserDefaults] setValue:@"sentcancel" forKey:@"cancel"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"validID"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                NSString *strSuccess = NSLocalizedString(@"Success", Nil);
                NSString *str = NSLocalizedString(@"invoice has been created", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strSuccess message:str delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                [alert show];
            }
            failure:^(NSString *message) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }];
    }
    else
    {
        NSString *someString = amtStrWithFormatter;
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] forKey:@"auth_code"];
        [params setValue:someString forKey:@"amount"];
        [params setValue:_makePayment.text forKey:@"desc"];
        [params setValue:pinstring forKey:@"user_pin"];
        [params setValue:czedrRecipientIdSave forKey:@"rec_czedr_id"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"invoice"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             _pin1.text=@"";
             _pin2.text=@"";
             _pin3.text=@"";
             _pin4.text=@"";

             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 message=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] valueForKey:@"msg"] objectAtIndex:0]];
                 objid=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] valueForKey:@"objid"] objectAtIndex:0]];
                 check_type=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] valueForKey:@"type"] objectAtIndex:0]];
                 _makePayment.text=@"";
                 _amount.text=@"";
                 _czedrId.text=@"";
                 [[NSUserDefaults standardUserDefaults] setValue:@"sentcancel" forKey:@"cancel"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"validID"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 
                 NSString *strSuccess = NSLocalizedString(@"Success", Nil);
                 NSString *str = NSLocalizedString(@"invoice has been created", Nil);
                 NSString *strOk = NSLocalizedString(@"OK", Nil);

                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:strSuccess message:str delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.navigationController popViewControllerAnimated:YES];
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
        if ([objid isEqualToString:@""]) {
            
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
             
         }
        failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             [MBProgressHUD hideHUDForView:self.view animated:YES];
            
             NSString *strErrorMsg = NSLocalizedString(@"error", Nil);
             NSString *strOk = NSLocalizedString(@"OK", Nil);
             
             UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strErrorMsg delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
             [alert show];         }];
    }
    }
    
}
@end
