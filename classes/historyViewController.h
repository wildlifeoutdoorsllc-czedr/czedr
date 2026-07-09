//
//  historyViewController.h
//  Czedr
//
//  Created by Renu on 13/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import <UIKit/UIKit.h>
NSArray *dataArrayhistory;
@interface historyViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet UITableView *tableDetail;
    IBOutlet UIButton *back;
    IBOutlet UILabel *nohistory;
    NSMutableArray *historyArraydata;
    UITableViewCell *cell;
    int startlimit;
    int endlimt;
    int total_count;
    UILabel *PriceLabel;
}

@property (strong, nonatomic) IBOutlet UILabel *titleLbl;
- (IBAction)backButton:(id)sender;

@end
