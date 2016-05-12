//
//  AppDelegate.m
//  sample-users
//
//  Created by Quickblox Team on 6/11/15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "AppDelegate.h"
#import <Quickblox/Quickblox.h>

const NSUInteger kApplicationID = 92;
NSString *const kAuthKey        = @"wJHdOcQSxXQGWx5";
NSString *const kAuthSecret     = @"BTFsj7Rtt27DAmT";
NSString *const kAccountKey     = @"7yvNe17TnjNUqDoPwfqp";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	// Override point for customization after application launch.
    
    // Set QuickBlox credentials (You must create application in admin.quickblox.com)
    //
	NSLog(@"QBSettings");
    [QBSettings setApplicationID:kApplicationID];
    [QBSettings setAuthKey:kAuthKey];
    [QBSettings setAuthSecret:kAuthSecret];
    [QBSettings setAccountKey:kAccountKey];
    
    return YES;
}

@end
