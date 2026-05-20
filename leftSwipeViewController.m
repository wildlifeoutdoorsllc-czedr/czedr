//
//  leftSwipeViewController.m
//  payooxe
//
//  Created by Renu on 01/01/09.
//  Copyright (c) 2009 Renu. All rights reserved.
//

#import "leftSwipeViewController.h"
#import "CzedrTheme.h"
#import "pendingInvoicesViewController.h"
#import "historyViewController.h"
#import "profileViewController.h"
#import "makePaymentViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "MMDrawerVisualState.h"
#import "MMDrawerBarButtonItem.h"
#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"
#import "SharedServiceController.h"
#import "addCreditViewController.h"
#import "CzedrAppChrome.h"
#import <CoreData/CoreData.h>
@interface leftSwipeViewController ()
{
     NSManagedObjectContext *managedObjectContext;
     BOOL _homeDataLoaded;
}
@end

@implementation leftSwipeViewController

- (NSString *)czedr_formattedCzedrIdLine
{
    NSString *czedrId = [SharedServiceController savedCzedrUserId] ?: @"";
    NSString *strYourId = NSLocalizedString(@"Your Czedr ID", Nil);
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"?";
    return [NSString stringWithFormat:@"%@ - %@  ·  Build %@", strYourId, czedrId, build];
}

- (void)czedr_refreshCzedrIdLabel
{
    if (czedrIdLabel) {
        czedrIdLabel.text = [self czedr_formattedCzedrIdLine];
        czedrIdLabel.textColor = [CzedrTheme captionOnDark];
        czedrIdLabel.textAlignment = NSTextAlignmentCenter;
    }
}

- (void)czedr_styleHomeTile:(UIView *)tile width:(CGFloat)tileW height:(CGFloat)tileH
{
    if (!tile) {
        return;
    }
    [CzedrTheme styleGridTile:tile];
    tile.autoresizingMask = UIViewAutoresizingNone;
    for (UIView *sub in tile.subviews) {
        sub.autoresizingMask = UIViewAutoresizingNone;
        if ([sub isKindOfClass:[UIImageView class]]) {
            CGFloat iconW = MIN(96.0, tileW - 36.0);
            CGFloat iconH = MIN(78.0, tileH - 44.0);
            sub.frame = CGRectMake((tileW - iconW) / 2.0, 10.0, iconW, iconH);
            ((UIImageView *)sub).contentMode = UIViewContentModeScaleAspectFit;
        } else if ([sub isKindOfClass:[UILabel class]]) {
            UILabel *tileLabel = (UILabel *)sub;
            tileLabel.textColor = [UIColor whiteColor];
            tileLabel.backgroundColor = [UIColor clearColor];
            sub.frame = CGRectMake(4.0, tileH - 30.0, tileW - 8.0, 26.0);
        } else if ([sub isKindOfClass:[UIButton class]]) {
            sub.frame = CGRectMake(0, 0, tileW, tileH);
        }
    }
}

- (void)czedr_bringHomeContentToFront
{
    if (self.legacyHeaderView) {
        self.legacyHeaderView.hidden = YES;
    }
    if (self.homeLogoImageView) {
        self.homeLogoImageView.hidden = YES;
    }
    if (self.homeTilesContainer) {
        [self.view bringSubviewToFront:self.homeTilesContainer];
    }
    if (self.homeBalanceCaptionLabel) {
        [self.view bringSubviewToFront:self.homeBalanceCaptionLabel];
    }
    if (self.homeBalanceLabel) {
        [self.view bringSubviewToFront:self.homeBalanceLabel];
    }
    if (czedrIdLabel) {
        [self.view bringSubviewToFront:czedrIdLabel];
    }
    if (self.referralEarningsBtn) {
        [self.view bringSubviewToFront:self.referralEarningsBtn];
    }
}

- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *strTitleLbl = NSLocalizedString(@"Home", Nil);
    _titleLbl.text = strTitleLbl;
    
    NSString *strMkPymnt = NSLocalizedString(@"Make Payments", Nil);
    _mkPymntLbl.text = strMkPymnt;
    
    NSString *strPndingInvoics = NSLocalizedString(@"Pending Invoices", Nil);
    _pndingInvoicsLbl.text = strPndingInvoics;
    
    NSString *strHistryLbl = NSLocalizedString(@"History", Nil);
    _histryLbl.text = strHistryLbl;
    
    NSString *strMyProfile = NSLocalizedString(@"My Profile", Nil);
    _myProfileLbl.text = strMyProfile;
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(call_loadCardsService)
                                                 name:@"call_cardcount"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(czedr_userDidLogin:)
                                                 name:CzedrUserDidLoginNotification
                                               object:nil];
    NSString *autcode=[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"];
    [[NSUserDefaults standardUserDefaults] setValue:@"store_databse" forKey:@"update_value"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self czedr_refreshCzedrIdLabel];
    
    [self.referralEarningsBtn setTitle:NSLocalizedString(@"Referral earnings", nil) forState:UIControlStateNormal];
    [self syncReferralEarningsUIWithAuthToken:autcode ?: @""];

    if (self.legacyHeaderView) {
        self.legacyHeaderView.hidden = YES;
    }
    if (countlable) {
        countlable.hidden = YES;
        countlable.text = @"";
    }
    if (self.homeTilesContainer) {
        self.homeTilesContainer.autoresizingMask = UIViewAutoresizingNone;
    }
    if (self.homeLogoImageView) {
        self.homeLogoImageView.hidden = YES;
    }
    if (self.homeTilesContainer) {
        self.homeTilesContainer.backgroundColor = [UIColor clearColor];
        for (UIView *tile in self.homeTilesContainer.subviews) {
            [self czedr_styleHomeTile:tile width:120 height:118];
        }
    }
    if (self.homeBalanceCaptionLabel) {
        self.homeBalanceCaptionLabel.text = NSLocalizedString(@"Available balance", nil);
        self.homeBalanceCaptionLabel.textAlignment = NSTextAlignmentCenter;
        [CzedrTheme styleHomeBalanceCaptionLabel:self.homeBalanceCaptionLabel];
        self.homeBalanceCaptionLabel.font = [CzedrTheme avenir:15.0 weight:@"heavy"];
        self.homeBalanceCaptionLabel.hidden = NO;
    }
    if (self.homeBalanceLabel) {
        self.homeBalanceLabel.text = @"";
        self.homeBalanceLabel.textAlignment = NSTextAlignmentCenter;
        [CzedrTheme styleHomeBalanceAmountLabel:self.homeBalanceLabel];
        self.homeBalanceLabel.font = [CzedrTheme avenir:24.0 weight:@"heavy"];
        self.homeBalanceLabel.adjustsFontSizeToFitWidth = YES;
        self.homeBalanceLabel.minimumScaleFactor = 0.7;
        self.homeBalanceLabel.backgroundColor = [UIColor clearColor];
        self.homeBalanceLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *balanceTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(czedr_balanceTapped:)];
        [self.homeBalanceLabel addGestureRecognizer:balanceTap];
    }
    
    if (autcode.length==0)
    {
        ViewController *ViewController_O=[[ViewController alloc]initWithNibName:@"ViewController" bundle:nil];
        ViewController_O.hidesBottomBarWhenPushed=YES;
        [self.mm_drawerController setOpenDrawerGestureModeMask:(MMOpenDrawerGestureModeNone)];
        [self.navigationController pushViewController:ViewController_O animated:NO];
    }
}

- (void)czedr_userDidLogin:(NSNotification *)notification
{
    (void)notification;
    _homeDataLoaded = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.isViewLoaded) {
            return;
        }
        NSString *tok = [[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] ?: @"";
        [strongSelf czedr_refreshCzedrIdLabel];
        [strongSelf syncReferralEarningsUIWithAuthToken:tok];
        [strongSelf call_loadCardsService];
        [CzedrAppChrome refreshSessionBarForDrawer:strongSelf.mm_drawerController];
    });
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    payNowBool = false;
    self.navigationController.navigationBar.hidden=YES;
    [CzedrTheme applyLoggedInDarkScreenToView:self.view];
    if (_titleLbl) {
        _titleLbl.textColor = [CzedrTheme lightText];
        _titleLbl.backgroundColor = [UIColor clearColor];
    }
    if (czedrIdLabel) {
        czedrIdLabel.textColor = [CzedrTheme captionOnDark];
    }
    if (self.homeBalanceCaptionLabel) {
        [CzedrTheme styleHomeBalanceCaptionLabel:self.homeBalanceCaptionLabel];
    }
    if (self.homeBalanceLabel) {
        [CzedrTheme styleHomeBalanceAmountLabel:self.homeBalanceLabel];
    }
    NSString *tok = [[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] ?: @"";
    [self syncReferralEarningsUIWithAuthToken:tok];
    [[NSUserDefaults standardUserDefaults]setValue:nil forKey:@"pmakepaymentclick"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [CzedrAppChrome refreshSessionBarForDrawer:self.mm_drawerController];
    [self czedr_layoutHomeHeader];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_homeDataLoaded) {
        return;
    }
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"auth_codeSaved"].length == 0) {
        return;
    }
    _homeDataLoaded = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && strongSelf.isViewLoaded) {
            [strongSelf call_loadCardsService];
        }
    });
}

- (CGFloat)czedr_topChromeBottomY
{
    MMDrawerController *drawer = self.mm_drawerController;
    if (drawer) {
        return [CzedrAppChrome topChromeBottomYForView:drawer.view];
    }
    if (@available(iOS 11.0, *)) {
        return self.view.safeAreaInsets.top;
    }
    return 0;
}

- (void)czedr_layoutHomeTilesAtGridTop:(CGFloat)gridTop width:(CGFloat)width tileW:(CGFloat)tileW tileH:(CGFloat)tileH
{
    if (!self.homeTilesContainer) {
        return;
    }
    const CGFloat gap = 10.0;
    CGFloat gridH = gap + tileH + gap + tileH + gap;

    self.homeTilesContainer.frame = CGRectMake(0, gridTop, width, gridH);
    self.homeTilesContainer.autoresizingMask = UIViewAutoresizingNone;
    self.homeTilesContainer.backgroundColor = [UIColor clearColor];

    NSArray<UIView *> *tiles = self.homeTilesContainer.subviews;
    if (tiles.count < 4) {
        return;
    }
    UIView *tl = tiles[0];
    UIView *tr = tiles[1];
    UIView *bl = tiles[2];
    UIView *br = tiles[3];
    tl.frame = CGRectMake(gap, gap, tileW, tileH);
    tr.frame = CGRectMake(gap + tileW + gap, gap, tileW, tileH);
    bl.frame = CGRectMake(gap, gap + tileH + gap, tileW, tileH);
    br.frame = CGRectMake(gap + tileW + gap, gap + tileH + gap, tileW, tileH);
    [self czedr_styleHomeTile:tl width:tileW height:tileH];
    [self czedr_styleHomeTile:tr width:tileW height:tileH];
    [self czedr_styleHomeTile:bl width:tileW height:tileH];
    [self czedr_styleHomeTile:br width:tileW height:tileH];
}

- (void)czedr_layoutHomeHeader
{
    if (!self.isViewLoaded || self.view.bounds.size.width < 1.0) {
        return;
    }
    CGFloat width = self.view.bounds.size.width;
    CGFloat viewH = self.view.bounds.size.height;

    if (self.homeLogoImageView) {
        self.homeLogoImageView.hidden = YES;
    }

    if (czedrIdLabel) {
        CGFloat idY = [self czedr_topChromeBottomY] + 10.0;
        czedrIdLabel.frame = CGRectMake(16.0, idY, width - 32.0, 22.0);
        czedrIdLabel.textAlignment = NSTextAlignmentCenter;
    }

    CGFloat btnH = 48.0;
    CGFloat btnY = viewH - btnH;
    if (@available(iOS 11.0, *)) {
        btnY -= self.view.safeAreaInsets.bottom;
    }
    if (self.referralEarningsBtn && !self.referralEarningsBtn.hidden) {
        self.referralEarningsBtn.frame = CGRectMake(0, btnY, width, btnH);
        [CzedrTheme styleRedPrimaryButton:self.referralEarningsBtn];
    } else {
        btnY = viewH;
        if (@available(iOS 11.0, *)) {
            btnY -= self.view.safeAreaInsets.bottom;
        }
    }

    const CGFloat gap = 10.0;
    CGFloat tileW = floor((width - gap * 3.0) / 2.0);
    CGFloat tileH = MIN(tileW, 118.0);
    tileH = MAX(96.0, tileH);
    CGFloat gridH = gap + tileH + gap + tileH + gap;
    CGFloat tilesBottom = btnY - 8.0;
    CGFloat gridTop = tilesBottom - gridH;

    CGFloat balanceBottom = gridTop - 12.0;
    if (self.homeBalanceLabel) {
        self.homeBalanceLabel.frame = CGRectMake(16.0, balanceBottom - 34.0, width - 32.0, 34.0);
    }
    if (self.homeBalanceCaptionLabel) {
        CGFloat captionY = self.homeBalanceLabel
            ? CGRectGetMinY(self.homeBalanceLabel.frame) - 24.0
            : balanceBottom - 20.0;
        self.homeBalanceCaptionLabel.frame = CGRectMake(16.0, captionY, width - 32.0, 20.0);
    }

    [self czedr_layoutHomeTilesAtGridTop:gridTop width:width tileW:tileW tileH:tileH];
    [self czedr_bringHomeContentToFront];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [CzedrAppChrome refreshSessionBarForDrawer:self.mm_drawerController];
    [self czedr_layoutHomeHeader];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    //Dispose of any resources that can be recreated.
}

- (IBAction)pendingButton:(id)sender
{
    [[NSUserDefaults standardUserDefaults]setValue:nil forKey:@"pendingclick"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    pendingInvoicesViewController *pending=[[pendingInvoicesViewController alloc]initWithNibName:@"pendingInvoicesViewController" bundle:nil];
        [self.navigationController pushViewController:pending animated:YES];
}

-(IBAction)leftDrawerButtonPress:(id)sender
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)makePaymentButton:(id)sender
{
    [[NSUserDefaults standardUserDefaults]setValue:nil forKey:@"pmakepaymentclick"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    makePaymentViewController *make=[[makePaymentViewController alloc]initWithNibName:@"makePaymentViewController" bundle:nil];
    [self.navigationController pushViewController:make animated:YES];
}

- (IBAction)historyButton:(id)sender
{
    [[NSUserDefaults standardUserDefaults]setValue:nil
                                            forKey:@"historyclick"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    historyViewController *history=[[historyViewController alloc]initWithNibName:@"historyViewController" bundle:nil];
    [self.navigationController pushViewController:history animated:YES];
}

- (IBAction)profileButton:(id)sender
{
    [[NSUserDefaults standardUserDefaults]setValue:nil forKey:@"profileclick"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    profileViewController *profile=[[profileViewController alloc]initWithNibName:@"profileViewController" bundle:nil];
    [self.navigationController pushViewController:profile animated:YES];
}

- (void)syncReferralEarningsUIWithAuthToken:(NSString *)token
{
    BOOL v1 = [SharedServiceController usesV1API];
    BOOL authed = token.length > 0;
    self.referralEarningsBtn.hidden = !(v1 && authed);
    if (self.referralEarningsBtn && v1 && authed) {
        [CzedrTheme styleRedPrimaryButton:self.referralEarningsBtn];
    }
}

- (IBAction)referralEarningsButton:(id)sender
{
    [self showReferralEarnings];
}

-(void)call_CardcountService
{
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int reach = [reachAbilty updateInterfaceWithReachability];
    if (reach==0){
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else if ([SharedServiceController usesV1API])
    {
        [SharedServiceController fetchReceivedInvoicesOffset:0 limit:8
            success:^(NSArray *rows, NSInteger total) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if (countlable) {
                    countlable.text = [NSString stringWithFormat:@"%ld pending", (long)total];
                }
            }
            failure:^(NSString *message) {
                (void)message;
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if (countlable) {
                    countlable.text = @"";
                }
            }];
    }
    else
    {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        NSString *autcode=[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:autcode forKey:@"auth_code"];
        [params setValue:@"0" forKey:@"offset"];
        [params setValue:@"8" forKey:@"limit"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"invoicerecev"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 
             }
             else
             {
                countlable.text=@"0";
             }
         }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
        
//                  NSString *strErrorMsg = NSLocalizedString(@"error", Nil);
//                  NSString *strOk = NSLocalizedString(@"OK", Nil);
//                  
//                  UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strErrorMsg delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
//                  [alert show];
              }];
    }
}

-(void)recevied_service
{
   // [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int reach = [reachAbilty updateInterfaceWithReachability];
    if (reach==0){
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else if ([SharedServiceController usesV1API])
    {
        [SharedServiceController fetchReceivedInvoicesOffset:1 limit:8
            success:^(NSArray *rows, NSInteger total) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                countlable.text = [NSString stringWithFormat:@"%ld", (long)total];
            }
            failure:^(NSString *message) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                countlable.text = @"0";
            }];
    }
    else
    {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        NSString* authCodeStr =[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:authCodeStr forKey:@"auth_code"];
        [params setValue:@"0" forKey:@"offset"];
        [params setValue:@"8" forKey:@"limit"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"invoicerecev"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                
                NSString * receve_totalcount=[[response JSONValue] valueForKey:@"Total_rows"];
                 countlable.text=receve_totalcount;
                 
             }
             else
             {
               countlable.text=@"0";
            }
             [MBProgressHUD hideHUDForView:self.view animated:YES];
         }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
              }];
    }
    
}
-(void)call_loadCardsService
{
    if ([SharedServiceController usesV1API]) {
        [self czedr_refreshCzedrIdLabel];
        __weak typeof(self) weakSelf = self;
        [SharedServiceController fetchLedgerBalanceSuccess:^(NSDictionary *data) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || !strongSelf.isViewLoaded) {
                return;
            }
            NSInteger cents = [[data objectForKey:@"balance_cents"] integerValue];
            float dollars = cents / 100.0f;
            if (strongSelf.homeBalanceLabel) {
                strongSelf.homeBalanceLabel.text = [NSString stringWithFormat:@"$%.2f", dollars];
                [CzedrTheme styleHomeBalanceAmountLabel:strongSelf.homeBalanceLabel];
            }
            [strongSelf czedr_layoutHomeHeader];
            [MBProgressHUD hideHUDForView:strongSelf.view animated:YES];
        } failure:^(NSString *message) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            (void)message;
            if (strongSelf && strongSelf.isViewLoaded) {
                [MBProgressHUD hideHUDForView:strongSelf.view animated:YES];
            }
        }];
        return;
    }

    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int reach = [reachAbilty updateInterfaceWithReachability];
    if (reach==0){
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else{
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        NSString *autcode=[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"]];
        [params setValue:autcode forKey:@"auth_code"];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"creditcarddetail"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 array=[[NSMutableArray alloc]init];
                 array=[[response JSONValue] valueForKey:@"Data"];
                 
                 [self checkdatabase_count];
             }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 if ([Alertstatus isEqualToString:@"authcode expired"])
                 {
                     NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                     
                    if([language isEqual:@"fr"])
                    {
                        if ([Alertstatus isEqual:@"authcode expired"])
                        {
                            Alertstatus = @"code d'autorisation expiré";
                        }
                        else if ([Alertstatus isEqual:@"No Card Detail"])
                        {
                            Alertstatus = @"Pas de carte détaillée";
                        }
                    }
 
                 }
                 else
                 {
                     NSString *strAlert = NSLocalizedString(@"Alert", Nil);
                     NSString *strNotLinkedCards = NSLocalizedString(@"not linked any cards", Nil);
                     NSString *strOk = NSLocalizedString(@"OK", Nil);

                     UIAlertView *alert=[[UIAlertView alloc]initWithTitle:strAlert message:strNotLinkedCards delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                     [alert show];
                 }
             }
         }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
                 
//                  NSString *strErrorMsg = NSLocalizedString(@"error", Nil);
//                  NSString *strOk = NSLocalizedString(@"OK", Nil);
//                  
//                  UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strErrorMsg delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
//                  [alert show];
              }];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    addCreditViewController *add=[[addCreditViewController alloc]initWithNibName:@"addCreditViewController" bundle:nil];
    [self.navigationController pushViewController:add animated:YES];
}

-(void)checkdatabase_count
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    if (context == nil) {
//        NSLog(@"Nil");
    }
    else {
        
        NSError *error;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cards" inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        
        fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects.count==0) {
            
        }
        else
        {
            for (int i=0; i<fetchedObjects.count; i++)
            {
//                NSLog(@"%lu",(unsigned long)fetchedObjects.count);
//                NSLog(@"%@",[[fetchedObjects objectAtIndex:i] valueForKey:@"name"]);
            }
            
        }
    }
    NSUInteger fetchedCount = fetchedObjects ? fetchedObjects.count : 0;
    NSUInteger arrayCount = array ? array.count : 0;
    if (fetchedCount == arrayCount)
    {
        if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"update_value"] isEqualToString:@"store_databse"])
        {
           //[self update_quary];
             [self store_indabase];
        }
    }
    else
    {
       [self store_indabase];
    }
    
}
-(void)update_quary
{
    NSError *error;
    managedObjectContext = [self managedObjectContext];
    NSFetchRequest * Brand = [[NSFetchRequest alloc] initWithEntityName:@"Cards"];
    NSString * saveindex=[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"save_index"]];
    NSPredicate *pred =[NSPredicate predicateWithFormat:@"id=%@",[[array objectAtIndex:[saveindex intValue]] valueForKey:@"id"]];
    [Brand setPredicate:pred];
    NSArray * array1 = [managedObjectContext executeFetchRequest:Brand error:&error];
    self.device=[array1 objectAtIndex:0];
    for (int i=0; i<[array1 count]; i++)
    {
        [self.device setValue:[[array objectAtIndex:i]valueForKey:@"card_default"] forKey:@"card_default"];
        [self.device setValue:[[array objectAtIndex:i]valueForKey:@"cardnumber"] forKey:@"cardnumber"];
        [self.device setValue:[[array objectAtIndex:i]valueForKey:@"id"] forKey:@"id"];
        [self.device setValue:[[array objectAtIndex:i]valueForKey:@"month"] forKey:@"month"];
        [self.device setValue:[[array objectAtIndex:i]valueForKey:@"name"] forKey:@"name"];
        [self.device setValue:[[array objectAtIndex:i]valueForKey:@"year"] forKey:@"year"];
    }
    [managedObjectContext save:&error];
    if (![managedObjectContext save:&error])
    {
//      NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

-(void)store_indabase
{
    managedObjectContext = [self managedObjectContext];
    if (managedObjectContext == nil) {
        return;
    }
    NSError *error;
    NSFetchRequest * Brand = [[NSFetchRequest alloc] init];
    [Brand setEntity:[NSEntityDescription entityForName:@"Cards" inManagedObjectContext:managedObjectContext]];
    [Brand setIncludesPropertyValues:NO];
    NSArray * array1 = [managedObjectContext executeFetchRequest:Brand error:&error];
    for (NSManagedObject * car in array1)
    {
        [managedObjectContext deleteObject:car];
    }
    for (int i=0; i<[array count]; i++)
    {
        managedObjectContext = [self managedObjectContext];
        NSManagedObject *reminder_Object = [NSEntityDescription insertNewObjectForEntityForName:@"Cards"inManagedObjectContext:managedObjectContext];
        [reminder_Object setValue:[[array objectAtIndex:i]valueForKey:@"card_default"] forKey:@"card_default"];
        [reminder_Object setValue:[[array objectAtIndex:i]valueForKey:@"cardnumber"] forKey:@"cardnumber"];
        [reminder_Object setValue:[[array objectAtIndex:i]valueForKey:@"id"] forKey:@"id"];
        [reminder_Object setValue:[[array objectAtIndex:i]valueForKey:@"month"] forKey:@"month"];
        [reminder_Object setValue:[[array objectAtIndex:i]valueForKey:@"name"] forKey:@"name"];
        [reminder_Object setValue:[[array objectAtIndex:i]valueForKey:@"year"] forKey:@"year"];
        [managedObjectContext save:&error];
    }
    
    if (![managedObjectContext save:&error])
    {
//        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"update_value"] isEqualToString:@"store_databse"])
    {
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"update_value"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self checkdatabase_count];
    }
}
- (void)sessionLogout:(id)sender
{
    (void)sender;
    [CzedrAppChrome logoutFromViewController:self drawer:self.mm_drawerController];
}

- (void)sessionMinimize:(id)sender
{
    (void)sender;
    [CzedrAppChrome minimizeFromViewController:self drawer:self.mm_drawerController];
}

- (void)sessionMaximize:(id)sender
{
    (void)sender;
    [CzedrAppChrome maximizeFromViewController:self drawer:self.mm_drawerController];
}

- (void)sessionExit:(id)sender
{
    (void)sender;
    [CzedrAppChrome exitFromViewController:self drawer:self.mm_drawerController];
}

- (void)showReferralEarnings
{
    if (![SharedServiceController usesV1API]) { return; }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [SharedServiceController fetchReferralEarningsSuccess:^(NSDictionary *data) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSInteger total = [[data objectForKey:@"referral_earnings_total_cents"] integerValue];
        NSInteger cnt = [[data objectForKey:@"referral_payment_count"] integerValue];
        float usd = total / 100.f;
        NSString *title = NSLocalizedString(@"Referral earnings", nil);
        NSString *msg = [NSString stringWithFormat:@"Total from referrals: $%.2f (%ld referee payments).\n\nThese credits are already included in your Czedr balance.", usd, (long)cnt];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } failure:^(NSString *message) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)czedr_balanceTapped:(UITapGestureRecognizer *)gesture
{
    (void)gesture;
    if (![SharedServiceController usesV1API]) {
        return;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [SharedServiceController fetchFundingStatusSuccess:^(NSDictionary *data) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        BOOL enabled = [[data objectForKey:@"enabled"] boolValue];
        BOOL ready = [[data objectForKey:@"moov_ready"] boolValue];
        NSArray *banks = [data objectForKey:@"banks"];
        NSInteger bankCount = [banks isKindOfClass:[NSArray class]] ? banks.count : 0;
        NSString *title = NSLocalizedString(@"Add money", nil);
        NSString *msg;
        if (!enabled || !ready) {
            msg = NSLocalizedString(@"Bank transfers (ACH) are not available yet on this server. Use transfers from another Czedr user, or ask support to enable Moov funding.", nil);
        } else if (bankCount == 0) {
            msg = NSLocalizedString(@"Link your bank first (coming soon in this build). See docs/MOOV-ACH-FUNDING.md on the server.", nil);
        } else {
            NSInteger minC = [[data objectForKey:@"min_deposit_cents"] integerValue];
            NSInteger maxC = [[data objectForKey:@"max_deposit_cents"] integerValue];
            msg = [NSString stringWithFormat:NSLocalizedString(@"ACH deposit UI is in progress. You have %ld linked bank(s). Limits: $%.2f – $%.2f per deposit.", nil),
                   (long)bankCount, minC / 100.0, maxC / 100.0];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } failure:^(NSString *message) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if ([message containsString:@"503"] || [message rangeOfString:@"not configured" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            NSString *title = NSLocalizedString(@"Add money", nil);
            NSString *msg = NSLocalizedString(@"ACH funding is not configured on this server yet.", nil);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

@end
