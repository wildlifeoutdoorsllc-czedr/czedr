//
//  AppDelegate.m
//  payooxe
//
//  Created by Renu on 01/01/09.
//  Copyright (c) 2009 Renu. All rights reserved.
//

#import "AppDelegate.h"
#import "CzedrTheme.h"
#import "MMDrawerController.h"
#import "MMDrawerVisualState.h"
#import <QuartzCore/QuartzCore.h>
#import "leftSwipeViewController.h"
#import "leftViewController.h"
#import "CzedrAppChrome.h"
#import <CoreData/CoreData.h>

@interface AppDelegate ()

@end

@implementation AppDelegate
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize writerManagedObjectContext = _writerManagedObjectContext;
//app id 7XWEXhCjOtiQzRCN4txZuASMpIfm3Y6EhgbZnK9A
//cliet id XaqgeDkV3eBSDhbvvYAvNpc86sjqZc8hFUfqwtBT
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    (void)application;
    (void)launchOptions;

    if (self.window == nil) {
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    [CzedrTheme applyGlobalAppearance];
    self.window.backgroundColor = [CzedrTheme darkBackground];
    // New process after force-quit: stored auth must not skip sign-in (token alone is not enough).
    if ([CzedrAppChrome isLoggedIn]) {
        [CzedrAppChrome clearLocalSession];
    }
    [[NSUserDefaults standardUserDefaults] setValue:@"0" forKey:@"Avalue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self mainViewSwitch];
    [self.window makeKeyAndVisible];
    
//    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
//    {
//        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
//        
//    }
//    else
//    {
//        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
//         (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
//    }
    
    return YES;
}

//- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
//{
//    if (error.code == 3010) {
//        NSLog(@"Push notifications are not supported in the iOS Simulator.");
//    } else {
//        // show some alert or otherwise handle the failure to register.
//        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
//    }
//}
//
//- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString* )identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
//{
//    //handle the actions
//    if ([identifier isEqualToString:@"declineAction"]){
//    }
//    else if ([identifier isEqualToString:@"answerAction"]){
//    }
//}
//- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
//{
//    
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    [currentInstallation setDeviceTokenFromData:deviceToken];
//    
//    
//    NSString  *token_string = [[[[deviceToken description]    stringByReplacingOccurrencesOfString:@"<"withString:@""]
//                                stringByReplacingOccurrencesOfString:@">" withString:@""]
//                               stringByReplacingOccurrencesOfString: @" " withString: @""];
//    
//    [[NSUserDefaults standardUserDefaults] setValue:token_string forKey:@"objectId"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    
//    [currentInstallation saveInBackground];
//}
//
//
//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
//{
//    [PFPush handlePush:userInfo];
//}
//- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
//{
//    //register to receive notifications
//    [application registerForRemoteNotifications];
//}
//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
//{
////    aps =     {
////        alert = hgh;
////        sound = default;
////    };
////}
////{
//    UIApplicationState state = [application applicationState];
//    if (state == UIApplicationStateActive)
//    {
//        NSString *message=[NSString stringWithFormat:@"%@",[[userInfo valueForKey:@"aps"] valueForKey:@"alert"]];
//        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"You have Receive new notification" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//        [alert show];
//    }
//    else
//    {
//        [self mainViewSwitch];
//    }
//}

- (MMDrawerController *)drawerControllerWithCenterNavigation:(UINavigationController *)navigation
{
    leftViewController *leftDrawer = [[leftViewController alloc] initWithNibName:@"leftViewController" bundle:nil];
    MMDrawerController *drawerController = [[MMDrawerController alloc]
                                          initWithCenterViewController:navigation
                                          leftDrawerViewController:leftDrawer
                                          rightDrawerViewController:nil];
    [drawerController setMaximumLeftDrawerWidth:220];
    [drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
    [drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    if ([@"1" isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"Avalue"]]) {
        [drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    }
    return drawerController;
}

-(void)mainViewSwitch
{
    leftSwipeViewController *left = [[leftSwipeViewController alloc] initWithNibName:@"leftSwipeViewController" bundle:nil];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:left];
    navigation.navigationBarHidden = YES;
    MMDrawerController *drawerController = [self drawerControllerWithCenterNavigation:navigation];
    self.window.rootViewController = drawerController;
    [CzedrAppChrome refreshSessionBarForDrawer:drawerController];
}

- (void)presentHomeAfterLogin
{
    leftSwipeViewController *home = [[leftSwipeViewController alloc] initWithNibName:@"leftSwipeViewController" bundle:nil];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:home];
    navigation.navigationBarHidden = YES;
    MMDrawerController *drawerController = [self drawerControllerWithCenterNavigation:navigation];
    self.window.rootViewController = drawerController;
    [self.window makeKeyAndVisible];
    dispatch_async(dispatch_get_main_queue(), ^{
        [CzedrAppChrome refreshSessionBarForDrawer:drawerController];
    });
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  //  [[NSUserDefaults standardUserDefaults] setValue:@"0" forKey:@"Avalue"];
    
  //  [[NSUserDefaults standardUserDefaults]synchronize];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  //  [[NSUserDefaults standardUserDefaults] setValue:@"0" forKey:@"Avalue"];
    
   // [[NSUserDefaults standardUserDefaults]synchronize];
}

- (void)saveContext
{
    NSError *error = nil;
    _managedObjectContext = self.managedObjectContext;
    if (_managedObjectContext != nil)
    {
        if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error]) {
            NSLog(@"Core Data save failed: %@, %@", error, [error userInfo]);
        }
    }
}

#pragma mark - Core Data stack
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"payooze" withExtension:@"momd"];
    if (!modelURL) {
        modelURL = [[NSBundle mainBundle] URLForResource:@"czedr" withExtension:@"momd"];
    }
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"czedr.sqlite"];
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSLog(@"Core Data store failed: %@", error);
        _persistentStoreCoordinator = nil;
    }
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
@end
