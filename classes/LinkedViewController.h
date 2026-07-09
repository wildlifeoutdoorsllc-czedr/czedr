//
//  LinkedViewController.h
//  Czedr
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import <UIKit/UIKit.h>
NSArray *addcardArraydata;
@interface LinkedViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    NSArray *fetchedObjects1;
    IBOutlet UILabel *titleLbl;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;

-(IBAction)backButton:(id)sender;
-(IBAction)addButton:(id)sender;
@end
