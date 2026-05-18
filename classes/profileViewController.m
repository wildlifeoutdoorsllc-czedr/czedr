//
//  profileViewController.m
//  payoox
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import "profileViewController.h"
#import "CzedrTheme.h"
#import "AsyncImageView.h"
#import "leftSwipeViewController.h"
#import "generalViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+MMDrawerController.h"
#import "SharedServiceController.h"
#import "CzedrAppChrome.h"
#import "CzedrAvatarHelper.h"
#import "MMDrawerVisualState.h"
#import "MMDrawerBarButtonItem.h"
//#import "MGSwipeButton.h"
@interface profileViewController ()

@end

@implementation profileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    NSString *strTitleLbl = NSLocalizedString(@"PROFILE", Nil);
    titleLbl.text = [strTitleLbl uppercaseString];
    
    NSString *strGeneralInfo = NSLocalizedString(@"General info & Settings", Nil);
    generalInfo.text = strGeneralInfo;

    if (linkedCrds && linkedCrds.superview) {
        linkedCrds.superview.hidden = YES;
    }

    _imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped)];
    [_imageView addGestureRecognizer:avatarTap];
}

- (void)avatarTapped
{
    [CzedrAvatarHelper presentFromViewController:self imageView:_imageView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated
{
    [CzedrAppChrome refreshSessionBarForDrawer:self.mm_drawerController];
    [CzedrAppChrome hideLegacyPageHeadersInView:self.view];
    [self czedr_layoutProfileTiles];
    //load the image
    
    namelbl.text=[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"name"];
    emaillbl.text=[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"email "];
    NSURL *urlImage;
    [[AsyncImageLoader sharedLoader].cache removeAllObjects];
    urlImage = [SharedServiceController profileImageURLForStoredName:[[NSUserDefaults standardUserDefaults] valueForKey:@"profile_pic"]];
  
    _imageView.imageURL = urlImage;
   
    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"profile_pic"])
    {
        _imageView.image=[UIImage imageNamed:@"pro_icon.png"];
    }
    _imageView.layer.cornerRadius=_imageView.frame.size.height/2;
    _imageView.userInteractionEnabled = YES;
    _imageView.clipsToBounds = YES;
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"profileclick"] isEqualToString:@"profile"])
    {
        [backbtn setImage:[UIImage imageNamed:@"menu2.png"] forState:UIControlStateNormal];
    }
    [CzedrTheme applyDeckLookToView:self.view];
}

-(void)setRoundedView:(UIImageView *)roundedView toDiameter:(float)newSize;
{
    CGPoint saveCenter = roundedView.center;
    CGRect newFrame = CGRectMake(roundedView.frame.origin.x, roundedView.frame.origin.y, newSize, newSize);
    roundedView.frame = newFrame;
    roundedView.layer.cornerRadius = newSize / 2.0;
    roundedView.center = saveCenter;
}

-(IBAction)leftDrawerButtonPress:(id)sender
{
    if([[[NSUserDefaults standardUserDefaults] valueForKey:@"profileclick"] isEqualToString:@"profile"])
    {
         [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    }
    else
    {
         [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)backButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)czedr_layoutProfileTiles
{
    UIView *tilesHost = nil;
    for (UIView *sub in self.view.subviews) {
        if (sub.subviews.count >= 1 && CGRectGetMinY(sub.frame) > 200) {
            const CGFloat *c = CGColorGetComponents(sub.backgroundColor.CGColor);
            if (CGColorGetNumberOfComponents(sub.backgroundColor.CGColor) >= 3
                && c[0] > 0.45 && c[0] < 0.65 && c[1] > 0.72) {
                tilesHost = sub;
                break;
            }
        }
    }
    if (!tilesHost) {
        return;
    }
    CGFloat top = [CzedrAppChrome topChromeBottomYForView:self.mm_drawerController.view] + 8.0;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height - top - 16.0;
    tilesHost.frame = CGRectMake(0, top + 250.0, width, MAX(160.0, height - 250.0));
    for (UIView *tile in tilesHost.subviews) {
        if (!tile.hidden) {
            tile.frame = CGRectMake(8, 8, width - 16, CGRectGetHeight(tilesHost.frame) - 16);
            tile.autoresizingMask = UIViewAutoresizingNone;
            break;
        }
    }
}

-(IBAction)linkedCard:(id)sender
{
    (void)sender;
}

- (IBAction)generalButton:(id)sender
{
    generalViewController *general=[[generalViewController alloc]initWithNibName:@"generalViewController" bundle:nil];
    [self.navigationController pushViewController:general animated:YES];
}
@end
