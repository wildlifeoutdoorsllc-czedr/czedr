//
//  ViewController.h
//  Czedr
//
//  Created by Renu on 01/01/09.
//  Copyright (c) 2009 Renu. All rights reserved.
//

#import <UIKit/UIKit.h>
NSMutableArray *user_infodata;
@interface ViewController : UIViewController
{
    IBOutlet UIButton *loginbutton;
    IBOutlet UIButton *signupbutton;
    IBOutlet UIButton *forgetbutton;
    
}
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *password;

- (IBAction)loginButton:(id)sender;
- (IBAction)forgotPassword:(id)sender;
- (IBAction)SignUp:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *viewDetail;


@end

