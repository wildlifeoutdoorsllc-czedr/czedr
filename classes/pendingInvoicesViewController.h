//
//  pendingInvoicesViewController.h
//  Czedr
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import <UIKit/UIKit.h>
NSMutableArray *dataArray1;
@interface pendingInvoicesViewController : UIViewController
{
    
    NSMutableArray *recevieArray;
    NSMutableArray *sentArray;
    NSMutableArray *commonArray;
    int sentStartvariable;
    int receveStartvariable;
    int segmentValue;
    IBOutlet UIButton *back;
    IBOutlet UILabel *noinvoicelbl;
    BOOL checkbool;
}

@property  BOOL selectedBool;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)addButton:(id)sender;
- (IBAction)backButton:(id)sender;
- (IBAction)segmentButton:(id)sender;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segment;
@property (strong, nonatomic) IBOutlet UILabel *titleLbl;

@end
