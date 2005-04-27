//
//  XJGrowlManager.h
//  Xjournal
//
//  Created by Fraser Speirs on 11/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

FOUNDATION_EXPORT NSString * const XJGrowlAccountDidLogInNotification;
FOUNDATION_EXPORT NSString * const XJGrowlAccountDidNotLogInNotification;
FOUNDATION_EXPORT NSString * const XJEntryDidPostGrowlNotification;
FOUNDATION_EXPORT NSString * const XJFriendsUpdatedGrowlNotification;

@interface XJGrowlManager : NSObject {
	BOOL growlAvailable;
	BOOL growlReady;
}

+ (XJGrowlManager *)defaultManager;

- (void)notifyWithTitle: (NSString *)title 
			description: (NSString *)description 
	   notificationName: (NSString *)notificationName
				 sticky: (BOOL)isSticky;

- (BOOL)growlAvailable;
- (void)setGrowlAvailable:(BOOL)flag;

@end
