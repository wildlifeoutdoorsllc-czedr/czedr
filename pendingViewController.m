//
//  pendingViewController.m
//  payooxe
//
//  Created by Renu on 24/02/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import "pendingViewController.h"
#import "creditNewInvoiceViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "MMDrawerVisualState.h"
#import "MMDrawerBarButtonItem.h"
#import <QuartzCore/QuartzCore.h>
#import "InvoiceDetailViewController.h"

@interface pendingViewController ()

@end

@implementation pendingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    Namearray=[[NSMutableArray alloc] initWithObjects:@"DAVID",@"SIYA",@"RIYA", @"SIYA",@"RIYA",nil];
    nameArray2=[[NSMutableArray alloc]initWithObjects:@"john",@"siya",@"diya",@"rajesh",@"renu", nil];
    emailArray=[[NSMutableArray alloc]initWithObjects:@"john@gmail.com",@"siya@yahoo.com",@"diya@yahoo.com",@"rajesh@gmail.com",@"renu@yahoo.com", nil];
    price=[[NSMutableArray alloc]initWithObjects:@"$20.0",@"$30.44",@"$36.89",@"$89.7",@"$34.87", nil];
    emailArray1=[[NSMutableArray alloc]initWithObjects:@"jinny@gmail.com",@"sita@yahoo.com",@"mahi@yahoo.com",@"rajesh@gmail.com",@"renu@yahoo.com", nil];
    price1=[[NSMutableArray alloc]initWithObjects:@"$240.0",@"$308.44",@"$367.89",@"$839.7",@"$304.87", nil];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:true];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:true];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UILabel *Namelabel;
    UILabel *Emaillabel;
    UILabel *PriceLabel;

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    Namelabel  =[[UILabel alloc]initWithFrame:(CGRectMake(10, 0, 150, 25))];
   
    Namelabel.autoresizesSubviews=YES;
    [Namelabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
    Namelabel.font=[UIFont fontWithName:@"Avenir-Roman" size:12.5];
    
    Emaillabel = [[UILabel alloc]initWithFrame:(CGRectMake(10,15, 200, 30))];
    Emaillabel.autoresizesSubviews=YES;
    [Emaillabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
    [Emaillabel setFont: [UIFont systemFontOfSize:12.0]];
    PriceLabel  =[[UILabel alloc]initWithFrame:(CGRectMake(240, 15, 60, 25))];
    PriceLabel.autoresizesSubviews=YES;
    PriceLabel.textAlignment = NSTextAlignmentRight;
    [PriceLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
    PriceLabel.font=[UIFont fontWithName:@"Avenir-Roman" size:12.5];
    
    if(segmentValue==0)
    {
        Namelabel.text=[Namearray objectAtIndex:indexPath.row] ;
        Emaillabel.text=[emailArray objectAtIndex:indexPath.row];
        PriceLabel.text=[price objectAtIndex:indexPath.row];
    }
    else
    {
        Namelabel.text=[nameArray2 objectAtIndex:indexPath.row] ;
        Emaillabel.text=[emailArray1 objectAtIndex:indexPath.row];
        PriceLabel.text=[price1 objectAtIndex:indexPath.row];
    }
    [cell.contentView addSubview:Namelabel];
    [cell.contentView addSubview:Emaillabel];
    [cell.contentView addSubview:PriceLabel];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    InvoiceDetailViewController *invoice=[[InvoiceDetailViewController alloc]initWithNibName:@"InvoiceDetailViewController" bundle:nil];
    if(segmentValue==0)
    {
        invoice.selectedIndex=0;
    }else
    {
        invoice.selectedIndex=1;
    }
    [self.navigationController pushViewController:invoice animated:YES];
}

- (IBAction)addButton:(id)sender
{
    creditNewInvoiceViewController *credit=[[creditNewInvoiceViewController alloc]initWithNibName:@"creditNewInvoiceViewController" bundle:nil];
    [self.navigationController pushViewController:credit animated:YES];
}

- (IBAction)backButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)segmentButton:(id)sender
{
    segmentValue=(int)_segment.selectedSegmentIndex;
    [_tableView reloadData];
}

-(IBAction)leftDrawerButtonPress:(id)sender
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

@end
