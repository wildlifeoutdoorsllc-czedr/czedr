//
//  pendingViewController.h
//  payooxe
//
//  Created by Renu on 24/02/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface pendingViewController : UIViewController
{
    NSMutableArray *Namearray;
    NSMutableArray *nameArray2;
    NSMutableArray *emailArray;
    NSMutableArray *price;
    NSMutableArray *emailArray1;
    NSMutableArray *price1;
    int segmentValue;
}
@property  BOOL selectedBool;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)addButton:(id)sender;
- (IBAction)backButton:(id)sender;
- (IBAction)segmentButton:(id)sender;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segment;


@end
