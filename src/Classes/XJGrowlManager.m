//
//  XJGrowlManager.m
//  Xjournal
//
//  Created by Fraser Speirs on 11/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJGrowlManager.h"
#import <GrowlAppBridge/GrowlApplicationBridge.h>
#import <GrowlAppBridge/GrowlDefines.h>

NSString * const XJGrowlAccountDidLogInNotification =   @"Account Logged In";
NSString * const XJGrowlAccountDidNotLogInNotification =   @"Account Login Failed";
NSString * const XJEntryDidPostGrowlNotification = @"Entry Posted";
NSString * const XJFriendsUpdatedGrowlNotification = @"Friends Page Updated";

static XJGrowlManager *singleton;

@implementation XJGrowlManager
+ (XJGrowlManager *)defaultManager {
	if(!singleton)
		singleton = [[XJGrowlManager alloc] init];
	return singleton;
}

+ (void)initialize {
	singleton = [[XJGrowlManager alloc] init];
}

- (id)init {
	self = [super init];
	if(self) {
		// Pull in Growl if we have it.
		id gab = NSClassFromString(@"GrowlAppBridge");
		NSLog(@"Got GAB: %@", gab);
		if(gab != nil) {
			[self setGrowlAvailable: [gab launchGrowlIfInstalledNotifyingTarget: self
																	   selector: @selector(growlIsReady:)
																		context: nil]];		
		}
		else {
			[self setGrowlAvailable: NO];
		}
		NSLog(@"Growl available: %d", [self growlAvailable]);
	}
	return self;
}


- (void)notifyWithTitle: (NSString *)title 
			description: (NSString *)description 
	   notificationName: (NSString *)notificationName
				 sticky: (BOOL)isSticky
{
	if([self growlAvailable] && growlReady) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject: @"Xjournal" forKey: GROWL_APP_NAME];
		[dict setObject: notificationName forKey: GROWL_NOTIFICATION_NAME];
		[dict setObject: title forKey: GROWL_NOTIFICATION_TITLE];
		[dict setObject: description forKey: GROWL_NOTIFICATION_DESCRIPTION];
		[dict setObject: [[NSApp applicationIconImage] TIFFRepresentation] forKey: GROWL_NOTIFICATION_ICON];
		[dict setObject: [NSNumber numberWithBool: isSticky] forKey: GROWL_NOTIFICATION_STICKY];
		
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION 
																	   object:nil 
																	 userInfo: dict
														   deliverImmediately:YES];
	}
	else {
		NSLog(@"Growl unavailable: %@", description);
	}
}

- (void)growlIsReady: (NSNotification *)note {
	growlReady = YES;	
	NSLog(@"Got growlIsReady Notification");
	
	// Growl Registration
	
	NSMutableDictionary *regDict = [NSMutableDictionary dictionary];
	NSArray *allNotifications = [NSArray arrayWithObjects: XJGrowlAccountDidLogInNotification, XJGrowlAccountDidNotLogInNotification, XJEntryDidPostGrowlNotification, nil];
	NSArray *defaultNotifications = [NSArray arrayWithObjects: XJGrowlAccountDidLogInNotification, XJGrowlAccountDidNotLogInNotification, XJEntryDidPostGrowlNotification, nil];
	
	[regDict setObject: @"Xjournal" forKey: GROWL_APP_NAME];
	[regDict setObject: allNotifications forKey: GROWL_NOTIFICATIONS_ALL];
	[regDict setObject: defaultNotifications forKey: GROWL_NOTIFICATIONS_DEFAULT];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName: GROWL_APP_REGISTRATION
																   object: nil
																 userInfo: regDict];
}

// =========================================================== 
// - growlAvailable:
// =========================================================== 
- (BOOL)growlAvailable {
	
    return growlAvailable;
}

// =========================================================== 
// - setGrowlAvailable:
// =========================================================== 
- (void)setGrowlAvailable:(BOOL)flag {
	growlAvailable = flag;
}
@end
