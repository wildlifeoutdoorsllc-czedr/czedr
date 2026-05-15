//
//  pendingInvoicesViewController.m
//  payoox
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import "pendingInvoicesViewController.h"
#import "creditNewInvoiceViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "MMDrawerVisualState.h"
#import "MMDrawerBarButtonItem.h"
#import <QuartzCore/QuartzCore.h>
#import "InvoiceDetailViewController.h"
#import "SharedServiceController.h"
#import "leftSwipeViewController.h"
@interface pendingInvoicesViewController ()

@end

static int receve_totalcount;
static int sent_totalcount;
@implementation pendingInvoicesViewController
-(void)viewWillAppear:(BOOL)animated
{
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"pendingclick"] isEqualToString:@"pending"])
    {
        [back setImage:[UIImage imageNamed:@"menu2.png"] forState:UIControlStateNormal];
    }
 
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"cancel"] isEqualToString:@"sentcancel"])
    {
        _segment.selectedSegmentIndex=1;
        segmentValue=1;
        [sentArray removeAllObjects];
        sentStartvariable=1;
        [self sentinvoice_service];
    }
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"revcancel"] isEqualToString:@"receviecancel"])
    {
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"revcancel"];
        [[NSUserDefaults standardUserDefaults] synchronize];
         _segment.selectedSegmentIndex=0;
        receveStartvariable=1;
        [recevieArray removeAllObjects];
        [self recevied_service];
    }
    
    if(payNowBool == true)
    {
        [self recevied_service];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *strTitleLbl = NSLocalizedString(@"Pending Invoices", Nil);
    _titleLbl.text = [strTitleLbl uppercaseString];
    
    NSString *strSegmnt0 = NSLocalizedString(@"Received Invoices", Nil);
    NSString *strSegmnt1 = NSLocalizedString(@"Sent Invoices", Nil);
    
    [_segment setTitle:strSegmnt0 forSegmentAtIndex:0];
    [_segment setTitle:strSegmnt1 forSegmentAtIndex:1];
    
    checkbool=YES;
    sentStartvariable=1;
    receveStartvariable=1;
    receve_totalcount=0;
    sent_totalcount=0;
    [self recevied_service];
    noinvoicelbl.hidden=YES;
    self.tableView.hidden=YES;
    recevieArray=[[NSMutableArray alloc]init];
    sentArray=[[NSMutableArray alloc]init];
    commonArray=[[NSMutableArray alloc]init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(IBAction)leftDrawerButtonPress:(id)sender
{
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"pendingclick"] isEqualToString:@"pending"])
    {
        [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    }
    else
    {
        if (payNowBool == true)
        {
            leftSwipeViewController *obj=[[leftSwipeViewController alloc]initWithNibName:@"leftSwipeViewController" bundle:nil];
            [self.navigationController pushViewController:obj animated:YES];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return commonArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UILabel *Namelabel;
    UILabel *Emaillabel;
    UILabel *PriceLabel;
    if (cell == nil)
    {
           
    }
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    Namelabel  =[[UILabel alloc]initWithFrame:(CGRectMake(24, 9, 150, 25))];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
    Namelabel.autoresizesSubviews=YES;
    [Namelabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
    Namelabel.font=[UIFont fontWithName:@"Avenir-Roman" size:12.5];
  
    Emaillabel  =[[UILabel alloc]initWithFrame:(CGRectMake(24,24, 200, 30))];
    Emaillabel.autoresizesSubviews=YES;
    [Emaillabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
    [Emaillabel setFont: [UIFont systemFontOfSize:12.0]];
    
    PriceLabel  =[[UILabel alloc]initWithFrame:(CGRectMake(225, 23, 70, 25))];
    PriceLabel.autoresizesSubviews=YES;
    PriceLabel.textAlignment = NSTextAlignmentRight;
    [PriceLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
    PriceLabel.font=[UIFont fontWithName:@"Avenir-Roman" size:12.5];
   
    Namelabel.text=[[commonArray objectAtIndex:indexPath.row] valueForKey:@"name"] ;
    Emaillabel.text=[[commonArray objectAtIndex:indexPath.row] valueForKey:@"user_email"];
    
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
    
    PriceLabel.text = [NSString stringWithFormat:@"%@%@",symbol,[numberFormat stringFromNumber:[NSNumber numberWithFloat:[[[commonArray objectAtIndex:indexPath.row] valueForKey:@"amount"] floatValue]]]];
    
    if([PriceLabel.text containsString:@"-"])
    {
        PriceLabel.text = [PriceLabel.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
        PriceLabel.text = [NSString stringWithFormat:@"%@%@",@"-",PriceLabel.text];
    }
    
    [cell.contentView addSubview:Namelabel];
    [cell.contentView addSubview:Emaillabel];
    [cell.contentView addSubview:PriceLabel];
    UIImageView *Rightimage=[[UIImageView alloc]initWithFrame:(CGRectMake(tableView.frame.size.width-20,cell.frame.size.height/2+5, 10, 15))] ;
    Rightimage.image=[UIImage imageNamed:@"arrowgrey.png"];
    [cell.contentView addSubview:Rightimage];
    if(indexPath.row == [commonArray count] - 1)
    {
        if(commonArray.count<10)
        {
        }
        else
        {
            if(segmentValue==0)
            {
              if (receveStartvariable<commonArray.count)
              {
                 if(commonArray.count==receveStartvariable)
                 {
                 }
                 else
                 {
                   if(receve_totalcount==commonArray.count)
                   {
                   }
                   receveStartvariable=receveStartvariable+10;
                   if(receveStartvariable>commonArray.count)
                   {
                   }
                   else
                   {
                     [self recevied_service];
                   }
               }
            }
        }
        else
        {
            if(sentStartvariable<commonArray.count)
            {
                if(commonArray.count==sent_totalcount)
                {
                }
                else
                {
                    sentStartvariable=sentStartvariable+10;
                    [self sentinvoice_service];
                }
            }
        }
     }
  }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    dataArray1=[[NSMutableArray alloc]init];
    InvoiceDetailViewController *invoice=[[InvoiceDetailViewController alloc]initWithNibName:@"InvoiceDetailViewController" bundle:nil];
    if(segmentValue==0)
    {
        invoice.selectedIndex=0;
        dataArray1=[recevieArray objectAtIndex:indexPath.row];
    }
    else
    {
        invoice.selectedIndex=1;
        dataArray1=[sentArray objectAtIndex:indexPath.row];
    }
    [self.navigationController pushViewController:invoice animated:YES];
}

-(IBAction)addButton:(id)sender
{
    creditNewInvoiceViewController *credit=[[creditNewInvoiceViewController alloc]initWithNibName:@"creditNewInvoiceViewController" bundle:nil];
    [self.navigationController pushViewController:credit animated:YES];
}

-(IBAction)backButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:true];
}

-(IBAction)segmentButton:(id)sender
{
    noinvoicelbl.hidden=YES;
    self.tableView.hidden=NO;

    segmentValue=(int)_segment.selectedSegmentIndex;
    if (segmentValue==0)
    {
        commonArray=recevieArray;
        [self.tableView reloadData];
    }
    else
    {
        if (checkbool==YES)
        {
           checkbool=NO;
           [self sentinvoice_service];
        }
        else
        {
        }
        commonArray = sentArray;
        [self.tableView reloadData];
    }
}

-(void)recevied_service
{
    NSString *start=[NSString stringWithFormat:@"%d",receveStartvariable];
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
        [SharedServiceController fetchReceivedInvoicesOffset:receveStartvariable limit:10
            success:^(NSArray *rows, NSInteger total) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if (rows.count > 0) {
                    noinvoicelbl.hidden = YES;
                    self.tableView.hidden = NO;
                    receve_totalcount = (int)total;
                    [recevieArray removeAllObjects];
                    [recevieArray addObjectsFromArray:rows];
                    commonArray = [NSMutableArray arrayWithArray:recevieArray];
                    [self.tableView reloadData];
                } else {
                    noinvoicelbl.hidden = NO;
                    self.tableView.hidden = YES;
                    NSString *strNoInvoice = NSLocalizedString(@"No invoice available!", Nil);
                    noinvoicelbl.text = strNoInvoice;
                }
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
         NSString* authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:start forKey:@"offset"];
        [params setValue:@"10" forKey:@"limit"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"invoicerecev"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 noinvoicelbl.hidden=YES;
                 self.tableView.hidden=NO;
                
                 receve_totalcount=[[[response JSONValue] valueForKey:@"Total_rows"] intValue];
                 
                 NSArray *data=[[response JSONValue] valueForKey:@"Data"];
        
                 [recevieArray removeAllObjects];
                 
                 [recevieArray addObjectsFromArray:data];
                 commonArray=[NSMutableArray arrayWithArray:recevieArray];
                 [self.tableView reloadData];
             }
             else
             {
                 noinvoicelbl.hidden=NO;
                 self.tableView.hidden=YES;
                 
                 NSString *strNoInvoice = NSLocalizedString(@"No invoice available!", Nil);
                 noinvoicelbl.text = strNoInvoice;
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

-(void)sentinvoice_service
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSString * start=[NSString stringWithFormat:@"%d",sentStartvariable];
    
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
        [SharedServiceController fetchSentInvoicesOffset:sentStartvariable limit:10
            success:^(NSArray *rows, NSInteger total) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                sent_totalcount = (int)total;
                if (rows.count > 0) {
                    noinvoicelbl.hidden = YES;
                    self.tableView.hidden = NO;
                    [sentArray removeAllObjects];
                    [sentArray addObjectsFromArray:rows];
                    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"cancel"] isEqualToString:@"sentcancel"]) {
                        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"cancel"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    commonArray = sentArray;
                    [self.tableView reloadData];
                } else {
                    self.tableView.hidden = YES;
                    noinvoicelbl.hidden = NO;
                    NSString *strNoInvoice = NSLocalizedString(@"No invoice available!", Nil);
                    noinvoicelbl.text = strNoInvoice;
                }
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
        NSString *authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:start forKey:@"offset"];
        [params setValue:@"10" forKey:@"limit"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"invoicehistory"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
              sent_totalcount=[[[response JSONValue] valueForKey:@"Total_rows"] intValue];
             if ([status isEqualToString:@"true"])
             {
                 noinvoicelbl.hidden=YES;
                 self.tableView.hidden=NO;
               
               if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"cancel"] isEqualToString:@"sentcancel"])
               {
                   NSArray *data=[[response JSONValue] valueForKey:@"Data"];
                   [sentArray removeAllObjects];
                   [sentArray addObjectsFromArray:data];
                   [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"cancel"];
                   [[NSUserDefaults standardUserDefaults] synchronize];
                    commonArray=sentArray;
                   [self.tableView reloadData];
               }
               else
               {
                     NSArray *data=[[response JSONValue] valueForKey:@"Data"];
                     [sentArray removeAllObjects];
                     [sentArray addObjectsFromArray:data];
                     [self.tableView reloadData];
               }
             }
             else
             {
                 self.tableView.hidden=YES;
                 noinvoicelbl.hidden=NO;
                 NSString *strNoInvoice = NSLocalizedString(@"No invoice available!", Nil);
                 noinvoicelbl.text=strNoInvoice;
             }
             [MBProgressHUD hideHUDForView:self.view animated:YES];
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
