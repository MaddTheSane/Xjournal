//
//  XJHistorySyncManager.m
//  Xjournal
//
//  Created by Fraser Speirs on 11/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJHistorySyncManager.h"
#import "XJAccountManager.h"
#import <LJKit/LJKit.h>

@implementation XJHistorySyncManager
- (id)init {
	self = [super init];
	if(self) {
		// Use this to kick off another trickle sync
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(entryDidSave:)
													 name: LJEntryDidSaveToJournalNotification
												   object: nil];
		
		[self setAccountManager: [XJAccountManager defaultManager]];
		[self setSyncInterval: 60*5];
		
		[self setSyncTimer: [NSTimer scheduledTimerWithTimeInterval: 10
															 target: self
														   selector: @selector(syncTimerFired:)
														   userInfo: nil
															repeats: NO]];
	}
	return self;
}

- (void)syncTimerFired: (NSTimer *)timer {
	NSLog(@"Sync updating from timer");
	NSEnumerator *en = [[[self accountManager] accounts] objectEnumerator];
	LJAccount *acct;
	while(acct = [en nextObject]) {
		LJHistory *history = [acct history];
		if([acct isLoggedIn] && ![history isUpdating]) {
			NS_DURING
				[NSThread detachNewThreadSelector: @selector(updateHistoryForAccount:)
										 toTarget: self 
									   withObject: acct];
			NS_HANDLER
				// If bad stuff happens, we just patch up and try again later
				NSLog(@"Error updating History");
			NS_ENDHANDLER
		}
	}
	
	[self setSyncTimer: [NSTimer scheduledTimerWithTimeInterval: [self syncInterval]
														 target: self
													   selector: @selector(syncTimerFired:)
													   userInfo: nil
														repeats: NO]];
}

- (void)entryDidSave: (NSNotification *)note {
	NSLog(@"Trickle sync got notification of new post");
	// Invalidate the timer, then restart it when we know it's done.
	
	[self setSyncTimer: [NSTimer scheduledTimerWithTimeInterval: 5
														 target: self
													   selector: @selector(syncTimerFired:)
													   userInfo: nil
														repeats: NO]];
}

- (void)updateHistoryForAccount: (LJAccount *)acct {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL success = NO;
	int retries = 0;
	while(!success && retries < 3) {
		NS_DURING
			[[acct history] update];
			success = YES;
		NS_HANDLER
			NSLog(@"Error in account update thread: %@", [localException reason]);
			retries++;  
            // If we can't continue with three retries, give up and try the next time the sync timer fires.
		NS_ENDHANDLER
	}

	[pool release];
}

// =========================================================== 
// - accountManager:
// =========================================================== 
- (XJAccountManager *)accountManager {
    return accountManager; 
}

// =========================================================== 
// - setAccountManager:
// =========================================================== 
- (void)setAccountManager:(XJAccountManager *)anAccountManager {
    if (accountManager != anAccountManager) {
        accountManager = anAccountManager;
    }
}

// =========================================================== 
// - syncTimer:
// =========================================================== 
- (NSTimer *)syncTimer {
    return syncTimer; 
}

// =========================================================== 
// - setSyncTimer:
// =========================================================== 
- (void)setSyncTimer:(NSTimer *)aSyncTimer {
    if (syncTimer != aSyncTimer) {
        [aSyncTimer retain];
		
		[syncTimer invalidate];
        [syncTimer release];
        syncTimer = aSyncTimer;
    }
}

// =========================================================== 
// - syncInterval:
// =========================================================== 
- (int)syncInterval {
    return syncInterval;
}

// =========================================================== 
// - setSyncInterval:
// =========================================================== 
- (void)setSyncInterval:(int)aSyncInterval {
	syncInterval = aSyncInterval;
	
	[self setSyncTimer: [NSTimer scheduledTimerWithTimeInterval: syncInterval
														 target: self
													   selector: @selector(syncTimerFired:)
													   userInfo: nil
														repeats: YES]];
}

@end
