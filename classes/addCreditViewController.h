//
//  addCreditViewController.h
//  Czedr
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "NSData+Encryption.h"

@interface NSString (MyAdditions)
- (NSString *)md5;
@end

@interface addCreditViewController : UIViewController<UIImagePickerControllerDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
{
    IBOutlet UILabel *titleBL;
    UIAlertView *aler1;
    NSMutableArray *array;
    NSArray *fetchedObjects;
    BOOL check;
    NSInteger rowfor;
    NSInteger comp;
    NSInteger components;
    NSInteger rowvalue;
    NSString *montString;
    NSString *yearString;
    NSMutableArray *soureYear;
    NSMutableArray *soureMonth;
    NSString *cardid;
    NSString *cvv;
    NSData *encryptedData1;
    NSString *checkValueSet;
    IBOutlet UIButton *addbtn;
    IBOutlet UIButton *deletebtn;
    BOOL checked1;
  //IBOutlet UIDatePicker *datePicker;
    UIPickerView *datePicker;
    IBOutlet UILabel *datelabel;
    UIView *actionView;
    UIImagePickerController *imagePicker;
    UIView *  backView1;
    UIView *  backView;
    NSString *titleAlert;
    UIView *AlerView1;
    NSString *baseImage_16;
    NSString *finalString;
    NSString *encryptedData;
    UIImage *cardImage;
    NSString *all_textfieldValues;
    NSString *newstring;
    
    IBOutlet UILabel *setAsDefault;
}

@property (weak, nonatomic) IBOutlet UIButton *checkBoxButton;
@property (strong, nonatomic) NSString *myString1;
@property (strong, nonatomic) IBOutlet UITextField *name;
@property (strong, nonatomic) IBOutlet UITextField *cardNumber;
@property (strong, nonatomic) IBOutlet UITextField *cvvNumber;
@property(nonatomic,retain) UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIButton *expiryDate;

- (IBAction)backButton:(id)sender;
- (IBAction)datePicker:(id)sender;
- (IBAction)checkBoxButton:(id)sender;
@end
