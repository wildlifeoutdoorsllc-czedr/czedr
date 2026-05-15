//
//  addCreditViewController.m
//  payoox
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import "addCreditViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AESCrypt.h"
#import "SharedServiceController.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import <Security/Security.h>
#import "AESCrypt.h"
#import "NSData+Encryption.h"
#import "LinkedViewController.h"
#import "RNEncryptor.h"

@interface addCreditViewController ()
@end

@implementation addCreditViewController 
@synthesize checkBoxButton,myString1;

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    _cardNumber.inputAccessoryView = keyboardDoneButtonView;
    _cvvNumber.inputAccessoryView = keyboardDoneButtonView;
   
    check=NO;
    soureYear = [[NSMutableArray alloc] init];
    NSDate *currentdate=[[NSDate alloc]init];
    NSDateFormatter *dateFormat1 = [[NSDateFormatter alloc] init];
    [dateFormat1 setDateFormat:@"yyyy-MM-dd  HH:mm:ss Z"];
    [dateFormat1 setDateFormat:@"yyyy"];
    NSString * dateNotFormatted1 = [dateFormat1 stringFromDate:currentdate];
   
    for (int i=0; i<30; i++)
    {
       int year= [dateNotFormatted1 intValue]+i;
        NSString *finalyear=[NSString stringWithFormat:@"%d",year];
        [soureYear addObject:finalyear];
    }
    
    soureMonth = [[NSMutableArray alloc] initWithObjects:@"Jan",@"Feb",@"Mar",@"Apl",@"May",@"Jun",@"July",@"Aug",@"Sep",@"Oct",@"Nov",@"Dec", nil];
    checkValueSet=@"0";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    checked1 = [defaults boolForKey:@"box1IsChecked"];
    
    NSString *strName = NSLocalizedString(@"name", Nil);
    _name.placeholder = [strName capitalizedString];
    
    NSString *strCrdNo = NSLocalizedString(@"Card Number", Nil);
    _cardNumber.placeholder = strCrdNo;
    
    NSString *strExpiryDt = NSLocalizedString(@"Expiry Date", Nil);
    [_expiryDate setTitle: strExpiryDt forState: UIControlStateNormal];
    
    NSString *strCVVNo = NSLocalizedString(@"CVV Number", Nil);
    _cvvNumber.placeholder = strCVVNo;
    
    
    NSString *strDefault = NSLocalizedString(@"Set As Default", Nil);
    setAsDefault.text = strDefault;
    
    NSString *strAdd = NSLocalizedString(@"ADD", Nil);
    [addbtn setTitle: strAdd forState: UIControlStateNormal];
    
    NSString *strDelete = NSLocalizedString(@"DELETE", Nil);
    [deletebtn setTitle: strDelete forState: UIControlStateNormal];
    
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"cardInfo"] isEqualToString:@"updtae"])
    {
        NSString *strTitleLbl = NSLocalizedString(@"UPDATE CARD", Nil);
        titleBL.text = strTitleLbl;
        
        [addbtn setTitle:@"UPDATE" forState:UIControlStateNormal];
        deletebtn.hidden=NO;
        _name.text=[addcardArraydata valueForKey:@"name"];
        _cardNumber.text=[NSString stringWithFormat:@"*************%@",[addcardArraydata valueForKey:@"cardnumber"]];
        NSString *expirty=[NSString stringWithFormat:@"**/**"];
        _cvvNumber.text=@"***";
        [_expiryDate setTitle:expirty forState:UIControlStateNormal];
        
        if ([[addcardArraydata valueForKey:@"card_default"] isEqualToString:@"1"])
        {
            checkValueSet=@"1";
            [checkBoxButton setSelected:YES];
            [checkBoxButton setImage:[UIImage imageNamed:@"checkBoxMarked.png"] forState:UIControlStateNormal];
        }
    }
    else
    {
        NSString *strTitleLbl = NSLocalizedString(@"ADD CARD", Nil);
        titleBL.text = strTitleLbl;
        
        deletebtn.hidden=YES;
    }
}

- (IBAction)doneClicked:(id)sender
{
    [self.view endEditing:YES];
    [UIView commitAnimations];
    self.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    if (textField==_cvvNumber)
    {
        if (!string.length)
        {
            return YES;
        }
        if ([_cvvNumber.text length]>2)
        {
            return NO;
        }
    }
    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
     [actionView removeFromSuperview];
     _expiryDate.userInteractionEnabled=YES;
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"cardInfo"] isEqualToString:@"updtae"])
    {
        if (textField==_cardNumber)
        {
            _cardNumber.text=@"";
        }
        if (textField==_cvvNumber)
        {
            _cvvNumber.text=@"";
        }
    }
    else
    {
    }
    if (_cardNumber)
    {
        [_cardNumber setKeyboardType:UIKeyboardTypeNumberPad];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_cardNumber resignFirstResponder];
    [_cvvNumber resignFirstResponder];
    _expiryDate.userInteractionEnabled=YES;
    if (textField==_name)
    {
       [_cardNumber becomeFirstResponder];
    }
    return YES;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(component == 1)
        return [soureYear count];
        else
   return [soureMonth count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if(component == 0)
        return [soureMonth objectAtIndex:row];
        return [soureYear objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (component==1)
    {
        comp=component;
        rowfor=row;
    }
    else
    {
        components=component;
        rowvalue=row;
    }
}

-(void)dateAndTimePicker:(NSInteger)indexPath
{
    [actionView removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewWillDisappear:(BOOL)animated
{
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [_name setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_cvvNumber setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_cardNumber setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
}

- (IBAction)backButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)deletecard:(id)sender
{
    NSString *strDlteCrd = NSLocalizedString(@"delete card", Nil);
    NSString *strYES = NSLocalizedString(@"YES", Nil);
    NSString *strNO = NSLocalizedString(@"NO", Nil);
    
    aler1=[[UIAlertView alloc]initWithTitle:nil message:strDlteCrd delegate:self cancelButtonTitle:strNO otherButtonTitles:strYES, nil];
    aler1.tag=200;
    [aler1 show];
}

- (IBAction)datePicker:(id)sender
{
    actionView.hidden=NO;
    [_name resignFirstResponder];
    [_cardNumber resignFirstResponder];
    [_cvvNumber resignFirstResponder];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        actionView = [[UIView alloc] initWithFrame:CGRectMake(0, 290, self.view.frame.size.width, 350)];
    }
    else  if ([[UIScreen mainScreen] bounds].size.height ==568)
    {
        actionView = [[UIView alloc] initWithFrame:CGRectMake(0,370, self.view.frame.size.width, 350)];
    }
    else  if ([[UIScreen mainScreen] bounds].size.height ==667)
    {
        actionView = [[UIView alloc] initWithFrame:CGRectMake(0, 450, self.view.frame.size.width, 350)];
    }
    else
    {
        actionView = [[UIView alloc] initWithFrame:CGRectMake(0, 500, self.view.frame.size.width, 350)];
    }
    
    datePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 44, actionView.frame.size.width, 162)];
  
    datePicker.backgroundColor=[UIColor whiteColor];
 
    actionView.backgroundColor=[UIColor whiteColor];
   
    UIToolbar *pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width, 44)];
    pickerToolbar.translucent=YES;
    pickerToolbar.barTintColor=[UIColor blackColor];
    NSMutableArray *barItems = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel_clicked:)];
    [cancelBtn setTintColor:[UIColor whiteColor]];
    [barItems addObject:cancelBtn];
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [flexSpace setTintColor:[UIColor whiteColor]];
    [barItems addObject:flexSpace];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(pickerDone:)];
    [doneBtn setTintColor:[UIColor whiteColor]];
    [barItems addObject:doneBtn];
    
    [pickerToolbar setItems:barItems animated:YES];
    
    [actionView addSubview:pickerToolbar];
    datePicker.dataSource=self;
    datePicker.delegate=self;
    [actionView addSubview:datePicker];
    [self.view addSubview:actionView];
   
    _expiryDate.userInteractionEnabled=NO;
}

- (void)pickerDone:(id)sender
{
    [actionView removeFromSuperview];
    _expiryDate.userInteractionEnabled=YES;
    
        if (components==0)
        {
            montString= [soureMonth objectAtIndex:rowvalue];
            components=0;
            rowvalue=0;
            check=YES;
        }

       if (comp==1)
       {
           yearString=  [soureYear objectAtIndex:rowfor];
           rowfor=0;
           comp=0;
        }

        if (check==NO)
        {
            montString= [soureMonth objectAtIndex:rowvalue];
        }
        else
        {
            check=NO;
        }
    if ([yearString length]==0) {
        yearString=  [soureYear objectAtIndex:rowfor];
    }
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM/yyyy"];
    NSDate * dateNotFormatted = [dateFormat dateFromString:[NSString stringWithFormat:@"%@/%@",montString,yearString]];
    [dateFormat setDateFormat:@"M/YY"];
    NSString * dateFormatted = [dateFormat stringFromDate:dateNotFormatted];
  
    NSDate *currentdate=[[NSDate alloc]init];
    NSDateFormatter *dateFormat1 = [[NSDateFormatter alloc] init];
    [dateFormat1 setDateFormat:@"yyyy-MM-dd  HH:mm:ss Z"];
    [dateFormat1 setDateFormat:@"M/YY"];
    NSString * dateNotFormatted1 = [dateFormat1 stringFromDate:currentdate];
    NSComparisonResult result;

    result = [dateNotFormatted compare:currentdate];
    
    if(result == NSOrderedAscending)
    {
        NSString *strValdExpiryDt = NSLocalizedString(@"valid expiry date", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strValdExpiryDt delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
    }
    else if(result == NSOrderedDescending)
    {
        [_expiryDate setTitle:[NSString stringWithFormat:@"%@",dateFormatted] forState:UIControlStateNormal];
    }
    else if(result == NSOrderedSame)
    {
        NSString *strValdExpiryDt = NSLocalizedString(@"valid expiry date", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strValdExpiryDt delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        //NSLog(@"Date cannot be compared");
    }

    yearString=nil;
       [actionView removeFromSuperview];
     _expiryDate.userInteractionEnabled=YES;
}

- (void)cancel_clicked:(id)sender
{
     [actionView removeFromSuperview];
    _expiryDate.userInteractionEnabled=YES;
}

- (IBAction)checkclick:(id)sender
{
    UIButton *button = (UIButton *)sender;
    button.selected = ![button isSelected];
    if (button.selected)
    {
        checkValueSet=@"1";
        [checkBoxButton setImage:[UIImage imageNamed:@"checkBoxMarked.png"] forState:UIControlStateNormal];
    }
    else
    {
           checkValueSet=@"0";
        [checkBoxButton setImage:[UIImage imageNamed:@"checkBox.png"] forState:UIControlStateNormal];
    }
}

-(IBAction)addbtn_click:(id)sender
{
    [UIView animateWithDuration:0.3f
                          delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                              self.view.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
                          } completion:nil];
    if ([_cardNumber.text length]==0)
    {
        
    }
    else
    {
        cardid=[_cardNumber.text substringToIndex:4];
    }
    if ([_cvvNumber.text length]==0)
    {
        
    }
    else
    {
        cvv=[_cvvNumber.text substringToIndex:3];
    }
    if (_name.text.length==0)
    {
        NSString *strNmOfCard = NSLocalizedString(@"name of card", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strNmOfCard delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if (_cardNumber.text.length==0)
    {
        NSString *strCrdNo = NSLocalizedString(@"enter card number", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strCrdNo delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if ([_expiryDate.titleLabel.text length]==0)
    {
        NSString *strExpiryDate = NSLocalizedString(@"select expirydate", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strExpiryDate delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if ([_cvvNumber.text length]==0)
    {
        NSString *strCVVNo = NSLocalizedString(@"enter CVV number", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strCVVNo delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
   
   else if  ([_expiryDate.titleLabel.text isEqualToString:@"**/**"])
    {
        NSString *strUpdtDetails = NSLocalizedString(@"update your details", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);

        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strUpdtDetails delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    else if  ([cardid isEqualToString:@"****"])
    {
        NSString *strUpdtDetails = NSLocalizedString(@"update your details", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strUpdtDetails delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if  ([cardid isEqualToString:@"****"])
    {
        NSString *strUpdtDetails = NSLocalizedString(@"update your details", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strUpdtDetails delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if  ([cvv isEqualToString:@"***"])
    {
        NSString *strUpdtDetails = NSLocalizedString(@"update your details", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strUpdtDetails delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
        [alert show];
        return;
    }
    else
    {
        NSString *rawString = [_name text];
        NSString *rawString2 = [_cardNumber text];
        NSString *rawString3 = [_cvvNumber text];
         NSString *rawString4 = _expiryDate.titleLabel.text;
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
        NSString *trimmed2 = [rawString2 stringByTrimmingCharactersInSet:whitespace];
        NSString *trimmed3 = [rawString3 stringByTrimmingCharactersInSet:whitespace];
        NSString *trimmed4 = [rawString4 stringByTrimmingCharactersInSet:whitespace];
        if ([trimmed length] == 0 || [trimmed2 length] == 0|| [trimmed3 length] == 0|| [trimmed4 length] == 0)
        {
            NSString *strAttention = NSLocalizedString(@"Attention", Nil);
            NSString *strCorrectValues = NSLocalizedString(@"correct values", Nil);
            NSString *strOk = NSLocalizedString(@"OK", Nil);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strAttention message:strCorrectValues delegate:nil cancelButtonTitle:strOk otherButtonTitles: nil];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        }
        else
        {
            if (_cardNumber.text.length<13)
            {
                NSString *str13digit = NSLocalizedString(@"atleast 13 digit", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);

                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str13digit delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
                [alert show];
            }
            else if (_cardNumber.text.length>19)
            {
                NSString *str = NSLocalizedString(@"digit less than 20", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);

                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
                [alert show];
                
            }
            else if (_cvvNumber.text.length<3)
            {
                NSString *str = NSLocalizedString(@"three digit", Nil);
                NSString *strOk = NSLocalizedString(@"OK", Nil);

                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil];
                [alert show];
            }
            else
            {
                if ([SharedServiceController usesV1API]) {
                    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    [SharedServiceController addBankAccountHolder:_name.text
                        routing:@CZEDR_DEV_ROUTING_NUMBER
                        account:_cardNumber.text
                    accountType:@"checking"
                        success:^(NSDictionary *data) {
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"call_cardcount" object:nil];
                        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(targetMethod_added) userInfo:nil repeats:NO];
                    } failure:^(NSString *message) {
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alert show];
                    }];
                    return;
                }
                [actionView removeFromSuperview];
                [_name resignFirstResponder];
                [_cvvNumber resignFirstResponder];
                [_cardNumber resignFirstResponder];
                
                NSString *strGallery = NSLocalizedString(@"from gallery", Nil);
                NSString *strCancel = NSLocalizedString(@"Cancel", Nil);
                NSString *strOpenCamera = NSLocalizedString(@"Open Camera", Nil);
                NSString *strSensitiveData = NSLocalizedString(@"secure sensitive data", Nil);

                UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:strSensitiveData delegate:self cancelButtonTitle:strCancel destructiveButtonTitle:nil otherButtonTitles:
                                        strGallery,
                                        strOpenCamera,nil];
                 popup.tag = 1;
                [popup showInView:[UIApplication sharedApplication].keyWindow];
            }
        }
    }
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (popup.tag)
    {
        case 1:
        {
            switch (buttonIndex)
            {
                case 0:
                    [self galleryClick:nil];
                    break;
                case 1:
                    [self camraClick:nil];
                    break;
            }
            break;
        }
    }
}

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:    (NSDictionary *)info
{
    cardImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData* data = UIImageJPEGRepresentation(cardImage,100);
   
    NSString *base64String =[data base64EncodedStringWithOptions:0];
    baseImage_16=[base64String substringToIndex:16];
    
    NSString *myCzedrId=[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"];
    NSString *MD5string= [self md5HexDigest:myCzedrId];
    finalString=[MD5string substringToIndex:16];
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"cardInfo"] isEqualToString:@"updtae"])
    {
        NSString *cardid=[NSString stringWithFormat:@"%@",[addcardArraydata valueForKey:@"id"]];
         all_textfieldValues=[NSString stringWithFormat:@"name=%@&card_no=%@&cvv=%@&date=%@&type=%@&default=%@&id=%@",_name.text,_cardNumber.text,_cvvNumber.text,_expiryDate.titleLabel.text,@"visa",checkValueSet,cardid];
    }
    else
    {
         all_textfieldValues=[NSString stringWithFormat:@"name=%@&card_no=%@&cvv=%@&date=%@&type=%@&default=%@",_name.text,_cardNumber.text,_cvvNumber.text,_expiryDate.titleLabel.text,@"visa",checkValueSet];
    }
    NSString *concatString=[NSString stringWithFormat:@"%@%@",baseImage_16,finalString];
    NSString *key =concatString;
    NSString * secret =all_textfieldValues;
    NSError *error;
    
    encryptedData1 = [RNEncryptor encryptData:[secret dataUsingEncoding:NSUTF8StringEncoding]
                       withSettings:kRNCryptorAES256Settings
                           password:key
                              error:&error];
    
    
    NSString *string = [[NSString alloc] initWithData:encryptedData1 encoding:NSUTF8StringEncoding];
    if (string)
    {
//        printf("%s\n", [string UTF8String]);
    }
    else
    {
//        printf("%s\n", [[encryptedData1 base64EncodedStringWithOptions:0] UTF8String]);
    }
    newstring=[NSString stringWithFormat:@"%s",[[encryptedData1 base64EncodedStringWithOptions:0] UTF8String]];
    
    [self imageUpload_service];
   
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

//NSData *plain = [secret dataUsingEncoding:NSUTF8StringEncoding];
//
//NSData *cipher = [plain AES128EncryptedDataWithKey:key];
//// NSData *cipher =[plain AES256EncryptWithKey:key];
//
//newstring =[self NSDataToHex:cipher];
//printf("%s",[[cipher description] UTF8String]);

-(NSString*) NSDataToHex:(NSData*)data
{
    const unsigned char *dbytes = [data bytes];
    NSMutableString *hexStr =
    [NSMutableString stringWithCapacity:[data length]*2];
    int i;
    for (i = 0; i < [data length]; i++) {
        [hexStr appendFormat:@"%02x ", dbytes[i]];
    }
    return [NSString stringWithString: hexStr];
}

//printf("%s",[[cipher description] UTF8String]);
//NSData  *decData = [cipher AES256DecryptWithKey:key];
//printf("%s\n", [[decData description] UTF8String]);
//printf("%s\n", [[[NSString alloc] initWithData:decData encoding:NSUTF8StringEncoding] UTF8String]);
// newstring = [AESCrypt encrypt:secret password:concatString];

//  newstring=encryptedData;
// NSString *signatureString = [cipher base64EncodedStringWithOptions:0];
//EQLLzIbl8kQc/+gX3Bi062V69bJlw5HPguw3jKdA3rXWL2HBIoJ4102GVvqw+Edf8Hk8w6/lPB/MAGTrGboY4Rw2rPod1Q4AvlHGEImgO1Y=
//cox+s7eQRleMASJjs1VLO4FLtIc4OUU5wWO+uPak2HBvWGVG2Jp/dNY2CFD/eI4TVOkDaRsdZvkkK7Qy8w2TtY5pAM4LIPiM+Pp7RlsDGa0=

// newstring = [AESCrypt encrypt:secret password:concatString];

//  newstring=encryptedData;
// NSString *signatureString = [cipher base64EncodedStringWithOptions:0];
//EQLLzIbl8kQc/+gX3Bi062V69bJlw5HPguw3jKdA3rXWL2HBIoJ4102GVvqw+Edf8Hk8w6/lPB/MAGTrGboY4Rw2rPod1Q4AvlHGEImgO1Y=
//cox+s7eQRleMASJjs1VLO4FLtIc4OUU5wWO+uPak2HBvWGVG2Jp/dNY2CFD/eI4TVOkDaRsdZvkkK7Qy8w2TtY5pAM4LIPiM+Pp7RlsDGa0=


//    NSString *cipherString=[NSString stringWithFormat:@"%s",[[cipher description] UTF8String]];
//        NSCharacterSet *charsToRemove = [NSCharacterSet characterSetWithCharactersInString:@"< >"];
//        NSString *someString = [cipherString stringByTrimmingCharactersInSet:charsToRemove];
//        newstring = [someString stringByReplacingOccurrencesOfString:@" " withString:@""];
-(NSString*)md5HexDigest:(NSString*)input {
    const char* str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

- (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark alertview
-(void)messageCode
{
    
    backView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    if ([[UIScreen mainScreen] bounds].size.height == 568.0f||[[UIScreen mainScreen] bounds].size.height == 480.0f) {
        AlerView1=[[UIView alloc]initWithFrame:CGRectMake(23, 190, 280, 200)];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667.0f) {
        AlerView1=[[UIView alloc]initWithFrame:CGRectMake(47, 190, 280, 200)];
    }
    else
    {
        AlerView1=[[UIView alloc]initWithFrame:CGRectMake(66, 190, 280, 200)];
        
    }
    
    backView.backgroundColor=[UIColor colorWithWhite:0 alpha:0.3];
    AlerView1.backgroundColor=[UIColor whiteColor];
    UILabel *titleLbl=[[UILabel alloc]initWithFrame:CGRectMake(10, 0, 280, 50)];
    titleLbl.text=@"You Need to select an image to secure sensitive data.";
    titleLbl.backgroundColor=[UIColor clearColor];
    [titleLbl setTextColor:[UIColor colorWithRed:55/255.0 green:181/255.0 blue:229/255.0 alpha:1.0]];
    titleLbl.font=[UIFont fontWithName:@"Avenir-Roman" size:14.0];
    titleLbl.numberOfLines=0;
    [AlerView1 addSubview:titleLbl];
    
    UIView *line1=[[UIView alloc]initWithFrame:CGRectMake(0, 50, 280, 2)];
    line1.backgroundColor=[UIColor colorWithRed:55/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
    [AlerView1 addSubview:line1];
    
    NSString *strGallery = NSLocalizedString(@"from gallery", Nil);
    
    UIButton *chosseGalleryButton=[UIButton buttonWithType:UIButtonTypeCustom];
    chosseGalleryButton.frame=CGRectMake(10, 55, 280, 40);
    [chosseGalleryButton setTitle:strGallery forState:UIControlStateNormal];
    [chosseGalleryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [chosseGalleryButton addTarget:self action:@selector(galleryClick:) forControlEvents:UIControlEventTouchUpInside];
    [AlerView1 addSubview:chosseGalleryButton];
    UIView *linefr3=[[UIView alloc]initWithFrame:CGRectMake(0, 100, 280, 1)];
    linefr3.backgroundColor=[UIColor colorWithRed:209/255.0 green:209/255.0 blue:209/255.0 alpha:1.0];
    [AlerView1 addSubview:linefr3];
    
    NSString *strOpenCamera = NSLocalizedString(@"Open Camera", Nil);
    
    UIButton *camraButton=[UIButton buttonWithType:UIButtonTypeCustom];
    camraButton.frame=CGRectMake(10, 102, 280, 40);
    [camraButton setTitle:strOpenCamera forState:UIControlStateNormal];
    [camraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [camraButton addTarget:self action:@selector(camraClick:) forControlEvents:UIControlEventTouchUpInside];
    [AlerView1 addSubview:camraButton];
    UIView *linefr=[[UIView alloc]initWithFrame:CGRectMake(0, 150, 280, 1)];
    linefr.backgroundColor=[UIColor colorWithRed:209/255.0 green:209/255.0 blue:209/255.0 alpha:1.0];
    [AlerView1 addSubview:linefr];
    
    
    NSString *strCancel = NSLocalizedString(@"Cancel", Nil);
    
    UIButton *okButton=[UIButton buttonWithType:UIButtonTypeCustom];
    okButton.frame=CGRectMake(10, 153, 280, 40);
    [okButton setTitle:strCancel forState:UIControlStateNormal];
    [okButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [okButton addTarget:self action:@selector(okBackClick:) forControlEvents:UIControlEventTouchUpInside];
    
    okButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    camraButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    chosseGalleryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [AlerView1 addSubview:okButton];
    [backView addSubview:AlerView1];
    [self.view addSubview:backView];
}
-(IBAction)okBackClick:(id)sender
{
    [backView removeFromSuperview];
}

-(IBAction)galleryClick:(id)sender
{
    imagePicker = [[UIImagePickerController alloc]init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:^{}];
    [backView removeFromSuperview];
}

-(IBAction)camraClick:(id)sender
{
    //UIImagePickerController space in memory
    imagePicker = [[UIImagePickerController alloc]init];
    //Set the delegate
    imagePicker.delegate = self;
    //Set the sourceType
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    //Show Image Picker UI
    [self presentViewController:imagePicker animated:YES completion:^{}];
    [backView removeFromSuperview];
}

-(void)update_card_service
{
    if ([SharedServiceController usesV1API]) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        return;
    }
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
        NSString* result =[NSString stringWithFormat:@"%@.%@",[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"],@"jpg"];
        
        NSString *authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:newstring forKey:@"enc_data"];
        [params setValue:result forKey:@"enc_image"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        [manager POST:[NSString stringWithFormat:@"%s?auth_code=%@&enc_data=%@&enc_image=%@", CZEDR_LEGACY_CARD_UPDATE, authCodeStr, newstring, result] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
            
             response = [NSString stringWithFormat:@"%@",operation.responseString];
          
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 [[NSUserDefaults standardUserDefaults] setValue:@"store_databse" forKey:@"update_value"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"call_cardcount" object:nil];
                 [NSTimer scheduledTimerWithTimeInterval:2.0
                                                  target:self
                                                selector:@selector(targetMethod_updated)
                                                userInfo:nil
                                                 repeats:NO];
             }
             else
             {
                 NSString *strTitle = NSLocalizedString(@"Card not Updated", Nil);
                 NSString *str = NSLocalizedString(@"Your Card has not been updated", Nil);
                 NSString *strOk = NSLocalizedString(@"OK", Nil);

                 
                 UIAlertView *aler=[[UIAlertView alloc]initWithTitle:strTitle message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                 [aler show];
               [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
             }
             
         }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                  
                  NSString *strErrorMsg = NSLocalizedString(@"error", Nil);
                  NSString *strOk = NSLocalizedString(@"OK", Nil);

                  UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strErrorMsg delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                  [alert show];
              }];
        }
}

-(void)addcard_service
{
    if ([SharedServiceController usesV1API]) {
        return;
    }
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
           NSString *result =[NSString stringWithFormat:@"%@.%@",[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"],@"jpg"];
        
//        NSString *result =[NSString stringWithFormat:@"%s.%@","manya",@"jpg"];
       
       NSString *authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:newstring forKey:@"enc_data"];
        [params setValue:result forKey:@"enc_image"];
      
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
    
        [manager POST:[NSString stringWithFormat:@"%s?auth_code=%@&enc_data=%@&enc_image=%@", CZEDR_LEGACY_CARD_DECRYPT, authCodeStr, newstring, result] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 [NSTimer scheduledTimerWithTimeInterval:2.0
                                                  target:self
                                                selector:@selector(targetMethod_added)
                                                userInfo:nil
                                                 repeats:NO];
                  [[NSNotificationCenter defaultCenter] postNotificationName:@"call_cardcount" object:nil];
             }
             else
             {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                 
                 NSString *str = NSLocalizedString(@"Card not added", Nil);
                 NSString *strOk = NSLocalizedString(@"OK", Nil);

                UIAlertView *aler=[[UIAlertView alloc]initWithTitle:nil message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                 [aler show];
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

-(void)targetMethod_deleted
{
    NSString *strCardDeleted = NSLocalizedString(@"Card Deleted", Nil);
    NSString *str = NSLocalizedString(@"Card has been deleted", Nil);
    NSString *strOk = NSLocalizedString(@"OK", Nil);
    
    UIAlertView *alertview = [[UIAlertView alloc]initWithTitle:strCardDeleted message:str delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
    [alertview show];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

-(void)targetMethod_updated
{
    NSString *strCardUpdated = NSLocalizedString(@"Card Updated", Nil);
    NSString *str = NSLocalizedString(@"Card has been updated", Nil);
    NSString *strOk = NSLocalizedString(@"OK", Nil);
    
    UIAlertView *aler=[[UIAlertView alloc]initWithTitle:strCardUpdated message:str delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
    [aler show];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

-(void)targetMethod_added
{
    NSString *strCardAdded = NSLocalizedString(@"Card Added", Nil);
    NSString *str = NSLocalizedString(@"Card has been added", Nil);
    NSString *strOk = NSLocalizedString(@"OK", Nil);
    
    UIAlertView *alertview = [[UIAlertView alloc]initWithTitle:strCardAdded message:str delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
    [alertview show];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag==200)
    {
        if (buttonIndex==0)
        {
            
        }
        else
        {
            [self deletecard_service];
        }
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)imageUpload_service
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int i = [reachAbilty updateInterfaceWithReachability];
    if (i==0)
    {
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else
    {
        UIImage * getImage=[self imageWithImage:cardImage scaledToSize:CGSizeMake(200, 200)];
        NSData *myData=UIImageJPEGRepresentation(getImage,0.8);
        NSMutableURLRequest *request;
        
        NSString *urlString = @CZEDR_LEGACY_IMAGE_UPLOAD;
        
        NSString *result =[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"];
        request= [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"POST"];
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        NSMutableData *postbody = [NSMutableData data];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"enc_pic\"; filename=\"%@.jpg\"\r\n",result] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[NSData dataWithData:myData]];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:postbody];
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString *returnString;
        returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        
        if ([[[returnString JSONValue] valueForKey:@"Status"] isEqualToString:@"true"])
        {
            if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"cardInfo"] isEqualToString:@"updtae"])
            {
                [self update_card_service];
            }
            else
            {
                [self addcard_service];
            }
        }
        else
        {
            NSString *str = NSLocalizedString(@"card image not uploaded", Nil);
            NSString *strOk = NSLocalizedString(@"OK", Nil);

            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
            [alert show];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }
}

-(void)deletecard_service
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
            NSString *bankId = [NSString stringWithFormat:@"%@", [addcardArraydata valueForKey:@"id"]];
            [SharedServiceController deleteBankAccountId:bankId
                success:^(NSDictionary *data) {
                [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(targetMethod_deleted) userInfo:nil repeats:NO];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"call_cardcount" object:nil];
            } failure:^(NSString *message) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }];
            return;
        }
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        NSString* authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:[addcardArraydata valueForKey:@"id"] forKey:@"card_id"];
        
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"deletecreditcard"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                  [NSTimer scheduledTimerWithTimeInterval:2.0
                                                  target:self
                                                selector:@selector(targetMethod_deleted)
                                                userInfo:nil
                                                 repeats:NO];
                  [[NSNotificationCenter defaultCenter] postNotificationName:@"call_cardcount" object:nil];
             }
             else
             {
                 NSString *alert=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] valueForKey:@"result"] objectAtIndex:0]];
                 
                 NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                 if([language isEqual:@"fr"])
                 {
                     if ([alert isEqual:@"Please enter a valid password and try again."])
                     {
                         alert = @"Entrez un mot de passe valide et réessayez.";
                     }
                     else if ([alert isEqual:@"card deleted"])
                     {
                         alert = @"Carte supprimée";
                     }
                     else if ([alert isEqual:@"Creditcard which you are choosing is default"])
                     {
                         alert = @"La carte de crédit que vous choisissez est par défaut";
                     }
                     else if ([alert isEqual:@"No Card Found"])
                     {
                         alert = @"Aucune carte trouvée";
                     }
                     
                 }
                 
                 UIAlertView *aler=[[UIAlertView alloc]initWithTitle:nil message:alert delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                 [aler show];
                 [MBProgressHUD hideHUDForView:self.view animated:YES];
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

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end
