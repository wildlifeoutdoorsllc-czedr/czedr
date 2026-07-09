//
//  forgotViewController.h
//  Czedr
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface forgotViewController : UIViewController
{
    IBOutlet UILabel*forgotlbl;
    IBOutlet UILabel *textlbl;
    
    NSString *strEmailAdrs;
}

@property (strong, nonatomic) IBOutlet UIButton *cancel;
@property (strong, nonatomic) IBOutlet UITextField *emailAddress;
@property (strong, nonatomic) IBOutlet UIButton *ResetPassword;
@property (strong, nonatomic) IBOutlet UIView *Viewdetail1;

- (IBAction)resetPassword:(id)sender;
@end
