//
//  AppDelegate.h
//  payooxe
//
//  Created by Renu on 01/01/09.
//  Copyright (c) 2009 Renu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    ViewController *view;
}
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *writerManagedObjectContext;
@property (strong, nonatomic) UIWindow *window;

/** Swaps the drawer center to home (call after successful sign-in). */
- (void)presentHomeAfterLogin;

/** Shows first-time PIN setup as drawer center when user_pin is 0. */
- (void)presentPinSetupAfterLogin;

/** Navigate to home after login without touching the login view controller. */
- (void)handleLoginSuccessWithPayload:(NSDictionary *)data;

@end
