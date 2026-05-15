//
//  HistoryInvoiveViewController.h
//  payooxe
//
//  Created by Renu on 24/02/15.
//  Copyright (c) 2015 Renu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryInvoiveViewController : UIViewController
{
    IBOutlet UILabel *name;
    IBOutlet UILabel *email;
    IBOutlet UILabel *amount;
    IBOutlet UILabel *date;
    IBOutlet UILabel *detail;
    IBOutlet UIView *deatilView;
}
@property int selectedIndex;
@property (weak, nonatomic) IBOutlet UILabel *received;
@property (weak, nonatomic) IBOutlet UIView *viewhistory;
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UILabel *detailLbl;

@end
