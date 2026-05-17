//
//  leftViewController.m
//  3pL app
//
//  Created by Mind Roots Technologies on 11/09/13.
//  Copyright (c) 2013 Mind Roots Technologies. All rights reserved.
//

#import "leftViewController.h"
#import "CzedrTheme.h"
#import "loginViewController.h"
#import "creditNewInvoiceViewController.h"
#import "makePaymentViewController.h"
#import "historyViewController.h"
#import "leftSwipeViewController.h"
#import "profileViewController.h"
#import "pendingInvoicesViewController.h"
#import "makePaymentViewController.h"
#import "pendingViewController.h"

#import "AppDelegate.h"
#import "SharedServiceController.h"
#import "CzedrAppChrome.h"
@interface leftViewController ()

@end

@implementation leftViewController
@synthesize tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];

    if ([language  isEqual: @"fr"])
    {
      listOfArray=[[NSMutableArray alloc]initWithObjects:@"DOMICILE",@"PROFIL",@"FACTURES",@"EFFECTUER LE PAIEMENT",@"RELEVÉ",@"SE DÉCONNECTER",nil];
    }
    else
    {
      listOfArray=[[NSMutableArray alloc]initWithObjects:@"HOME",@"PROFILE",@"INVOICES",@"MAKE PAYMENT",@"HISTORY",@"LOGOUT",nil];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    _imageView.clipsToBounds = YES;
    [self setRoundedView:_imageView toDiameter:60.0];
    namelbl.text=[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"name"];
    [AsyncImageLoader sharedLoader].cache = nil;

    _imageView.imageURL = [SharedServiceController profileImageURLForStoredName:[[NSUserDefaults standardUserDefaults] valueForKey:@"profile_pic"]];
    
    
    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"profile_pic"])
    {
        _imageView.image=[UIImage imageNamed:@"pro_icon.png"];
    }
    [CzedrTheme applyDeckLookToView:self.view];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setRoundedView:(UIImageView *)roundedView toDiameter:(float)newSize;
{
    CGPoint saveCenter = roundedView.center;
    CGRect newFrame = CGRectMake(roundedView.frame.origin.x, roundedView.frame.origin.y, newSize, newSize);
    roundedView.frame = newFrame;
    roundedView.layer.cornerRadius = newSize / 2.0;
    roundedView.center = saveCenter;
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return listOfArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableVieww cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    tableView.backgroundColor=[UIColor colorWithRed:50.0/255 green:50.0/255 blue:50.0/255 alpha:1.0];

    UITableViewCell *cell = [tableVieww dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.selected=NO;
    cell.backgroundColor=[UIColor colorWithRed:50.0/255 green:50.0/255 blue:50.0/255 alpha:1.0];
    cell.imageView.image=[UIImage imageNamed:[listOfArrayImages objectAtIndex:indexPath.row]];
    cell.textLabel.text=[listOfArray objectAtIndex:indexPath.row];

    cell.textLabel.font=[UIFont fontWithName:@"Avenir" size:13.0];
    cell.textLabel.textColor=[UIColor whiteColor];
    CALayer *separator = [CALayer layer];
    separator.backgroundColor = [UIColor blackColor].CGColor;
    separator.frame = CGRectMake(-5, 44, self.view.frame.size.width+5, .9);
    [cell.layer addSublayer:separator];

    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case 0:
        {
           leftSwipeViewController *left=[[leftSwipeViewController alloc]initWithNibName:@"leftSwipeViewController" bundle:nil];
            _nav = [[UINavigationController alloc] initWithRootViewController:left];
            _nav.navigationBarHidden=YES;
            [self.mm_drawerController setCenterViewController:_nav withCloseAnimation:YES
                                                   completion:nil];
        }
        break;
        case 1:
        {
            profileViewController *profile=[[profileViewController alloc]initWithNibName:@"profileViewController" bundle:nil];
            _nav = [[UINavigationController alloc] initWithRootViewController:profile];
            _nav.navigationBarHidden=YES;
            [[NSUserDefaults standardUserDefaults]setValue:@"profile" forKey:@"profileclick"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.mm_drawerController setCenterViewController:_nav withCloseAnimation:YES
                                                   completion:nil];
        }
        break;
        case 2:
        {
            [[NSUserDefaults standardUserDefaults]setValue:@"pending" forKey:@"pendingclick"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            pendingInvoicesViewController *pending=[[pendingInvoicesViewController alloc]initWithNibName:@"pendingInvoicesViewController" bundle:nil];
            [self.navigationController pushViewController:pending animated:YES];
            
            _nav = [[UINavigationController alloc] initWithRootViewController:pending];
            _nav.navigationBarHidden=YES;
            [self.mm_drawerController setCenterViewController:_nav withCloseAnimation:YES completion:nil];
        }
        break;
        case 3:
        {
            [[NSUserDefaults standardUserDefaults]setValue:@"makepayment" forKey:@"pmakepaymentclick"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            makePaymentViewController *payment=[[makePaymentViewController alloc]initWithNibName:@"makePaymentViewController" bundle:nil];
            _nav = [[UINavigationController alloc] initWithRootViewController:payment];
            _nav.navigationBarHidden=YES;
            [self.mm_drawerController setCenterViewController:_nav withCloseAnimation:YES completion:nil];
        }
        break;
        case 4:
        {
            [[NSUserDefaults standardUserDefaults]setValue:@"history" forKey:@"historyclick"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            historyViewController *history=[[historyViewController alloc]initWithNibName:@"historyViewController" bundle:nil];
            [self.navigationController pushViewController:history animated:YES];
            _nav = [[UINavigationController alloc] initWithRootViewController:history];
            _nav.navigationBarHidden=YES;
            [self.mm_drawerController setCenterViewController:_nav withCloseAnimation:YES completion:nil];
        }
            break;
        case 5:
        {
            [CzedrAppChrome logoutFromViewController:self drawer:self.mm_drawerController];
        }
            break;
//              case 6:
//        {
//            [[NSUserDefaults standardUserDefaults] setValue:@"0" forKey:@"Avalue"];
//            [[NSUserDefaults standardUserDefaults]synchronize];
//            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
////             [appDelegate mainViewSwitch];
//        }
//            break;
        default:
            break;
    }
}

-(void)logoutservice
{
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int reach = [reachAbilty updateInterfaceWithReachability];
    if (reach==0)
    {
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else
    {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        
        NSString *email=[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"]valueForKey:@"email "];
        
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] forKey:@"auth_code"];
         [params setValue:email forKey:@"user_email"];
        
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"logout"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"])
             {
                 [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"auth_codeSaved"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"userDataArray"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 ViewController *view=[[ViewController alloc]initWithNibName:@"ViewController" bundle:nil];
                 _nav = [[UINavigationController alloc] initWithRootViewController:view];
                 _nav.navigationBarHidden=YES;
                 [self.mm_drawerController setCenterViewController:_nav withCloseAnimation:YES
                                                        completion:nil];
             }
             else
             {
                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
                 
                NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
                 
                if([language isEqual:@"fr"])
                {
                    if ([Alertstatus isEqual:@"Data is missing"])
                    {
                        Alertstatus = @"Données manquantes";
                    }
                }

                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                
                 [alert show];
                 return;
             }
         }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
              
                  NSString *strErrorMsg = NSLocalizedString(@"error", Nil);
                  NSString *strOk = NSLocalizedString(@"OK", Nil);
                  
                  UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:strErrorMsg delegate:nil cancelButtonTitle:strOk otherButtonTitles:nil, nil];
                  [alert show];
              }];
    }
}

-(void)parse_logout
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    ReachabiltyTest *reachAbilty = [[ReachabiltyTest alloc]init];
    int reach = [reachAbilty updateInterfaceWithReachability];
    if (reach==0)
    {
        NSString *strAttention = NSLocalizedString(@"Attention", Nil);
        NSString *strYourNetwork = NSLocalizedString(@"Your network", Nil);
        NSString *strOk = NSLocalizedString(@"OK", Nil);
        
        UIAlertView *alertview=[[UIAlertView alloc]initWithTitle:strAttention message:strYourNetwork delegate:self cancelButtonTitle:strOk otherButtonTitles:nil, nil];
        [alertview performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else
    {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"] forKey:@"auth_code"];
        [params setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"objectId"] forKey:@"obj_token"];
        
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:[NSString stringWithFormat:@"%s/%s",base_url,"unregisteredtoken"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *response;
             response = [NSString stringWithFormat:@"%@",operation.responseString];
             NSString *status=[NSString stringWithFormat:@"%@",[[response JSONValue] valueForKey:@"Status"]];
             if ([status isEqualToString:@"true"]) {
                 
                 [self logoutservice];
             }
             else {
                 
                 [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"auth_codeSaved"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"userDataArray"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 ViewController *view=[[ViewController alloc]initWithNibName:@"ViewController" bundle:nil];
                 _nav = [[UINavigationController alloc] initWithRootViewController:view];
                 _nav.navigationBarHidden=YES;
                 [self.mm_drawerController setCenterViewController:_nav withCloseAnimation:YES completion:nil];
                 
//                 NSString *Alertstatus=[NSString stringWithFormat:@"%@",[[[[response JSONValue] valueForKey:@"Data"] objectAtIndex:0]valueForKey:@"result"]];
//                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"" message:Alertstatus delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//                 [alert show];
                 return;
             }
         }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
              }];
    }
}
@end
