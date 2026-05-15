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
#import <CoreData/CoreData.h>
@interface leftSwipeViewController ()
{
     NSManagedObjectContext *managedObjectContext;
}
@end

@implementation leftSwipeViewController
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
    NSString *autcode=[[NSUserDefaults standardUserDefaults] valueForKey:@"auth_codeSaved"];
    NSString *myCzedrId=[[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"];
    czedrIdLabel.text=myCzedrId;
    [[NSUserDefaults standardUserDefaults] setValue:@"store_databse" forKey:@"update_value"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *strYourId = NSLocalizedString(@"Czedr ID", Nil);
     czedrIdLabel.text=[NSString stringWithFormat:@"%@ - %@",strYourId,czedrIdLabel.text];
    
    if (autcode.length==0)
    {
        ViewController *ViewController_O=[[ViewController alloc]initWithNibName:@"ViewController" bundle:nil];
        ViewController_O.hidesBottomBarWhenPushed=YES;
        [self.mm_drawerController setOpenDrawerGestureModeMask:(MMOpenDrawerGestureModeNone)];
        [self.navigationController pushViewController:ViewController_O animated:NO];
    }
    else
    {
        dispatch_queue_t backgroundQueue = dispatch_queue_create("dispatch_queue_#1", 0);
        dispatch_async(backgroundQueue, ^{

            dispatch_async(dispatch_get_main_queue(), ^{
               
                [self call_loadCardsService];
                
            });
        });
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    payNowBool = false;
    self.navigationController.navigationBar.hidden=YES;
    czedrIdLabel.textColor = [CzedrTheme mutedText];
    [CzedrTheme applyDeckLookToView:self.view];
    [[NSUserDefaults standardUserDefaults]setValue:nil forKey:@"pmakepaymentclick"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    dispatch_queue_t backgroundQueue = dispatch_queue_create("dispatch_queue_#1", 0);
    dispatch_async(backgroundQueue, ^{
        [self recevied_service];
        dispatch_async(dispatch_get_main_queue(), ^{
            
//            [self call_loadCardsService];
        });
    });
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
                countlable.text = [NSString stringWithFormat:@"%ld", (long)total];
            }
            failure:^(NSString *message) {
                (void)message;
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                countlable.text = @"0";
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
        NSString *czedrId = [[[NSUserDefaults standardUserDefaults] valueForKey:@"userDataArray"] valueForKey:@"id"];
        NSString *strYourId = NSLocalizedString(@"Your Czedr ID", Nil);
        czedrIdLabel.text = [NSString stringWithFormat:@"%@ - %@", strYourId, czedrId ?: @""];
        [SharedServiceController fetchLedgerBalanceSuccess:^(NSDictionary *data) {
            NSInteger cents = [[data objectForKey:@"balance_cents"] integerValue];
            float dollars = cents / 100.0f;
            [SharedServiceController syncBankAccountsToCoreData:^{
                [SharedServiceController fetchLinkedAccountCountSuccess:^(NSInteger count) {
                    countlable.text = [NSString stringWithFormat:@"$%.2f | %ld linked", dollars, (long)count];
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                } failure:^(NSString *message) {
                    countlable.text = [NSString stringWithFormat:@"$%.2f", dollars];
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                }];
            }];
        } failure:^(NSString *message) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
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
    if (fetchedObjects.count==array.count)
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
@end
