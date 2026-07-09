//
//  generalViewController.h
//  Czedr
//
//  Created by Renu on 13/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "HFImageEditorViewController.h"
#import "AsyncImageView.h"
@interface DemoImageEditor : HFImageEditorViewController
@end
@interface generalViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    NSTimer *imageupload_timer;
    NSString *headingTitle;
    UIImagePickerController *imagePickerView;
    NSString *titleAlert;
    UIView *AlerView1;
    UIView *  backView1;
    UIView *  backView;
    IBOutlet UIImageView *profilepic;
    
    IBOutlet UILabel *titleLbl;
    IBOutlet UILabel *nameLbl;
    IBOutlet UILabel *email;
    IBOutlet UILabel *contactNo;
    IBOutlet UILabel *profilePic;
    
    IBOutlet UIButton *updateProfile;
    IBOutlet UIButton *changePwd;
    IBOutlet UIButton *changePin;
    IBOutlet UIButton *ForgotPin;
}

@property (strong, nonatomic) IBOutlet UITextField *name;
@property (strong, nonatomic) IBOutlet UITextField *emailAddress;
@property (strong, nonatomic) IBOutlet UITextField *contactNumber;

- (IBAction)backButton:(id)sender;
-(IBAction)profilebtnClick:(id)sender;

@end
