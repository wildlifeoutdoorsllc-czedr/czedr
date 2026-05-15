//
//  leftViewController.h
//  3pL app
//
//  Created by Mind Roots Technologies on 11/09/13.
//  Copyright (c) 2013 Mind Roots Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+MMDrawerController.h"
#import "AsyncImageView.h"

@interface leftViewController : UIViewController<UITableViewDataSource,UITableViewDataSource,UITabBarControllerDelegate>
{
    NSMutableArray *listOfArray;
    NSMutableArray *listOfArrayImages;
    IBOutlet UILabel *namelbl;
    IBOutlet UIImageView *imageView;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *view_header;
@property (strong, nonatomic) IBOutlet UIView *view_footer;


@property (strong, nonatomic) IBOutlet UILabel *lbl_name;

@property (strong, nonatomic) IBOutlet UILabel *lbl_email;

@property (strong, nonatomic) IBOutlet UILabel *lbl_company;
@property (strong, nonatomic) IBOutlet UILabel *lbl_location;

@property(strong,nonatomic)UINavigationController *nav;
@property(strong,nonatomic)AsyncImageView *imageView;

@property(strong, nonatomic)UITabBarController *tabbar;
@end
