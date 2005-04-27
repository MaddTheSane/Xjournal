//
//  XJPreferencesController.m
//  Xjournal
//
//  Created by Fraser Speirs on 09/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJPreferencesController.h"
#import "XJAccountManager.h"

#import "XJPreferences.h"

#define kAccountsItem @"Accounts"
#define kNotificationItem @"Notification"
#define kGeneralItem @"General"
#define kSWUpdate @"SWUpdate"
#define kMusic @"Music"
#define kRSS @"RSS"

@implementation XJPreferencesController
- (id)init {
	self = [super initWithWindowNibName: @"XJPreferences"];
	if(self) {
		[self setAccountManager: [XJAccountManager defaultManager]];
		[self setAvailableSounds: [NSMutableArray array]];
		[self buildArrayOfSounds];
	}
	return self;
}

- (void)windowDidLoad {
	[self replaceViewWithView: generalView];
	
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: @"Preferences Toolbar"];
	[toolbar setAllowsUserCustomization: NO];
	[toolbar setAutosavesConfiguration: NO];
	[toolbar setDelegate: self];
	[[self window] setToolbar: toolbar];
	[toolbar setSelectedItemIdentifier: kGeneralItem];
	[toolbar release];
}

- (void)windowWillClose:(NSNotification *)notification {
	// Make sure we commit the edits
	[[self window] endEditingFor: nil];
}

- (IBAction)switchPane: (id)sender {
	
	if([[sender itemIdentifier] isEqualToString: kGeneralItem]) {
		[self replaceViewWithView: generalView];
	}
	else if([[sender itemIdentifier] isEqualToString: kAccountsItem]) {
		[self replaceViewWithView: accountsView];
		
		[self syncAccountViewUI];
	}
	else if([[sender itemIdentifier] isEqualToString: kNotificationItem]) {
		[self replaceViewWithView: notificationView];
	}
	else if([[sender itemIdentifier] isEqualToString: kSWUpdate]) {
		[self replaceViewWithView: swupdateView];
	}
	else if([[sender itemIdentifier] isEqualToString: kMusic]) {
		[self replaceViewWithView: musicView];
	}
	else if([[sender itemIdentifier] isEqualToString: kRSS]) {
		[self replaceViewWithView: rssView];
	}
}

- (void)replaceViewWithView:(NSView *)subView {
	if(currentView)
		[currentView removeFromSuperview];
	
	currentView = subView;
	[[[self window] contentView] addSubview: currentView];
}

// ----------------------------------------------------------------------------------------
// Account creation/addition
// ----------------------------------------------------------------------------------------
- (IBAction)addAccount: (id)sender {
	LJAccount *acct = [[LJAccount alloc] initWithUsername: @"Username"];
	[[self accountManager] insertObject: acct
					  inAccountsAtIndex: [[self accountManager] countOfAccounts]];
	[acct autorelease];
}

- (IBAction)removeSelectedAccount: (id)sender {
	
}

// ----------------------------------------------------------------------------------------
// Toolbar delegate
// ----------------------------------------------------------------------------------------
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
	
	if([itemIdentifier isEqualToString: kGeneralItem]) {
		[item setLabel: NSLocalizedString(@"General", @"")];
		[item setTarget: self];
		[item setAction: @selector(switchPane:)];
		[item setImage: [NSImage imageNamed: @"GenPreferences"]];
	}
	else if([itemIdentifier isEqualToString: kAccountsItem]) {
		[item setLabel: NSLocalizedString(@"Accounts", @"")];
		[item setTarget: self];
		[item setAction: @selector(switchPane:)];
		[item setImage: [NSImage imageNamed: @"AccountPreferences"]];
	}
	else if([itemIdentifier isEqualToString: kNotificationItem]) {
		[item setLabel: NSLocalizedString(@"Notification", @"")];
		[item setTarget: self];
		[item setAction: @selector(switchPane:)];
		[item setImage: [NSImage imageNamed: @"CautionIcon"]];
	}
	else if([itemIdentifier isEqualToString: kSWUpdate]) {
		[item setLabel: NSLocalizedString(@"Update", @"")];
		[item setTarget: self];
		[item setAction: @selector(switchPane:)];
		[item setImage: [NSImage imageNamed: @"OSUPreferences"]];
	}
	else if([itemIdentifier isEqualToString: kMusic]) {
		[item setLabel: NSLocalizedString(@"Music", @"")];
		[item setTarget: self];
		[item setAction: @selector(switchPane:)];
		[item setImage: [NSImage imageNamed: @"cd"]];
	}
	else if([itemIdentifier isEqualToString: kRSS]) {
		[item setLabel: NSLocalizedString(@"RSS Posting", @"")];
		[item setTarget: self];
		[item setAction: @selector(switchPane:)];
		[item setImage: [NSImage imageNamed: @"PostToWeblog"]];
	}
    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: kGeneralItem, kAccountsItem, kNotificationItem, kMusic, kRSS, kSWUpdate, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: kGeneralItem, kAccountsItem, kNotificationItem, kMusic, kRSS, kSWUpdate, nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return [self toolbarAllowedItemIdentifiers: toolbar];
}

- (void) syncAccountViewUI {
	LJAccount *selectedAccount = [[accountsArrayController selectedObjects] objectAtIndex: 0];
	BOOL checksFriends = [accountManager accountChecksFriends: selectedAccount];
	[accountChecksFriendsCheckbox setState: checksFriends];
	[checksAllOrGroupsMatrix setEnabled: checksFriends];
	
	if(checksFriends) {
		BOOL checksGroups = [[[accountManager cfSessionForAccount: selectedAccount] checkGroupArray] count] != 0;
		[checksAllOrGroupsMatrix selectCellWithTag: checksGroups];  // tag 0 for all, 1 for groups
	}
	
	[checkFriendsTable reloadData];
}

// =========================================================== 
// Checkfriends toggle for account
// ===========================================================
- (IBAction)setCheckFriendsForAccount:(id)sender {
	LJAccount *selectedAccount = [[accountsArrayController selectedObjects] objectAtIndex: 0];
	[accountManager setAccount: selectedAccount checksFriends: [sender state] startChecking: YES];
	
	[self syncAccountViewUI];
}

- (IBAction)setChecksAllOrGroupsForAccount:(id)sender {
	BOOL checksAll = [[sender selectedCell] tag] == 0;
	
	LJAccount *selectedAccount = [[accountsArrayController selectedObjects] objectAtIndex: 0];
	LJCheckFriendsSession *cfSession = [accountManager cfSessionForAccount: selectedAccount];
	
	if(checksAll) {
		// If want to check all, set the group set to nil and all
		// groups will be checked
		[cfSession setCheckGroupSet: nil];
	}
	
	NSLog(@"Set check all for account %@: %d", [selectedAccount username], checksAll);
	
	[checkFriendsTable reloadData];
}

// =========================================================== 
// Checkfriends table delegate
// ===========================================================
- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	if([[accountsArrayController selectedObjects] count] > 0) {
		LJAccount *selectedAccount = [[accountsArrayController selectedObjects] objectAtIndex: 0];
		return [[selectedAccount groupArray] count];
	}
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	LJAccount *selectedAccount = [[accountsArrayController selectedObjects] objectAtIndex: 0];
	LJGroup *group = [[selectedAccount groupArray] objectAtIndex: row];
	
	if([[tableColumn identifier] isEqualToString: @"groupName"]) {
		return [group name];
	}
	else {
		LJCheckFriendsSession *cfSession = [accountManager cfSessionForAccount: selectedAccount];
		return [NSNumber numberWithBool: [[cfSession checkGroupSet] containsObject: group]];
	}
	
	return [NSNumber numberWithBool: NO];
}

// optional
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	LJAccount *selectedAccount = [[accountsArrayController selectedObjects] objectAtIndex: 0];
	LJGroup *group = [[selectedAccount groupArray] objectAtIndex: row];
	
	LJCheckFriendsSession *cfSession = [accountManager cfSessionForAccount: selectedAccount];
	NSLog(@"Set checking for group %@ (%d)", [group name], [object boolValue]);
	[cfSession setChecking: [object boolValue] forGroup: group];
	
	[tableView reloadData];
}

- (void)tableView:(NSTableView *)aTableView 
  willDisplayCell:(id)aCell
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(int)rowIndex
{
	if([[aTableColumn identifier] isEqualToString: @"groupAccess"]) {
		[aCell setEnabled: [checksAllOrGroupsMatrix selectedTag] != 0];
	}
}

- (void)tableViewSelectionDidChange: (NSNotification *)note {
	[self syncAccountViewUI];
}

// Sounds
- (void)buildArrayOfSounds {
	NSFileManager *manager = [NSFileManager defaultManager];
    NSEnumerator *locs = [[NSArray arrayWithObjects: @"/System/Library/Sounds", [@"~/Library/Sounds" stringByExpandingTildeInPath], nil] objectEnumerator];
    NSString *path;
	
    while(path = [locs nextObject]) {
        NSDirectoryEnumerator *dEnum = [manager enumeratorAtPath: path];
        NSString *file;
		
        while(file = [dEnum nextObject]) {
            if(![file hasPrefix: @"."]) {
				[[self mutableArrayValueForKey: @"availableSounds"] addObject: file];
            }
        }
    }
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
        [anAccountManager retain];
        [accountManager release];
        accountManager = anAccountManager;
    }
}


// =========================================================== 
// - availableSounds:
// =========================================================== 
- (NSMutableArray *)availableSounds {
    return availableSounds; 
}

// =========================================================== 
// - setAvailableSounds:
// =========================================================== 
- (void)setAvailableSounds:(NSMutableArray *)anAvailableSounds {
    if (availableSounds != anAvailableSounds) {
        [anAvailableSounds retain];
        [availableSounds release];
        availableSounds = anAvailableSounds;
    }
}
@end
