//
//  XJPreferencesController.h
//  Xjournal
//
//  Created by Fraser Speirs on 09/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XJAccountManager, XJAccountDoesCheckFriendsVT;

@interface XJPreferencesController : NSWindowController {
	NSView *currentView;
	
	XJAccountManager *accountManager;
	
	IBOutlet NSUserDefaultsController *defsController;
	
	// Array of available sounds
	NSMutableArray *availableSounds;
	
	// IB Outlets to views
	IBOutlet NSView *generalView;
	IBOutlet NSView *accountsView;
	IBOutlet NSView *notificationView;
	IBOutlet NSView *swupdateView;
	IBOutlet NSView *musicView;
	IBOutlet NSView *rssView;
		
	// ArrayController for accounts prefpane that manage groups and accounts
	IBOutlet NSTableView *checkFriendsTable;
	IBOutlet NSArrayController *accountsArrayController;
	IBOutlet NSArrayController *groupsArrayController;
	IBOutlet NSButton *accountChecksFriendsCheckbox;
	IBOutlet NSMatrix *checksAllOrGroupsMatrix;
}

- (IBAction)switchPane: (id)sender;
- (void)replaceViewWithView:(NSView *)subView;
- (void)buildArrayOfSounds;

- (void) syncAccountViewUI;

// ----------------------------------------------------------------------------------------
// Account creation/addition
// ----------------------------------------------------------------------------------------
- (IBAction)addAccount: (id)sender;
- (IBAction)removeSelectedAccount: (id)sender;

- (XJAccountManager *)accountManager;
- (void)setAccountManager:(XJAccountManager *)anAccountManager;

- (IBAction)setCheckFriendsForAccount:(id)sender;
- (IBAction)setChecksAllOrGroupsForAccount:(id)sender;

- (NSMutableArray *)availableSounds;
- (void)setAvailableSounds:(NSMutableArray *)anAvailableSounds;

@end
