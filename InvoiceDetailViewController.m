//
//  InvoiceDetailViewController.m
//  payooxe
//
//  Created by Renu on 23/02/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import "InvoiceDetailViewController.h"
#import "pendingInvoicesViewController.h"
#import "creditNewInvoiceViewController.h"
#import "SharedServiceController.h"
#import "makePaymentViewController.h"
@interface InvoiceDetailViewController ()

@end

@implementation InvoiceDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *strTitleLbl = NSLocalizedString(@"INVOICE DETAILS", Nil);
    titleLbl.text = strTitleLbl;
    
    NSString *strPendingLbl = NSLocalizedString(@"Pending (USD)", Nil);
    PendingLbl.text = strPendingLbl;
    
    NSString *strDetailsLbl = NSLocalizedString(@"Details:", Nil);
    detailsLbl.text = strDetailsLbl;
    
    NSString *strPayNow = NSLocalizedString(@"SEND REMINDER", Nil);
    [_payNow setTitle: strPayNow forState: UIControlStateNormal];
    
    NSString *strRejectInvoice = NSLocalizedString(@"REJECT INVOICE", Nil);
    [_rejectInvoice setTitle: strRejectInvoice forState: UIControlStateNormal];
}

-(void)viewWillAppear:(BOOL)animated
{
    //"2015-05-29 09:00:49";
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSDate *date1 = [formatter dateFromString:[dataArray1 valueForKey:@"created_date"]];
    
    NSDateFormatter *formatter1=[[NSDateFormatter alloc]init];
    [formatter1 setDateFormat:@"yyyy-MM-dd"];
    NSString *date2 = [formatter1 stringFromDate:date1];
   
    NSNumberFormatter *numberFormat = [[NSNumberFormatter alloc] init];
    numberFormat.usesGroupingSeparator = YES;
    numberFormat.groupingSeparator = @",";
    numberFormat.groupingSize = 3;
    numberFormat.roundingMode = NSNumberFormatterRoundUp;
    [numberFormat setDecimalSeparator:@"."];
    [numberFormat setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormat setMaximumFractionDigits:2];
    [numberFormat setMinimumFractionDigits:2];
    
    NSLocale *theLocale = [NSLocale currentLocale];
    NSString *symbol = [theLocale objectForKey:NSLocaleCurrencySymbol];
    
    dollarAmount.text = [NSString stringWithFormat:@"%@%@",symbol,[numberFormat stringFromNumber:[NSNumber numberWithFloat:[[dataArray1  valueForKey:@"amount"] floatValue]]]];

    if([dollarAmount.text containsString:@"-"])
    {
        dollarAmount.text = [dollarAmount.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
        dollarAmount.text = [NSString stringWithFormat:@"%@%@",@"-",dollarAmount.text];
    }
   
    name.text=[dataArray1 valueForKey:@"name"];
    emailuser.text=[dataArray1 valueForKey:@"user_email"];
    date.text=date2;
    details.text=[dataArray1 valueForKey:@"description"];
    if (_selectedIndex==0)
    {
        NSString *strPAYNOW = NSLocalizedString(@"PAY NOW", Nil);
        NSString *strREJECTINVOICE = NSLocalizedString(@"REJECT INVOICE", Nil);
        
        [_payNow setTitle:strPAYNOW forState:UIControlStateNormal];
        [_rejectInvoice setTitle:strREJECTINVOICE forState:UIControlStateNormal];
    }
    else
    {
        NSString *strSENDREMINDER = NSLocalizedString(@"SEND REMINDER", Nil);
        NSString *strCANCELINVOICE = NSLocalizedString(@"CANCEL INVOICE", Nil);
        
        
        //_payNow.hidden=YES;
        [_payNow setTitle:strSENDREMINDER forState:UIControlStateNormal];
        //_rejectInvoice.frame=CGRectMake(_payNow.frame.origin.x, _payNow.frame.origin.y, _payNow.frame.size.width, _payNow.frame.size.height);
        [_rejectInvoice setTitle:strCANCELINVOICE forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Sender Reminder Buuton
- (IBAction)payNow:(id)sender
{
    [[NSUserDefaults standardUserDefaults]setValue:nil forKey:@"pmakepaymentclick"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (_selectedIndex==0)
    {
        [[NSUserDefaults standardUserDefaults] setValue:@"paynow_for" forKey:@"make_p"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        makePaymentViewController *obj=[[makePaymentViewController alloc]initWithNibName:@"makePaymentViewController" bundle:nil];
        obj.paytoId = [dataArray1 valueForKey:@"user_id"];
        [self.navigationController pushViewController:obj animated:YES];
    }
    else
    {
        [self senderRemonderWebService];
    }
}

-(void) senderRemonderWebService
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
           
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
            NSString* authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
            [params setValue:authCodeStr forKey:@"auth_code"];
            [params setValue:[dataArray1 valueForKey:@"id"] forKey:@"invoice_id"];
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"resendinvoice"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
             {
                 NSString *response;
                 [MBProgressHUD hideHUDForView:self.view animated:YES];
                 response = [NSString stringWithFormat:@"%@",operation.responseString];
                 NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
                 
                 if ([status isEqualToString:@"true"])
                 {
                     NSString *str = NSLocalizedString(@"Reminder has been set", Nil);
                     NSString *strOk = NSLocalizedString(@"OK", Nil);

                     UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:str delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
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

- (IBAction)rejectedInvoice:(id)sender
{
    if (_selectedIndex==0)
    {
        [self receviecancel_click];
        
    }
    else
    {
        [self Sentcancel_click];
    }
}

-(void)Sentcancel_click
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
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
         NSString* authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:[dataArray1 valueForKey:@"id"] forKey:@"inv_id"];

        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"cancelinvoice"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 [[NSUserDefaults standardUserDefaults] setValue:@"sentcancel" forKey:@"cancel"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 
                 NSString *str = NSLocalizedString(@"succesfully canceled", Nil);
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
                     if ([Alertstatus isEqual:@"Invoice Cancelled"])
                     {
                         Alertstatus = @"Facture annulée";
                     }
                     else if([Alertstatus isEqual:@"Already Cancelled"])
                     {
                         Alertstatus = @"Déjà annulé";
                     }
                     else if([Alertstatus isEqual:@"Invoice Cannot be Cancelled"])
                     {
                         Alertstatus = @"La facture ne peut pas être annulée";
                     }
                     else if([Alertstatus isEqual:@"Invoice Id is not correct"])
                     {
                         Alertstatus = @"L'ID de facture n'est pas correct";
                     }
                 }
                 
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                 [alert show];
                 return;
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
-(void)receviecancel_click
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
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        NSString* authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:[dataArray1 valueForKey:@"id"] forKey:@"inv_id"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"rejectinvoice"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if([status isEqualToString:@"true"])
             {
                 [[NSUserDefaults standardUserDefaults] setValue:@"receviecancel" forKey:@"revcancel"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 
                 NSString *str = NSLocalizedString(@"invoice has been canceled", Nil);
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
                     if ([Alertstatus isEqual:@"Already Rejected"])
                     {
                         Alertstatus = @"Déjà rejeté";
                     }
                     else if([Alertstatus isEqual:@"Invoice Cannot be Rejected"])
                     {
                         Alertstatus = @"La facture ne peut pas être rejetée";
                     }
                     else if([Alertstatus isEqual:@"Invoice Id is not correct"])
                     {
                         Alertstatus = @"L'ID de facture n'est pas correct";
                     }
                 }
                 
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                 [alert show];
                 return;
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
@end
