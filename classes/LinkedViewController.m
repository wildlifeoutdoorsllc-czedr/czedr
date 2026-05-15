//
//  LinkedViewController.m
//  payoox
//
//  Created by Renu on 12/02/15.
//  Copyright (c) 2015 mindroots. All rights reserved.
//

#import "LinkedViewController.h"
#import "addCreditViewController.h"
#import <CoreData/CoreData.h>
#import "SharedServiceController.h"
@interface LinkedViewController ()
{
    NSManagedObjectContext *managedObjectContext;
}
@end

@implementation LinkedViewController

- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)])
    {
        context = [delegate managedObjectContext];
    }
    return context;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *strTitleLbl = NSLocalizedString(@"Linked Cards", Nil);
    titleLbl.text = [strTitleLbl uppercaseString];
}

-(void)viewWillAppear:(BOOL)animated
{
    if ([SharedServiceController usesV1API]) {
        [SharedServiceController syncBankAccountsToCoreData:^{
            [self reloadCardsTable];
        }];
        return;
    }
    [self reloadCardsTable];
}

-(void)reloadCardsTable
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    if (context == nil)
    {
//     NSLog(@"Nil");
    }
    else
    {
        NSError *error;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cards" inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        fetchedObjects1 = [context executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects1.count==0)
        {
            
        }
        else
        {
            for (int i=0; i<fetchedObjects1.count; i++)
            {
//             NSLog(@"%@",[[fetchedObjects1 objectAtIndex:i] valueForKey:@"name"]);
            }
            self.tableView.dataSource=self;
            self.tableView.delegate=self;
            [self.tableView reloadData];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return fetchedObjects1.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
        if (cell == nil)
        {
          cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UILabel *Namelabel  =[[UILabel alloc]initWithFrame:(CGRectMake(65, 2, 150, 25))];
        Namelabel.text=[[fetchedObjects1 objectAtIndex:indexPath.row] valueForKey:@"name"];
        Namelabel.autoresizesSubviews=YES;
        [Namelabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
        Namelabel.font=[UIFont fontWithName:@"Avenir-Roman" size:12.5];
        
        [cell.contentView addSubview:Namelabel];
        UILabel *passwordLabel  =[[UILabel alloc]initWithFrame:(CGRectMake(65,18, 200, 30))];
        passwordLabel.autoresizesSubviews=YES;
        [passwordLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth];
        passwordLabel.text=[NSString stringWithFormat:@"**** **** ****%@", [[fetchedObjects1 objectAtIndex:indexPath.row] valueForKey:@"cardnumber"]];
        passwordLabel.font=[UIFont fontWithName:@"Avenir-Roman" size:12.5];
        [passwordLabel setFont: [UIFont systemFontOfSize:12.0]];
        [cell.contentView addSubview:passwordLabel];
        UIImageView *image=[[UIImageView alloc]initWithFrame:(CGRectMake(5, 2, 60, 40))] ;
        if ([[[fetchedObjects1 objectAtIndex:indexPath.row] valueForKey:@"card_default"] isEqualToString:@"1"])
        {
            image.image=[UIImage imageNamed:@"chasebankcard_1.png"];
            [cell.contentView addSubview:image];
        }
        else
        {
            image.image=[UIImage imageNamed:@"cardsimple.png"];
            [cell.contentView addSubview:image];
        }
   
        UIImageView *Rightimage=[[UIImageView alloc]initWithFrame:(CGRectMake(tableView.frame.size.width-20,cell.frame.size.height/2-6, 10, 15))] ;
        Rightimage.image=[UIImage imageNamed:@"arrowgrey.png"];
        [cell.contentView addSubview:Rightimage];
        return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSUserDefaults standardUserDefaults] setValue:@"updtae" forKey:@"cardInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    addCreditViewController *ob=[[addCreditViewController alloc]initWithNibName:@"addCreditViewController" bundle:nil];
    addcardArraydata=[fetchedObjects1 objectAtIndex:indexPath.row];
    [[NSUserDefaults standardUserDefaults] setInteger:indexPath.row forKey:@"save_index"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.navigationController pushViewController:ob animated:YES];
}

- (IBAction)backButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)addButton:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"cardInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    addCreditViewController *add=[[addCreditViewController alloc]initWithNibName:@"addCreditViewController" bundle:nil];
    [self.navigationController pushViewController:add animated:YES];
}
@end
