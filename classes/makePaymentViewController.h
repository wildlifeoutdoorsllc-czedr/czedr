//
//  makePaymentViewController.h
//  Czedr
//
//  Created by Renu on 13/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaceholderTextView.h"

@interface makePaymentViewController : UIViewController<UITextFieldDelegate>
{
    NSString *values;
    IBOutlet UIScrollView *scroll;
    UITextField *_pin5;
    UITextView *h;
    NSString *czedrRecipientIdSave;
    IBOutlet UIButton *backbtn;
    NSString*pinstring;
    NSString *message;
    NSString *objid;
    NSString *check_type;
    NSURL *url;
    NSString *amtStrWithFormatter;
    
    NSString *strCzedrRecipientPlaceholder;
    NSString *strAmount;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scroll_view;
@property (strong, nonatomic) IBOutlet UITextField *czedrId;
@property (strong, nonatomic) IBOutlet UITextField *amount;
@property (strong, nonatomic) IBOutlet UIButton *validateButton;
@property (strong, nonatomic) IBOutlet UITextField *pin1;
@property (strong, nonatomic) IBOutlet UITextField *pin2;
@property (strong, nonatomic) IBOutlet UITextField *pin3;
@property (strong, nonatomic) IBOutlet UITextField *pin4;
@property (strong, nonatomic) IBOutlet UIButton *sendInvoice;
- (IBAction)sendInvoice:(id)sender;
- (IBAction)backButton:(id)sender;
@property(strong,nonatomic) NSString *paytoId;
@property (strong, nonatomic) IBOutlet PlaceholderTextView *makePayment;
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UIButton *mkPymntBtn;
@property (weak, nonatomic) IBOutlet UILabel *enterPin;

- (IBAction)make_Payment:(id)sender;

@end
