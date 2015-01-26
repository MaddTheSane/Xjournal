//
//  XJHistorySyncManager.h
//  Xjournal
//
//  Created by Fraser Speirs on 11/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XJAccountManager;

/*
 * This class lives in the background and manages 
 * syncing LJHistory objects for all known accounts.
 */
@interface XJHistorySyncManager : NSObject {
	XJAccountManager *accountManager;

	// We use a timer to kick off the syncing
	NSTimer *syncTimer;
	int syncInterval;
}

- (XJAccountManager *)accountManager;
- (void)setAccountManager:(XJAccountManager *)anAccountManager;

- (NSTimer *)syncTimer;
- (void)setSyncTimer:(NSTimer *)aSyncTimer;

- (int)syncInterval;
- (void)setSyncInterval:(int)aSyncInterval;
- (void)syncTimerFired: (NSTimer *)timer;
@end
