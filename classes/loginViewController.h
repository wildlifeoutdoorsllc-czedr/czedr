//
//  loginViewController.h
//  Czedr
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface loginViewController : UIViewController<UITextFieldDelegate>
{
    NSMutableArray *signup_dataArray;
}

@property (weak, nonatomic) IBOutlet UILabel *lblNewUser;
@property (weak, nonatomic) IBOutlet UILabel *lblFillOut;
@property (strong, nonatomic) IBOutlet UITextField *name;
@property (strong, nonatomic) IBOutlet UITextField *emailAddress;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UITextField *confirmPassword;
@property (strong, nonatomic) IBOutlet UITextField *mobileNumber;
@property (strong, nonatomic) IBOutlet UIView *viewDetail;
@property (strong, nonatomic) IBOutlet UIButton *signUp;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

- (IBAction)SignUpButton:(id)sender;
- (IBAction)cancelButton:(id)sender;
@end
