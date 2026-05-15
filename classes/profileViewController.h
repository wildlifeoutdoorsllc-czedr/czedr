//
//  profileViewController.h
//  payoox
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@interface profileViewController : UIViewController
{
    IBOutlet UIButton *backbtn;
    IBOutlet UILabel *namelbl;
    IBOutlet UILabel *emaillbl;
    
    IBOutlet UILabel *titleLbl;
    IBOutlet UILabel *generalInfo;
    IBOutlet UILabel *linkedCrds;
    //AsyncImageView *image;
}

-(IBAction)backButton:(id)sender;
-(IBAction)linkedCard:(id)sender;

@property (nonatomic,strong) IBOutlet UIImageView *imageView;

-(IBAction)generalButton:(id)sender;
@end
