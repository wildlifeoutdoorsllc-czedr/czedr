//
//  AppDelegate.h
//  payooxe
//
//  Created by Renu on 01/01/09.
//  Copyright (c) 2009 Renu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
//#import <Parse/Parse.h>
#import <OneSignal/OneSignal.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    ViewController *view;
}
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *writerManagedObjectContext;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) OneSignal *oneSignal;

@end

