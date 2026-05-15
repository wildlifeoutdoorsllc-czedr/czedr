//
//  ReachabiltyTest.h
//  CabProjectUniversal
//
//  Created by Graycell on 12/11/13.
//  Copyright (c) 2013 Graycell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface ReachabiltyTest : NSObject
{
    Reachability *internetReach;
}
-(int)updateInterfaceWithReachability;
-(void)CheckInternetConnection;
@end
