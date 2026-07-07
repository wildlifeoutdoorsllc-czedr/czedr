//
//  InvoiceDetailViewController.h
//  Czedr
//
//  Created by Renu on 23/02/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InvoiceDetailViewController : UIViewController
{
    IBOutlet UILabel *dollarAmount;
    IBOutlet UILabel *name;
    IBOutlet UILabel *emailuser;
    IBOutlet UILabel *date;
    IBOutlet UILabel *details;
    
    IBOutlet UILabel *titleLbl;
    IBOutlet UILabel *PendingLbl;
    IBOutlet UILabel *detailsLbl;
}

-(IBAction)payNow:(id)sender;
-(IBAction)rejectedInvoice:(id)sender;

@property (strong, nonatomic) IBOutlet UIButton *payNow;
@property (strong, nonatomic) IBOutlet UIButton *rejectInvoice;
@property int selectedIndex;
@end
