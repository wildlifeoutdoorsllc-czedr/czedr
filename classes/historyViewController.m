//
//  historyViewController.m
//  payoox
//
//  Created by Renu on 13/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import "historyViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "MMDrawerVisualState.h"
#import "MMDrawerBarButtonItem.h"
#import <QuartzCore/QuartzCore.h>
#import "HistoryInvoiveViewController.h"
#import "generalViewController.h"

#import "SharedServiceController.h"

@interface historyViewController ()

@end

@implementation historyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    nohistory.hidden=YES;
    startlimit=0;
    endlimt=10;
    historyArraydata=[[NSMutableArray alloc]init];
    tableDetail.hidden=YES;
    [self call_paymentHistoryService];
    
    NSString *strTitleLbl = NSLocalizedString(@"History", Nil);
    _titleLbl.text = [strTitleLbl uppercaseString];
    
    NSString *strNoHistory = NSLocalizedString(@"No history found", Nil);
    nohistory.text = strNoHistory;
}
-(void)viewWillAppear:(BOOL)animated
{
//    [self.tableDetail dataSource];
//    [self.tableDetail delegate];
    
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"historyclick"] isEqualToString:@"history"])
    {
        [back setImage:[UIImage imageNamed:@"menu2.png"] forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(IBAction)leftDrawerButtonPress:(id)sender
{
   if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"historyclick"] isEqualToString:@"history"]) {
       [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return historyArraydata.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell = [tableView dequeueReusableCellWithIdentifier:nil];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
        UILabel *Namelabel  =[[UILabel alloc]initWithFrame:(CGRectMake(15, 2, 150, 25))];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        Namelabel.text=[[historyArraydata objectAtIndex:indexPath.row] valueForKey:@"name"];
        Namelabel.autoresizesSubviews=YES;
        [Namelabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
        Namelabel.font=[UIFont fontWithName:@"Avenir-Roman" size:12.5];
        [cell.contentView addSubview:Namelabel];
        UILabel *Emaillabel = [[UILabel alloc]initWithFrame:(CGRectMake(15,17, 200, 30))];
        Emaillabel.autoresizesSubviews=YES;
        [Emaillabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
      
        Emaillabel.font = [UIFont fontWithName:@"Avenir-Roman" size:12.5];
        [Emaillabel setFont: [UIFont systemFontOfSize:12.0]];
        [cell.contentView addSubview:Emaillabel];
    if ([[UIScreen mainScreen] bounds].size.height == 568.0f) {
        PriceLabel  =[[UILabel alloc]initWithFrame:(CGRectMake(tableDetail.frame.size.width-110, 21, 100, 25))];

    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667.0f) {
        PriceLabel  =[[UILabel alloc]initWithFrame:(CGRectMake(tableDetail.frame.size.width-170, 21, 100, 25))];

    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736.0f) {
        PriceLabel  =[[UILabel alloc]initWithFrame:(CGRectMake(tableDetail.frame.size.width-210, 21, 100, 25))];

    }
        PriceLabel.textAlignment=NSTextAlignmentRight;
    
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
    
    PriceLabel.text = [NSString stringWithFormat:@"%@%@",symbol,[numberFormat stringFromNumber:[NSNumber numberWithFloat:[[[historyArraydata objectAtIndex:indexPath.row] valueForKey:@"amount"] floatValue]]]];
    
    if([PriceLabel.text containsString:@"-"])
    {
        PriceLabel.text = [PriceLabel.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
         PriceLabel.text = [NSString stringWithFormat:@"%@%@",@"-",PriceLabel.text];
    }
        PriceLabel.autoresizesSubviews=YES;
        [PriceLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
        int check=[[[historyArraydata objectAtIndex:indexPath.row] valueForKey:@"amount"] intValue];
        if (check<0)
        {
            Emaillabel.text=[NSString stringWithFormat:@"%@ - %@",[[historyArraydata objectAtIndex:indexPath.row] valueForKey:@"email"],[[historyArraydata objectAtIndex:indexPath.row] valueForKey:@"receiver_user_id"]];
            PriceLabel.textColor=[UIColor redColor];
        }
        else
        {
              Emaillabel.text=[NSString stringWithFormat:@"%@ - %@",[[historyArraydata objectAtIndex:indexPath.row] valueForKey:@"email"],[[historyArraydata objectAtIndex:indexPath.row] valueForKey:@"sender_user_id"]];
              PriceLabel.textColor=[UIColor colorWithRed:40/255.0 green:188/255.0 blue:121/255.0 alpha:1.0];
        }
        PriceLabel.font=[UIFont fontWithName:@"Avenir-Roman" size:12.5];
        [cell.contentView addSubview:PriceLabel];
    
        UILabel *passwordLabel  =[[UILabel alloc]initWithFrame:(CGRectMake(15,37, 200, 30))];
        passwordLabel.autoresizesSubviews=YES;
        [passwordLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
        passwordLabel.text=[NSString stringWithFormat:@"**** **** ****%@",[[historyArraydata objectAtIndex:indexPath.row] valueForKey:@"cardnumber"]];
        passwordLabel.font=[UIFont fontWithName:@"Avenir-Roman" size:12.5];
        [passwordLabel setFont: [UIFont systemFontOfSize:12.0]];
        [cell.contentView addSubview:passwordLabel];
        if (indexPath.row == [historyArraydata count] - 1)
        {
            if (historyArraydata.count<10)
            {
            }
           else
           {
            if (startlimit<historyArraydata.count)
            {
            if (historyArraydata.count==startlimit)
            {
            }
            else
            {
                startlimit=startlimit+10;
            if (startlimit>historyArraydata.count)
            {
            }
            else
            {
               [self call_paymentHistoryService];
            }
          }
        }
      }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    dataArrayhistory=[historyArraydata objectAtIndex:indexPath.row];
    HistoryInvoiveViewController *history=[[HistoryInvoiveViewController alloc]initWithNibName:@"HistoryInvoiveViewController" bundle:nil];
    [self.navigationController pushViewController:history animated:YES];
}

- (IBAction)backButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)call_paymentHistoryService
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
            [SharedServiceController fetchPaymentHistorySuccess:^(NSArray *rows, NSInteger total) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if (rows.count == 0) {
                    nohistory.hidden=NO;
                    tableDetail.hidden=YES;
                } else {
                    nohistory.hidden=YES;
                    tableDetail.hidden=NO;
                    [historyArraydata addObjectsFromArray:rows];
                    total_count = (int)total;
                    tableDetail.dataSource=self;
                    tableDetail.delegate=self;
                    [tableDetail reloadData];
                }
            } failure:^(NSString *message) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                nohistory.hidden=NO;
                tableDetail.hidden=YES;
            }];
            return;
        }

        NSString *start=[NSString stringWithFormat:@"%d",startlimit];
        NSString *limit=[NSString stringWithFormat:@"%d",endlimt];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] forKey:@"auth_code"];
        [params setValue:start forKey:@"offset"];
        [params setValue:limit forKey:@"limit"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"transactionhistroy"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 nohistory.hidden=YES;
                 tableDetail.hidden=NO;
                 NSArray *data=[[response JSONValue] valueForKey:@"Data"];
                 [historyArraydata addObjectsFromArray:data];
              
                 total_count=[[[response JSONValue] valueForKey:@"Total_row"]intValue];
                 tableDetail.dataSource=self;
                 tableDetail.delegate=self;
                 [tableDetail reloadData];
             }
             else
             {
                 nohistory.hidden=NO;
                 tableDetail.hidden=YES;
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
