//
//  GeneratePinViewController.h
//  Czedr
//
//  Created by Mind Roots New on 29/05/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GeneratePinViewController : UIViewController
{
    NSString *NewPassString;
}
@property (strong, nonatomic) IBOutlet UITextField *pin1;
@property (strong, nonatomic) IBOutlet UITextField *pin2;
@property (strong, nonatomic) IBOutlet UITextField *pin3;
@property (strong, nonatomic) IBOutlet UITextField *pin4;
@property (strong, nonatomic) IBOutlet UITextField *pin5;
@property (strong, nonatomic) IBOutlet UITextField *pin6;
@property (strong, nonatomic) IBOutlet UITextField *pin7;
@property (strong, nonatomic) IBOutlet UITextField *pin8;

@property (strong, nonatomic) IBOutlet UILabel *titleLbl;
@property (strong, nonatomic) IBOutlet UILabel *enterNewLbl;
@property (strong, nonatomic) IBOutlet UILabel *confirmNewLbl;
@property (strong, nonatomic) IBOutlet UIButton *generateBtn;

@end
