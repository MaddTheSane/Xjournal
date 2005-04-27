#import "XJFriendsController.h"
#import <LJKit/LJKit.h>
#import "XJAccountManager.h"
#import "XJFriendsController-NSToolbarController.h"
#import "XJPreferences.h"
#import <AddressBook/AddressBook.h>
#import "LJFriend-ABExtensions.h"
#import <Foundation/NSDebug.h>

#import "NetworkConfig.h"
#import "FriendshipDisplayValueTransformer.h"
#import "XJFriendImageValueTransformer.h"
#import "XJGroupImageValueTransformer.h"

#define kFriendsAutosaveName @"kFriendsAutosaveName"


@implementation XJFriendsController

- (id)init
{
	self = [super initWithWindowNibName: @"NewFriendsWindow"];
    if(self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(addressBookDropped:)
                                                     name: XJAddressCardDroppedNotification
                                                   object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dirtyWindow:)
                                                     name: @"XJGroupsChangedNotification"
                                                   object:nil];
		
		[self setAccountManager: [XJAccountManager defaultManager]];
		
		// Potential race condition.  Probably need to listen for the notification as well.
		[self setAccount: [accountManager defaultAccount]]; 
		
		[self setShowUsers: YES];
		[self setShowCommunities: YES];
		
		// Set VT for table
		FriendshipDisplayValueTransformer *fVT = [[FriendshipDisplayValueTransformer alloc] init];
		[NSValueTransformer setValueTransformer: fVT forName: @"FriendshipDisplayValueTransformer"];
		[NSValueTransformer setValueTransformer: [[[XJFriendImageValueTransformer alloc] init] autorelease] forName: @"XJFriendImageValueTransformer"];
		[NSValueTransformer setValueTransformer: [[[XJGroupImageValueTransformer alloc] init] autorelease] forName: @"XJGroupImageValueTransformer"];
    }
	return self;
}

- (void)windowDidLoad
{
    [[self window] setFrameAutosaveName: kFriendsAutosaveName];
    
    [self setUpToolbar]; // see the NSToolbarController category
    
    // Set the table for double click
    [friendsTable setTarget: self];
    [friendsTable setDoubleAction:@selector(openSelectedFriendsJournal:)];
    
	// Bind the friends array controller to me

	[friendsForSelectedGroupController bind: @"showUsers"
								   toObject: self
								withKeyPath: @"showUsers"
									options: nil];
	
	[friendsForSelectedGroupController bind: @"showCommunities"
								   toObject: self
								withKeyPath: @"showCommunities"
									options: nil];
	
	[groupController setAccount: [self account]];
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
// - showUsers:
// =========================================================== 
- (BOOL)showUsers {
	
    return showUsers;
}

// =========================================================== 
// - setShowUsers:
// =========================================================== 
- (void)setShowUsers:(BOOL)flag {
	showUsers = flag;
}

// =========================================================== 
// - showCommunities:
// =========================================================== 
- (BOOL)showCommunities {
    return showCommunities;
}

// =========================================================== 
// - setShowCommunities:
// =========================================================== 
- (void)setShowCommunities:(BOOL)flag {
	showCommunities = flag;
}

- (LJAccount *)account { 
    return account;
}

- (void)setAccount: (LJAccount *)acct {
    account = acct;
	[groupController setAccount: account];
}

// ----------------------------------------------------------------------------------------
// IB Actions
// ----------------------------------------------------------------------------------------
- (IBAction)addFriend:(id)sender
{
    if([friendsTable numberOfSelectedRows] == 1 && [[[friendsForSelectedGroupController selectedObjects] objectAtIndex:0] friendship] == LJIncomingFriendship )
		[friendField setStringValue: [[[friendsForSelectedGroupController selectedObjects] objectAtIndex:0] username]];
	else
		[friendField setStringValue: @""];
    [friendField setDrawsBackground: YES];
    currentSheet = friendSheet;
    
	[NSApp beginSheet: friendSheet
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo: @"friendSheet"];
}

- (IBAction)addGroup:(id)sender
{
    [groupField setStringValue: @""];
    currentSheet = groupSheet;
    
    [NSApp beginSheet: groupSheet
       modalForWindow: [self window]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
}

- (IBAction)deleteFriendButtonAction: (id)sender {
	NSLog(@"Selected index: %d", [groupController selectionIndex]);
	if([groupController selectionIndex] != 0) {
		NSString *groupName = [[[groupController selectedObjects] objectAtIndex: 0] name];
		NSString *msg = [NSString stringWithFormat: @"Do you want to remove the selected friends from your friends list, or simply remove them from the group \"%@\"?", groupName];
		
		//NSBeginAlertSheet(<#NSString * title#>,<#NSString * defaultButton#>,<#NSString * alternateButton#>,<#NSString * otherButton#>,<#NSWindow * docWindow#>,<#id modalDelegate#>,<#SEL didEndSelector#>,<#SEL didDismissSelector#>,<#void * contextInfo#>,<#NSString * msg#>)
		NSBeginAlertSheet(@"Delete Friend",
						  @"Remove from Group", // default
						  @"Cancel", // alternate
						  @"Remove as Friend", // other
						  [self window],
						  self,
						  @selector(sheetDidEnd:returnCode:contextInfo:),
						  nil,
						  @"DeleteFriendSheet",
						  msg);
	}
	else {
		[self deleteSelectedFriend: sender];
	}
}

- (IBAction)deleteSelectedFriend: (id)sender
{
	NSArray *selectedObjects = [friendsForSelectedGroupController selectedObjects];
	if([selectedObjects count] != 0) {
		LJFriend *friend;
		NSEnumerator *en = [selectedObjects objectEnumerator];
		while(friend = [en nextObject]) {
			NSLog(@"Removing %@ from friends list", [friend username]);
			[[self account] removeFriend: friend];
		}
		[[self window] setDocumentEdited: YES];
	}
}

- (IBAction)removeSelectedFriendFromGroup: (id)sender
{
    LJGroup *theGroup = [[groupController selectedObjects] objectAtIndex: 0];
    if(!theGroup) return;

	NSArray *selectedObjects = [friendsForSelectedGroupController selectedObjects];
	if([selectedObjects count] != 0) {
		LJFriend *friend;
		NSEnumerator *en = [selectedObjects objectEnumerator];
		while(friend = [en nextObject]) {
			NSLog(@"Removing %@ from group %@", [friend username], [theGroup name]);
			[theGroup removeFriend: friend];
		}
	}

    [[self window] setDocumentEdited: YES];
}

- (IBAction)deleteSelectedGroup: (id)sender
{
    LJGroup *grp = [[groupController selectedObjects] objectAtIndex: 0];
    if(!grp) return;
    
    [[self account] removeGroup: grp];
    
    [[self window] setDocumentEdited: YES];
}

- (IBAction)cancelSheet: (id)sender
{
    [NSApp endSheet: currentSheet];
    [currentSheet orderOut: nil];
    currentSheet = nil;
}

- (IBAction)commitSheet: (id)sender
{
    if([currentSheet isEqualTo: friendSheet]) {
        if([[friendField stringValue] length] == 0)
            return;
        
        [[self account] addFriendWithUsername: [friendField stringValue]];
    }
    else {
        if([[groupField stringValue] length] == 0)
            return;
        [[self account] newGroupWithName: [groupField stringValue]];
    }

    [self cancelSheet: self];
    [[self window] setDocumentEdited: YES];
}

- (IBAction)removeAddressCard: (id)sender
{
    LJFriend *selectedFriend = [[friendsForSelectedGroupController selectedObjects] objectAtIndex:0];
    if(!selectedFriend) return;

    [selectedFriend unassociateABRecord];
    [self updateTabs];
}

- (IBAction)openSelectedFriendsJournal: (id)sender
{
    LJFriend *selectedFriend = [[friendsForSelectedGroupController selectedObjects] objectAtIndex:0];
    if(!selectedFriend) return;

    [[NSWorkspace sharedWorkspace] openURL: [selectedFriend recentEntriesHttpURL]];
}

- (IBAction)openSelectedFriendsProfile: (id)sender
{
    LJFriend *selectedFriend = [[friendsForSelectedGroupController selectedObjects] objectAtIndex:0];
    if(!selectedFriend) return;

    [[NSWorkspace sharedWorkspace] openURL: [selectedFriend userProfileHttpURL]];
}

- (IBAction)saveDocument: (id)sender
{
    [[self window] setDocumentEdited: NO];
    [[self account] uploadFriends];
}

- (IBAction)launchAddressBook: (id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication: @"Address Book"];
}

- (void) addressBookDropped: (NSNotification *)note
{
    NSArray *addressUIDs = [note object];
    if([addressUIDs count] == 0) return;
    
    ABRecord *person = [[ABAddressBook sharedAddressBook] recordForUniqueId: [addressUIDs objectAtIndex:0]];

    [[[friendsForSelectedGroupController selectedObjects] objectAtIndex:0] associateABRecord: person];
    [addressBookClearButton setEnabled: YES];
}

- (IBAction)addSelectedFriendToAddressBook: (id)sender
{
    LJFriend *sFriend = [[friendsForSelectedGroupController selectedObjects] objectAtIndex:0];
    if(sFriend && ![sFriend hasAddressCard])
        [sFriend addAddressCardAndEdit: YES];
    [self updateTabs];
}

- (IBAction)launchChatSession: (id)sender
{
    LJFriend *friend = [[friendsForSelectedGroupController selectedObjects] objectAtIndex:0];
    NSString *chatURL = [friend chatURL];
    if(chatURL)
        [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: chatURL]];
}

// ----------------------------------------------------------------------------------------
// Sheet handling
// ----------------------------------------------------------------------------------------
- (void)sheetDidEnd: (NSWindow *)sheet returnCode: (int)code contextInfo: (void *)contextInfo
{
	id context = (id)contextInfo;
	
	if([context isEqualToString: @"DeleteFriendSheet"]) {
		switch(code) {
			case NSAlertDefaultReturn: // Remove from Group
				NSLog(@"Got Remove From Group");
				[self removeSelectedFriendFromGroup: self];
				break;
			case NSAlertOtherReturn: // Remove Totally
				NSLog(@"Got Remove Totally");
				[self deleteSelectedFriend:self];
				break;
			default:
				NSLog(@"Got Cancel");
				break;
		}
	}
	
	else if([context isEqualToString: @"SaveSheet"]) 
	{
		switch(code) {
			case NSAlertDefaultReturn: // Save
				[[self window] setDocumentEdited: NO];
				[[self window] close];
				break;
			case NSAlertAlternateReturn: // Don't save
				[[self window] setDocumentEdited: NO];
				[self updateTabs];
				[[self window] close];
				[[self account] downloadFriends];
				break;
			default:
				break;
           
        }
    }
}

// ----------------------------------------------------------------------------------------
// Notifications
// ----------------------------------------------------------------------------------------

- (void)updateTabs
{
    if([[friendsForSelectedGroupController selectedObjects] count] > 1) {
		[iCalButton setEnabled: NO];
		// AB
		[addressBookClearButton setEnabled: NO];
	} else {
		LJFriend *selFriend = [[friendsForSelectedGroupController selectedObjects] objectAtIndex:0];
		[addressBookClearButton setEnabled: [selFriend hasAddressCard]];
	}
}

- (IBAction)addBirthdayToiCal: (id)sender
{
    NSDictionary *cals = [self getCalendars];
    
    [calPopup removeAllItems];
    [calPopup addItemsWithTitles: [cals allKeys]];
    [calPopup selectItemWithTitle: @"Birthdays"];
    
    
    [NSApp beginSheet: calChooserSheet
       modalForWindow: [self window]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
}

- (IBAction)commitBirthdaySheet: (id)sender
{
    [[[friendsForSelectedGroupController selectedObjects] objectAtIndex:0] addBirthdayToCalendarNamed: [calPopup titleOfSelectedItem]];
    [self cancelBirthdaySheet:self];
}

- (IBAction)cancelBirthdaySheet: (id)sender
{
    [NSApp endSheet:calChooserSheet];
    [calChooserSheet orderOut: nil];
}


- (NSDictionary *)getCalendars
{
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:
        [@"~/Library/Preferences/com.apple.iCal.sources.plist" stringByExpandingTildeInPath]];
    
    if (prefs != nil) {
        NSDictionary *cals = [prefs objectForKey:@"SourcesView"];
        if (cals != nil) {
            NSMutableDictionary *output = [NSMutableDictionary dictionaryWithCapacity:[cals count]];
            NSEnumerator *enumerator = [cals objectEnumerator];
            NSDictionary *cal;
            while ((cal = [enumerator nextObject])) {
                [output setObject:[cal objectForKey:@"Color"] forKey:[cal objectForKey:@"Description"]];
            }
            return output;
        }
    }
    return nil;
}

- (IBAction)runABSelectSheet:(id)sender {
	[abPicker setValueSelectionBehavior: ABNoValueSelection];
	[abPicker setAllowsGroupSelection: NO];
	[abPicker setAllowsMultipleSelection: NO];
	[abPicker setTarget: self];
	[abPicker setNameDoubleAction: @selector(commitABSelectSheet:)];
	[abPicker setGroupDoubleAction: nil];
	
	[NSApp beginSheet: abSheet
	   modalForWindow: [self window]
		modalDelegate: nil didEndSelector: nil contextInfo: nil];
}

- (IBAction)commitABSelectSheet:(id)sender {
	[NSApp endSheet: abSheet];
	[abSheet orderOut: self];

	ABPerson *person = [[abPicker selectedRecords] objectAtIndex: 0];
	
    LJFriend *fr = [[friendsForSelectedGroupController selectedObjects] objectAtIndex:0];
	NSLog(@"Associating user %@ with AB card %@", [fr username], [person uniqueId]);
    [fr associateABRecord: person];
    [addressBookClearButton setEnabled: YES];	
}

- (IBAction)cancelABSelectSheet:(id)sender {
	[NSApp endSheet: abSheet];
	[abSheet orderOut: self];
}




// ----------------------------------------------------------------------------------------
// Menu item stuff
// ----------------------------------------------------------------------------------------
- (BOOL)validateMenuItem: (id <NSMenuItem>)item
{
    int tag = [item tag];

    if(tag == 1) { // Delete friend
        return [self canDeleteFriend];
    }
    else if(tag == 2) { // Remove friend from group
        return [self canRemoveFriendFromGroup];
    }
    else if(tag == 3) { // Remove Group
        return [self canDeleteGroup];
    }
    return YES;
}

- (BOOL)canDeleteGroup
{
    // Can delete a group as long as the group isn't all friends or rendezvousIsSelected
    return YES;
}

- (BOOL)canDeleteFriend
{
    // Can delete a friend only if All Friends is selected and a friend is selected
    return YES;
}

- (BOOL)canRemoveFriendFromGroup
{
    // Can remove a friend from a group if a friend is selected AND
    // a group other than Rendezvous and All Friends is selected
    return YES;
}
// ----------------------------------------------------------------------------------------
- (BOOL)windowShouldClose:(id)sender
{
    if([[self window] isDocumentEdited]) {
        NSBeginAlertSheet(NSLocalizedString(@"Do you want to save the changes you made to your friend groups?", @""),
                          NSLocalizedString(@"Save", @""),
                          NSLocalizedString(@"Don't Save", @""),
                          NSLocalizedString(@"Cancel", @""),
                          [self window],
                          self,
                          @selector(sheetDidEnd:returnCode:contextInfo:),
                          nil,
                          @"SaveSheet",
                          NSLocalizedString(@"Your changes will be lost if you don't save them.", @""));
        return NO;
    }
    return YES;
}

- (IBAction)refreshFriends: (id)sender {
	if([NetworkConfig destinationIsReachable:@"www.livejournal.com"]) {
		NS_DURING
			[[self account] downloadFriends];
		NS_HANDLER
			NSLog(@"Friends Download Exception");
		NS_ENDHANDLER
	}
}

- (void)dirtyWindow:(NSNotification *)note {
    [[self window] setDocumentEdited: YES];	
}
@end
