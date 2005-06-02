//
//  XJGrowlManager.m
//  Xjournal
//
//  Created by Fraser Speirs on 11/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJGrowlManager.h"
#import <Growl/GrowlApplicationBridge.h>

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
		[GrowlApplicationBridge setGrowlDelegate: self];
	}
	return self;
}

- (NSDictionary *) registrationDictionaryForGrowl {
	NSArray *allNotifications = [NSArray arrayWithObjects: XJGrowlAccountDidLogInNotification, 
		XJGrowlAccountDidNotLogInNotification,
		XJEntryDidPostGrowlNotification,
		XJFriendsUpdatedGrowlNotification, nil];

	return [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: allNotifications, allNotifications, nil]
									   forKeys: [NSArray arrayWithObjects: GROWL_NOTIFICATIONS_DEFAULT, GROWL_NOTIFICATIONS_ALL, nil]];
}


- (void)notifyWithTitle: (NSString *)title 
			description: (NSString *)description 
	   notificationName: (NSString *)notificationName
				 sticky: (BOOL)isSticky
{
	[GrowlApplicationBridge notifyWithTitle: title
								description: description
						   notificationName: notificationName
								   iconData: [[NSApp applicationIconImage] TIFFRepresentation]
								   priority: 0
								   isSticky: isSticky
							   clickContext: nil];
}

/*- (void)growlIsReady: (NSNotification *)note {
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
*/
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
