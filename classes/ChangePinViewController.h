//
//  ChangePinViewController.h
//  payooxe
//
//  Created by Mind Roots New on 29/05/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import "ViewController.h"

@interface ChangePinViewController : ViewController
{
    NSString *oldString;
    NSString *NewPassString;
    
    IBOutlet UILabel *changeS3Pin;
    IBOutlet UILabel *oldPin;
    IBOutlet UILabel *newPin;
    IBOutlet UILabel *confirmPin;
    IBOutlet UIButton *changePin;
}

@property (strong, nonatomic) IBOutlet UITextField *pin1;
@property (strong, nonatomic) IBOutlet UITextField *pin2;
@property (strong, nonatomic) IBOutlet UITextField *pin3;
@property (strong, nonatomic) IBOutlet UITextField *pin4;
@property (strong, nonatomic) IBOutlet UITextField *pin5;
@property (strong, nonatomic) IBOutlet UITextField *pin6;
@property (strong, nonatomic) IBOutlet UITextField *pin7;
@property (strong, nonatomic) IBOutlet UITextField *pin8;
@property (strong, nonatomic) IBOutlet UITextField *pin9;
@property (strong, nonatomic) IBOutlet UITextField *pin10;
@property (strong, nonatomic) IBOutlet UITextField *pin11;
@property (strong, nonatomic) IBOutlet UITextField *pin12;
@end
