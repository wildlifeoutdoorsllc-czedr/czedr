//
//  HistoryInvoiveViewController.m
//  Czedr
//
//  Created by Renu on 24/02/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import "HistoryInvoiveViewController.h"
#import "historyViewController.h"
@interface HistoryInvoiveViewController ()

@end

@implementation HistoryInvoiveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *strTitleLbl = NSLocalizedString(@"HISTORY INVOICE", Nil);
    
    _titleLbl.text = strTitleLbl;
    
    NSString *strRecvdUSD = NSLocalizedString(@"Received", Nil);
    _received.text=strRecvdUSD;
    
    NSString *strDetail = NSLocalizedString(@"Details:", Nil);
    _detailLbl.text=strDetail;
}

-(void)viewWillAppear:(BOOL)animated
{
    name.text=[dataArrayhistory valueForKey:@"name"];
    
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
    
    amount.text = [NSString stringWithFormat:@"%@%@",symbol,[numberFormat stringFromNumber:[NSNumber numberWithFloat:[[dataArrayhistory  valueForKey:@"amount"] floatValue]]]];
    
    if([amount.text containsString:@"-"])
    {
        amount.text = [amount.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
        amount.text = [NSString stringWithFormat:@"%@%@",@"-",amount.text];
    }
    
    detail.text=[dataArrayhistory valueForKey:@"transaction_notes"];
    email.text=[dataArrayhistory valueForKey:@"email"];
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSDate *date1 = [formatter dateFromString:[dataArrayhistory valueForKey:@"created_date"]];
    NSDateFormatter *formatter1=[[NSDateFormatter alloc]init];
    [formatter1 setDateFormat:@"yyyy-MM-dd"];
    NSString *date2 = [formatter1 stringFromDate:date1];
    date.text=date2;
    int amu=[[dataArrayhistory valueForKey:@"amount"] intValue];
    if (amu<0)
    {
        NSString *strPaidUSD = NSLocalizedString(@"Paid (USD)", Nil);
        _received.text=strPaidUSD;
//        deatilView.backgroundColor=[UIColor colorWithRed:233/255.0 green:69/255.0 blue:36/255.0 alpha:1.0];
//        _viewhistory.backgroundColor=[UIColor colorWithRed:233/255.0 green:69/255.0 blue:36/255.0 alpha:1.0];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)backButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
