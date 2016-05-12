//
//  AppDelegate.m
//  sample-chat
//
//  Created by Igor Khomenko on 10/16/13.
//  Copyright (c) 2013 Igor Khomenko. All rights reserved.
//

#import "AppDelegate.h"
#import "ServicesManager.h"
#import "ChatViewController.h"

const NSUInteger kApplicationID = 28783;
NSString *const kAuthKey        = @"b5bVGCHHv6rcAmD";
NSString *const kAuthSecret     = @"ySwEpardeE7ZXHB";
NSString *const kAccountKey     = @"7yvNe17TnjNUqDoPwfqp";

@interface AppDelegate () <NotificationServiceDelegate>

@end

@implementation AppDelegate 

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set QuickBlox credentials (You must create application in admin.quickblox.com)
    [QBSettings setApplicationID:kApplicationID];
    [QBSettings setAuthKey:kAuthKey];
    [QBSettings setAuthSecret:kAuthSecret];
    [QBSettings setAccountKey:kAccountKey];
    [QBSettings setChatDNSLookupCacheEnabled:YES];
    
    // enabling carbons for chat
    [QBSettings setCarbonsEnabled:YES];
    
    // Enables Quickblox REST API calls debug console output
//    [QBSettings setLogLevel:QBLogLevelNothing];

    // Enables detailed XMPP logging in console output
    [QBSettings enableXMPPLogging];
    
    // app was launched from push notification, handling it
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        ServicesManager.instance.notificationService.pushDialogID = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey][kPushNotificationDialogIdentifierKey];
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // subscribing for push notifications
    QBMSubscription *subscription = [QBMSubscription subscription];
    subscription.notificationChannel = QBMNotificationChannelAPNS;
    subscription.deviceUDID = deviceIdentifier;
    subscription.deviceToken = deviceToken;
    
    [QBRequest createSubscription:subscription successBlock:nil errorBlock:nil];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // failed to register push
    NSLog(@"Push failed to register with error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if ([application applicationState] != UIApplicationStateInactive){
		return;
	}
	
	NSString *dialogID = userInfo[kPushNotificationDialogIdentifierKey];
	if (dialogID == nil) {
		return;
	}
	
	NSString *dialogWithIDWasEntered = [ServicesManager instance].currentDialogID;
	if ([dialogWithIDWasEntered isEqualToString:dialogID]) return;
	
	ServicesManager.instance.notificationService.pushDialogID = dialogID;
	
	// calling dispatch async for push notification handling to have priority in main queue
	dispatch_async(dispatch_get_main_queue(), ^{
		[ServicesManager.instance.notificationService handlePushNotificationWithDelegate:self];
	});
	
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Logout from chat
    //
	[ServicesManager.instance.chatService disconnectWithCompletionBlock:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Login to QuickBlox Chat
    //
	[ServicesManager.instance.chatService connectWithCompletionBlock:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - NotificationServiceDelegate protocol

- (void)notificationServiceDidSucceedFetchingDialog:(QBChatDialog *)chatDialog
{
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;

	UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChatViewController *chatController = (ChatViewController *)[sb instantiateViewControllerWithIdentifier:@"ChatViewController"];
    chatController.channel = chatDialog;
    
    NSString *dialogWithIDWasEntered = [ServicesManager instance].currentDialogID;
    if (dialogWithIDWasEntered != nil) {
        // some chat already opened, return to dialogs view controller first
        [navigationController popViewControllerAnimated:NO];
    }
    
    [navigationController pushViewController:chatController animated:YES];
}

@end
