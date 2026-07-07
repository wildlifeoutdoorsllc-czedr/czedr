//
//  changePasswordViewController.h
//  Czedr
//
//  Created by Mind Roots New on 30/05/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface changePasswordViewController : UIViewController
{
    IBOutlet UITextField *oldpassword;
    IBOutlet UITextField *newpassword;
    IBOutlet UITextField *confirmpassword;
    IBOutlet UILabel *titleLbl;
    IBOutlet UIButton *updatePwd;
}
@end
