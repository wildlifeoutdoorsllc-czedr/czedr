//
//  leftSwipeViewController.h
//  payooxe
//
//  Created by Renu on 01/01/09.
//  Copyright (c) 2009 Renu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
@interface leftSwipeViewController : UIViewController

{
    IBOutlet UILabel *countlable;
    IBOutlet UILabel *czedrIdLabel;
    NSMutableArray *array;
    NSArray *fetchedObjects;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UILabel *mkPymntLbl;
@property (weak, nonatomic) IBOutlet UILabel *pndingInvoicsLbl;
@property (weak, nonatomic) IBOutlet UILabel *histryLbl;
@property (weak, nonatomic) IBOutlet UILabel *myProfileLbl;
@property (weak, nonatomic) IBOutlet UIButton *referralEarningsBtn;
@property (strong) NSManagedObject *device;

- (IBAction)pendingButton:(id)sender;
- (IBAction)makePaymentButton:(id)sender;
- (IBAction)historyButton:(id)sender;
- (IBAction)profileButton:(id)sender;
- (IBAction)referralEarningsButton:(id)sender;
@end
