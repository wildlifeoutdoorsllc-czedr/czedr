//
//  creditNewInvoiceViewController.h
//  payoox
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import <UIKit/UIKit.h>
#import"PlaceholderTextView.h"

@interface creditNewInvoiceViewController : UIViewController<UITextFieldDelegate>
{
    NSString *values;
    IBOutlet UITableView *table;
    NSMutableArray *array;
    UITextField *_pin5;
    NSString *pinstring;
    NSString *czedrRecipientIdSave;
    NSString *message;
    NSString *objid;
    NSURL *url;
    NSString *check_type;
    
    NSString *strCzedrRecipientPlaceholder;
    NSString *strAmount;
    
    NSString *amtStrWithFormatter;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet UITextField *czedrId;
@property (strong, nonatomic) IBOutlet UITextField *amount;
@property (strong, nonatomic) IBOutlet UIButton *validateButton;
@property (strong, nonatomic) IBOutlet UITextField *pin1;
@property (strong, nonatomic) IBOutlet UITextField *pin2;
@property (strong, nonatomic) IBOutlet UITextField *pin3;
@property (strong, nonatomic) IBOutlet UITextField *pin4;
@property (strong, nonatomic) IBOutlet UIButton *sendInvoice;
@property (strong, nonatomic) IBOutlet PlaceholderTextView *makePayment;
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UIButton *sendInvoiceBtn;
@property (weak, nonatomic) IBOutlet UILabel *enterPin;

- (IBAction)sendInvoice:(id)sender;
- (IBAction)backButton:(id)sender;
@end
