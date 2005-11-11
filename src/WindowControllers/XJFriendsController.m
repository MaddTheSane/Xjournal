#import "XJFriendsController.h"
#import <LJKit/LJKit.h>
#import "XJAccountManager.h"
#import "XJFriendsController-NSToolbarController.h"
#import "XJPreferences.h"
#import <AddressBook/AddressBook.h>
#import "LJFriend-ABExtensions.h"
#import <Foundation/NSDebug.h>

#import "NetworkConfig.h"

#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (254.0 / 255.0)

#define kViewAllFriends 100
#define kViewUsersOnly 101
#define kViewCommunitiesOnly 102

#define kFriendsAutosaveName @"kFriendsAutosaveName"

enum {
    XJColumnSortedAscending = 0,
    XJColumnSortedDescending,
    XJColumnNotSorted
};

@implementation XJFriendsController

- (id)init
{
	self = [super initWithWindowNibName: @"NewFriendsWindow"];
    if(self) {
        viewType = kViewAllFriends;
        
        [self refreshFriends: nil];

        sortSettings = [[NSMutableDictionary dictionaryWithCapacity: 30] retain];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(addressBookDropped:)
                                                     name: XJAddressCardDroppedNotification
                                                   object:nil];
        
        userinfo = [NSImage imageNamed: @"userinfo"];
        folder = [NSImage imageNamed: @"OpenFolder"];
        community = [NSImage imageNamed: @"communitysmall"];
        birthday = [NSImage imageNamed: @"Birthday"];
    }
	return self;
}

- (void)windowDidLoad
{
    [[self window] setFrameAutosaveName: kFriendsAutosaveName];
    
    [self setUpToolbar]; // see the NSToolbarController category
    
    // Configure the icon column to display images
    NSTableColumn *tc = [friendsTable tableColumnWithIdentifier:@"icon"];
    id cell = [[NSImageCell alloc] init];
    [cell setImageScaling:NSScaleNone];
    [tc setDataCell:cell];
    tc = [groupTable tableColumnWithIdentifier: @"icon"];
    [tc setDataCell:cell];

    // Configure the table for drag and drop
    [groupTable registerForDraggedTypes: [NSArray arrayWithObjects: @"LJFriend", NSStringPboardType, nil]];

    sortedColumn = [friendsTable tableColumnWithIdentifier: @"username"];
    sortDirection = XJColumnSortedAscending;

    // Set the table for double click
    [friendsTable setTarget: self];
    [friendsTable setDoubleAction:@selector(openSelectedFriendsJournal:)];
    
    // Set up the account popup menu
    NSMenu *popMenu = [accountToolbarPopup menu];
    [popMenu removeAllItems];
    NSEnumerator *accountItems = [[XJAccountManager defaultManager] menuItemEnumerator];
    NSMenuItem *item;

    while(item = [accountItems nextObject]) {
        [popMenu addItem: item];
        if([item state] == NSOnState) {
            // Enumerator vends them with the logged in account item in NSOnState
            [item setState: NSOffState];
            [accountToolbarPopup selectItem: item];
            [self setCurrentAccount: [item representedObject]];
        }
    }

    [[self window] setTitle: [NSString stringWithFormat: @"%@ - %@", NSLocalizedString(@"Friends", @""), [[self account] username]]];
    
    [groupTable selectRow: 0 byExtendingSelection: NO];
    [self updateFriendTableCache];

    [self sortFriendTableCacheOnColumn: sortedColumn direction: sortDirection];
    
    [self refreshWindow: nil];
    [self updateTabs];
    
    //Configure some WebView stuff
    [recentEntriesView setPolicyDelegate: self];
    [recentEntriesView setFrameLoadDelegate: self];
    [userInfoView setPolicyDelegate: self];
    [userInfoView setFrameLoadDelegate: self];
}

- (NSArray *)inspectedObjects
{
    return [NSArray arrayWithObjects: [self selectedFriend], nil];
}

- (LJAccount *)account
{ 
    return account;
}

- (void)setCurrentAccount: (LJAccount *)acct
{
    account = acct;
	if(![account isLoggedIn])
		[[XJAccountManager defaultManager] logInAccount: account];
}

- (IBAction)switchAccount: (id)sender
{
    [self setCurrentAccount: [sender representedObject]];

    [[self window] setTitle: [NSString stringWithFormat: @"%@ - %@", NSLocalizedString(@"Friends", @""), [[self account] username]]];

    // Update cache
    [self updateFriendTableCache];

    // Sort it
    sortedColumn = [friendsTable tableColumnWithIdentifier: @"username"];
    sortDirection = XJColumnSortedAscending;
    [groupTable selectRow: 0 byExtendingSelection: NO];
    [self sortFriendTableCacheOnColumn: sortedColumn direction: sortDirection];

    // Reload
    [self refreshWindow: nil];
    [self updateTabs];
}

- (IBAction)setViewType: (id)sender {
    viewType = [sender tag];
    // Reload
    [self updateFriendTableCache];
    [self sortFriendTableCacheOnColumn: sortedColumn direction: sortDirection];
    [self refreshWindow: nil];
    [self updateTabs];
}
// ----------------------------------------------------------------------------------------
// IB Actions
// ----------------------------------------------------------------------------------------
- (IBAction)addFriend:(id)sender
{
    if([friendsTable numberOfSelectedRows] == 1 && [[self selectedFriend] friendship] == LJIncomingFriendship )
		[friendField setStringValue: [[self selectedFriend] username]];
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
        modalDelegate: self
       didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo: @"groupSheet"];
}

- (IBAction)deleteSelectedFriend: (id)sender
{
    LJFriend *friend = [self selectedFriend];
    if(!friend) return;
    [[self account] removeFriend: friend];

    [self updateFriendTableCache];
    [self sortFriendTableCacheOnColumn: sortedColumn direction:sortDirection];
    [[self window] setDocumentEdited: YES];
    [self refreshWindow: nil];
    [self updateTabs];
}

- (IBAction)removeSelectedFriendFromGroup: (id)sender
{
    LJGroup *theGroup = [self selectedGroup];
    if(!theGroup) return;

    LJFriend *theFriend = [self selectedFriend];
    if(!theFriend) return;

    [theGroup removeFriend: theFriend];

    [self updateFriendTableCache];
    [[self window] setDocumentEdited: YES];
    [self refreshWindow: nil];
    [self updateTabs];
}

- (IBAction)deleteSelectedGroup: (id)sender
{
    LJGroup *grp = [self selectedGroup];
    if(!grp) return;
    
    [[self account] removeGroup: grp];
    [groupTable selectRow: 0 byExtendingSelection: NO];
    
    [[self window] setDocumentEdited: YES];
    [self refreshWindow: nil];
    [self updateTabs];
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
        if([[friendField stringValue] length] <= 0)
            return;
        
        [[self account] addFriendWithUsername: [friendField stringValue]];
    }
    else {
        if([[groupField stringValue] length] <= 0)
            return;
        [[self account] newGroupWithName: [groupField stringValue]];
    }

    [self cancelSheet: self];

    [self updateFriendTableCache];
    [self sortFriendTableCacheOnColumn: sortedColumn direction: sortDirection];
    [[self window] setDocumentEdited: YES];
    [self refreshWindow: nil];
}

- (IBAction)setForegroundColor: (id)sender
{
	int numberSelected = [friendsTable numberOfSelectedRows];
	if(numberSelected == 1) {
		LJFriend *selFriend = [self selectedFriend];
		if(selFriend) {
			[selFriend setForegroundColor: [sender color]];
		}
	} else {
		NSEnumerator *selectedFriends = [[self selectedFriendArray] objectEnumerator];
		LJFriend *friend;
		while(friend = [selectedFriends nextObject]) {
			[friend setForegroundColor: [sender color]];
		}
	}
	
	[[self window] setDocumentEdited: YES];
	[self refreshWindow: nil];
	[fullName setTextColor: [sender color]];
}

- (IBAction)setBackgroundColor: (id)sender
{
	
	int numberSelected = [friendsTable numberOfSelectedRows];
	if(numberSelected == 1) {
		LJFriend *selFriend = [self selectedFriend];
		if(selFriend) {
			[selFriend setBackgroundColor: [sender color]];
		}
	} else {
		NSArray *friendArr = [self selectedFriendArray];
		NSEnumerator *selectedFriends = [friendArr objectEnumerator];
		LJFriend *friend;
		while(friend = [selectedFriends nextObject]) {
			[friend setBackgroundColor: [sender color]];
		}
	}
	
	[[self window] setDocumentEdited: YES];
	[self refreshWindow: nil];
	[fullName setBackgroundColor: [sender color]];
}

- (IBAction)removeAddressCard: (id)sender
{
    LJFriend *selectedFriend = [self selectedFriend];
    if(!selectedFriend) return;

    [selectedFriend unassociateABRecord];
    [self updateTabs];
}

- (IBAction)openSelectedFriendsJournal: (id)sender
{
    LJFriend *selectedFriend = [self selectedFriend];
    if(!selectedFriend) return;

    [[NSWorkspace sharedWorkspace] openURL: [selectedFriend recentEntriesHttpURL]];
}

- (IBAction)openSelectedFriendsProfile: (id)sender
{
    LJFriend *selectedFriend = [self selectedFriend];
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
// ----------------------------------------------------------------------------------------
- (void)refreshWindow: (NSNotification *)note
{
    [friendsTable reloadData];
    [groupTable reloadData];
}

- (void)updateFriendTableCache
{
    LJAccount *userAccount = [self account];
    
    [friendTableCache release];
    friendTableCache = [[NSMutableArray arrayWithCapacity: 100] retain];

    if([self allFriendsIsSelected]) {
        /*
         The point of this Dictionary nonsense is that it's an efficient
         way to combine two sets with a common subset.

         friendArray may contain  [0, 1, 3, 5]
         friendOfArray may contain [2, 4, 5, 6]

         Simply adding the contents of both arrays will result in 5 being
         duplicated.  We key each friend to their username in a dictionary
         then take the array of all values.

         The 5 from friendArray will have been overwritten by the 5 from
         friendOfArray.
         */
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        NSEnumerator *enumerator = [[userAccount friendArray] objectEnumerator];
        id friend;

        while (friend = [enumerator nextObject]) {
            [dictionary setObject: friend forKey: [friend username]];
        }

        enumerator = [[userAccount friendOfArray] objectEnumerator];

        while (friend = [enumerator nextObject]) {
            [dictionary setObject: friend forKey: [friend username]];
        }

        if(viewType == kViewAllFriends) { // all
            [friendTableCache addObjectsFromArray: [dictionary allValues]];
        }
        else if(viewType == kViewUsersOnly) { // Uers only
            NSEnumerator *enumerator = [[dictionary allValues] objectEnumerator];
            LJFriend *obj;
            while(obj = [enumerator nextObject]) {
                if(![[obj accountType] isEqualToString: @"community"])
                    [friendTableCache addObject: obj];
            }
        }
        else { // Communities only
            NSEnumerator *enumerator = [[dictionary allValues] objectEnumerator];
            LJFriend *obj;
            while(obj = [enumerator nextObject]) {
                if([[obj accountType] isEqualToString: @"community"])
                    [friendTableCache addObject: obj];
            }
        }
    }
    else if(![self allFriendsIsSelected]) {
        if(viewType == kViewAllFriends) { // all
            [friendTableCache addObjectsFromArray: [[self selectedGroup] memberArray]];
        }
        else if(viewType == kViewUsersOnly) { // Uers only
            NSEnumerator *enumerator = [[[self selectedGroup] memberArray] objectEnumerator];
            LJFriend *obj;
            while(obj = [enumerator nextObject]) {
                if(![[obj accountType] isEqualToString: @"community"])
                    [friendTableCache addObject: obj];
            }
        }
        else { // Communities only
            NSEnumerator *enumerator = [[[self selectedGroup] memberArray] objectEnumerator];
            LJFriend *obj;
            while(obj = [enumerator nextObject]) {
                if([[obj accountType] isEqualToString: @"community"])
                    [friendTableCache addObject: obj];
            }
        }
    }
}

- (void)sortFriendTableCacheOnColumn: (NSTableColumn *)column direction: (int)direction
{
    if([[column identifier] isEqualToString: @"icon"]) {
        if(direction == XJColumnSortedAscending || direction == XJColumnNotSorted)
            [friendTableCache sortUsingSelector: @selector(compareUserCommunity:)];
        else
            [friendTableCache sortUsingSelector: @selector(compareUserCommunityDescending:)];
    }
    
    else if([[column identifier] isEqualToString: @"username"]) {
        if(direction == XJColumnSortedAscending || direction == XJColumnNotSorted)
            [friendTableCache sortUsingSelector: @selector(compareUsername:)];
        else
            [friendTableCache sortUsingSelector: @selector(compareUsernameDescending:)];
    }
    
    else if([[column identifier] isEqualToString: @"fullname"]) {
        if(direction == XJColumnSortedAscending || direction == XJColumnNotSorted)
            [friendTableCache sortUsingSelector: @selector(compareFullName:)];
        else
            [friendTableCache sortUsingSelector: @selector(compareFullNameDescending:)];        
    }
    if([[column identifier] isEqualToString: @"relationship"]) {
        if(direction == XJColumnSortedAscending || direction == XJColumnNotSorted)
            [friendTableCache sortUsingSelector: @selector(compareRelationship:)];
        else
            [friendTableCache sortUsingSelector: @selector(compareRelationshipDescending:)];     
    }
}

- (void) addressBookDropped: (NSNotification *)note
{
    NSArray *addressUIDs = [note object];
    if([addressUIDs count] == 0) return;
    
    ABRecord *person = [[ABAddressBook sharedAddressBook] recordForUniqueId: [addressUIDs objectAtIndex:0]];

    NSString *firstName = [person valueForProperty: kABFirstNameProperty];
    NSString *lastName = [person valueForProperty: kABLastNameProperty];

    [addressBookName setStringValue: [NSString stringWithFormat: @"%@ %@", firstName, lastName]];

    if([person isKindOfClass: [ABPerson class]]) {
        NSData *imageData = [(ABPerson *)person imageData];
        NSImage *img = [[NSImage alloc] initWithData: imageData];
        [addressBookImageWell setImage: img];
    }

    [[self selectedFriend] associateABRecord: person];
    [addressBookClearButton setEnabled: YES];
}

- (IBAction)addSelectedFriendToAddressBook: (id)sender
{
    LJFriend *sFriend = [self selectedFriend];
    if(sFriend && ![sFriend hasAddressCard])
        [sFriend addAddressCardAndEdit: YES];
    [self updateTabs];
}

- (IBAction)launchChatSession: (id)sender
{
    LJFriend *friend = [self selectedFriend];
    NSString *chatURL = [friend chatURL];
    if(chatURL)
        [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: chatURL]];
}

// ----------------------------------------------------------------------------------------
// Sheet handling
// ----------------------------------------------------------------------------------------
- (void)sheetDidEnd: (NSWindow *)sheet returnCode: (int)code contextInfo: (void *)contextInfo
{
    if([sheet isEqualTo: friendSheet]) {}
    else if([sheet isEqualTo: groupSheet]) {}
    else {
        // save sheet
        if(code == NSAlertDefaultReturn) { // Save
            [[self window] setDocumentEdited: NO];
            [[self window] close];
        }
        else if(code == NSAlertOtherReturn) { // Cancel
           
        }
        else {
            // Don't save
            [[self window] setDocumentEdited: NO];
            [self updateTabs];
            [[self window] close];
            [[self account] downloadFriends];
        }
    }
}

// ----------------------------------------------------------------------------------------
// Table stuff
// ----------------------------------------------------------------------------------------
- (LJGroup *)selectedGroup // Which group is selected in the group table?
{
    LJAccount *userAccount = [self account];
    int index = [groupTable selectedRow];

    if(index < 1)
        return nil;

    return [[userAccount groupArray] objectAtIndex: index-1];
}

- (LJGroup *)groupForRow:(int)row // What group is at the given row?
{
    LJAccount *userAccount = [self account];

    if(row == 0)
        return nil;

    return [[userAccount groupArray] objectAtIndex: row-1];
}

- (BOOL)allFriendsIsSelected // Returns YES if the All Friends item in the group table is selected
{
    return [groupTable selectedRow] == 0;
}

- (LJFriend *) selectedFriend {
    int index = [friendsTable selectedRow];
    if(index == -1) return nil; // No selection, return nil
    if([friendsTable numberOfSelectedRows] > 1) return nil;
    if(![self allFriendsIsSelected] ) {
        LJGroup *selectedGroup = [self selectedGroup];
        if(!selectedGroup) return nil;
        
        return [friendTableCache objectAtIndex: index];
    }
    else {
        return [friendTableCache objectAtIndex: [friendsTable selectedRow]];
    }
}

- (NSArray *)selectedFriendArray {
	NSMutableArray *friends = [[NSMutableArray array] retain];
	NSEnumerator *rowEnum = [friendsTable selectedRowEnumerator];
	int i;
	while(i = [[rowEnum nextObject] intValue]) {
		[friends addObject: [friendTableCache objectAtIndex:i]];
	}
	return [friends autorelease];
}

// ----------------------------------------------------------------------------------------
// Notifications
// ----------------------------------------------------------------------------------------

// Sent by NSTableView whenever something is selected
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    LJAccount *userAccount = [self account];
    
    if([[aNotification object] isEqualTo: groupTable]) {
        // If the group table changes, just reload the friends table.
        NSArray *sortInfo = nil;

        if([groupTable selectedRow] == 0)
            sortInfo = [sortSettings objectForKey: @"kAllFriendsXjournalItem"];
        else if([groupTable selectedRow] == -1) {
            [friendsTable selectRow: -1 byExtendingSelection: NO];
            [friendsTable reloadData];
            return;
        }
        else {
            NSString *theGroupName = [[[userAccount groupArray] objectAtIndex: [groupTable selectedRow]-1] name];
            sortInfo = [sortSettings objectForKey: theGroupName];
        }

        [self updateFriendTableCache];
        if(sortInfo) {
            NSTableColumn *columnToBeSortedOn = [friendsTable tableColumnWithIdentifier: [sortInfo objectAtIndex: 0]];
            int directionToSortIn = [[sortInfo objectAtIndex:1] intValue];
            
            [self sortFriendTableCacheOnColumn: columnToBeSortedOn direction: directionToSortIn];

            // Clear the currently sorted column
            [friendsTable setIndicatorImage: nil inTableColumn: sortedColumn];
            [friendsTable setHighlightedTableColumn: columnToBeSortedOn];
            
            if(directionToSortIn == XJColumnSortedAscending)
                [friendsTable setIndicatorImage: [NSImage imageNamed: @"NSAscendingSortIndicator"] inTableColumn: columnToBeSortedOn];
            else
                [friendsTable setIndicatorImage: [NSImage imageNamed: @"NSDescendingSortIndicator"] inTableColumn: columnToBeSortedOn];

            sortedColumn = columnToBeSortedOn;
            sortDirection = directionToSortIn;
        }
        else {
            NSTableColumn *columnToBeSortedOn = [friendsTable tableColumnWithIdentifier: @"username"];
            
            [self sortFriendTableCacheOnColumn: columnToBeSortedOn direction: XJColumnSortedAscending];

            // Clear the currently sorted column
            [friendsTable setIndicatorImage: nil inTableColumn: sortedColumn];
            [friendsTable setHighlightedTableColumn: columnToBeSortedOn];
            [friendsTable setIndicatorImage: [NSImage imageNamed: @"NSAscendingSortIndicator"] inTableColumn: columnToBeSortedOn];

            sortedColumn = columnToBeSortedOn;
            sortDirection = XJColumnSortedAscending;
        } 

        [friendsTable selectRow: -1 byExtendingSelection: NO];
        [friendsTable reloadData];
    }
    else {
        // If the friends table changes selection, need to work out the selected friend and reload the drawer.
        [self updateTabs];
    }
}

- (void)updateTabs
{
	int numSelected = [[friendsTable selectedRows] count];
	BOOL isMultiple = numSelected > 1;
	
	
    if(isMultiple) {
		NSString *placeHolder = [NSString stringWithFormat: @"(%d selected)", numSelected];
		[fullName setBackgroundColor: [NSColor clearColor]];
		[fullName setTextColor: [NSColor blackColor]];
		[fullName setStringValue: placeHolder];
		
		// DoB
		[dateOfBirth setStringValue: placeHolder]; 
		[iCalButton setEnabled: NO];
		
		// AB
		[addressBookImageWell setImage: [NSImage imageNamed: @"NewPerson"]];
		[addressBookName setStringValue: placeHolder];
		[addressBookName setEnabled: NO];
		[addressBookClearButton setEnabled: NO];
		// Disable dragging an AB card
		[addressBookImageWell setAcceptsDrags:NO];
		
		// Color Wells
		[fgWell setColor: [NSColor blackColor]];
		[bgWell setColor: [NSColor whiteColor]];
		
	} else {
		LJFriend *selFriend = [self selectedFriend];
		
		if([NetworkConfig destinationIsReachable:@"www.livejournal.com"]) {
			[[recentEntriesView mainFrame] loadRequest: [NSURLRequest requestWithURL:[selFriend recentEntriesHttpURL]]];
			[[userInfoView mainFrame] loadRequest: [NSURLRequest requestWithURL:[selFriend userProfileHttpURL]]];
		}
		
		[fullName setStringValue: (selFriend!=nil) ? [selFriend fullname] : @""];
    
		// Birthdate
		NSDate *date = [selFriend birthDate];
		if(date) {
			[dateOfBirth setStringValue: [date descriptionWithCalendarFormat: [[NSUserDefaults standardUserDefaults] objectForKey: NSShortDateFormatString] 
																	timeZone: nil 
																	  locale: nil]];
			[iCalButton setEnabled: YES];   
		}
		else {
			[dateOfBirth setStringValue: NSLocalizedString(@"not defined", @"")];
			[iCalButton setEnabled: NO];
		}
    
		if(selFriend) {
			[fgWell setColor: [selFriend foregroundColor]];
			[bgWell setColor: [selFriend backgroundColor]];
			
			NSColor *fg = [selFriend foregroundColor], *bg = [selFriend backgroundColor];
			if(fg)
				[fullName setTextColor:fg];
			else
				[fullName setTextColor: [NSColor blackColor]];
			
			if(bg)
				[fullName setBackgroundColor: bg];
			else
				[fullName setBackgroundColor: [NSColor clearColor]];
			
		}
		else {
			[fgWell setColor: [NSColor blackColor]];
			[bgWell setColor: [NSColor whiteColor]];
		}
    
		// Address Book
		// Enable dragging an AB card
		[addressBookImageWell setAcceptsDrags:YES];
		
		if([selFriend hasAddressCard]) {
			NSImage *friendImage = [selFriend abImage];
			if(!friendImage)
				friendImage = [NSImage imageNamed: @"NoABCard"];
			
			[addressBookImageWell setImage: friendImage];
			
			[addressBookName setStringValue: [selFriend abName]];
			[addressBookName setEnabled: YES];
			[addressBookClearButton setEnabled: YES];
		}
		else {
			[addressBookImageWell setImage: [NSImage imageNamed: @"NewPerson"]];
			[addressBookName setStringValue: NSLocalizedString(@"no address card", @"")];
			[addressBookName setEnabled: NO];
			[addressBookClearButton setEnabled: NO];
		}    
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
    [[self selectedFriend] addBirthdayToCalendarNamed: [calPopup titleOfSelectedItem]];
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

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    if(![frame isEqualTo: [sender mainFrame]])
        return;
    
    if([sender isEqualTo: recentEntriesView])
        [recentSpinner startAnimation: self];
    else 
        [userInfoSpinner startAnimation: self];
}

// This is called when the webview has finished loading - avoids switching artifacts
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if([sender isEqualTo: recentEntriesView])
        [recentSpinner stopAnimation: self];
    else 
        [userInfoSpinner stopAnimation: self];
}

// ----------------------------------------------------------------------------------------
// NSTableDataSource
// ----------------------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    LJAccount *userAccount = [self account];
    
    if([aTableView isEqualTo: groupTable]) {
        return [[userAccount groupArray] count] + 1;
    }
    else {
        if([self allFriendsIsSelected]) {
            return [friendTableCache count];
        }
        else {
            LJGroup *selectedGroup = [self selectedGroup];
            if(!selectedGroup) return 0; // Nil == no selection in left table
            return [friendTableCache count];
        }
    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    LJAccount *userAccount = [self account];
    NSString *columnIdentifier = [aTableColumn identifier];

    if([aTableView isEqualTo: groupTable]) {
        if(rowIndex == 0) { // 0th row is the "all friends" item
            if([columnIdentifier isEqualToString: @"icon"]) {
                return userinfo;
            }
            else
                return NSLocalizedString(@"All Friends", @"");
        }
        else {
            int arrayIndex = rowIndex - 1;
            NSArray *groupArray = [userAccount groupArray];

            if([columnIdentifier isEqualToString: @"icon"]) {
                return folder;
            }
            else {
                return [[groupArray objectAtIndex: arrayIndex] name]; 
            }
        }
    }
    else {
        NSArray *arrayOfFriends;
        if([self allFriendsIsSelected]) {
            arrayOfFriends = [userAccount friendArray];
        }
        else {
            LJGroup *selectedGroup = [self selectedGroup];
            if(!selectedGroup) return 0; // Nil == no selection in left table
            arrayOfFriends = [selectedGroup memberArray];
        }
          
        LJFriend *thisFriend = [friendTableCache objectAtIndex: rowIndex];

        if([columnIdentifier isEqualToString: @"icon"]) {
            if([[thisFriend accountType] isEqualToString: @"community"])
                return community;
            else {
                if([thisFriend birthdayIsToday])
                    return birthday;
                else
                    return userinfo;
            }
        }
        else if([[aTableColumn identifier] isEqualToString: @"username"])
            return [thisFriend username];
        else if([[aTableColumn identifier] isEqualToString: @"fullname"])
            return [thisFriend fullname];
        else if([[aTableColumn identifier] isEqualToString: @"relationship"]) {
            int rel = [thisFriend friendship];
            switch(rel) {
                case LJIncomingFriendship:
                    return NSLocalizedString(@"Incoming", @"");
                case LJOutgoingFriendship:
                    return NSLocalizedString(@"Outgoing", @"");
                case LJMutualFriendship:
                    return NSLocalizedString(@"Mutual", @"");
            }
        }
        
    }
    return @"";
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if([aTableView isEqualTo: friendsTable]) {
        LJFriend *friend;
        
        if([self allFriendsIsSelected]) {
            friend = [friendTableCache objectAtIndex: rowIndex];
        }
        else {
            if(![self selectedGroup]) {
                if([[aTableColumn identifier] isEqualToString: @"username"])
                    [aCell setDrawsBackground: NO];
                return;
            }
            else {
                friend = [friendTableCache objectAtIndex: rowIndex];
            }
        }
        
        if([[aTableColumn identifier] isEqualToString: @"username"]) {
            [aCell setDrawsBackground: YES];
            [aCell setBackgroundColor: [friend backgroundColor]];
            [aCell setTextColor: [friend foregroundColor]];
        } else if(![[aTableColumn identifier] isEqualToString: @"icon"]){
            [aCell setDrawsBackground: NO];
            [aCell setTextColor: [NSColor blackColor]];
        }
    }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if([aTableView isEqualTo: groupTable]) {
        if([[aTableColumn identifier] isEqualToString: @"groupname"]) {
            if(rowIndex > 1) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    LJGroup *grp = [self selectedGroup];
    NSAssert(grp != nil, @"Something really wierd is going on here");

    [grp setName: anObject];

    [[self window] setDocumentEdited: YES];
    [self refreshWindow: nil];
}

- (BOOL) tableView: (NSTableView *)aTableView writeRows: (NSArray *)rows toPasteboard: (NSPasteboard *)pb
{
    NSArray *arrayOfFriends;
    if([self allFriendsIsSelected]) {
        arrayOfFriends = friendTableCache;
    }
    else {
        LJGroup *selectedGroup = [self selectedGroup];
        if(!selectedGroup) return 0; // Nil == no selection in left table
        arrayOfFriends = friendTableCache;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [rows objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        int theRow = [object intValue];
        LJFriend *thisFriend = [arrayOfFriends objectAtIndex: theRow];
        [array addObject: [thisFriend username]];
    }

    [pb declareTypes: [NSArray arrayWithObjects: @"LJFriend", NSStringPboardType, nil] owner: self];

    NSMutableData *data;
    NSKeyedArchiver *archiver;

    data = [NSMutableData data];
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    // Customize archiver here
    [archiver encodeObject:array forKey: @"LJFriend"];
    [archiver finishEncoding];
    [archiver release];

    NSMutableString *string = [NSMutableString stringWithCapacity:100];
    enumerator = [array objectEnumerator];
    NSString *userName;
    while(userName = [enumerator nextObject]) {
        [string appendString: [NSString stringWithFormat: @"<lj user=\"%@\">, ", userName]];
    }
    NSString *userString = [string substringToIndex: [string length]-2]; // Hack to take off the last comma-space
    
    return [pb setData: data forType: @"LJFriend"] && [pb setData: [userString dataUsingEncoding: NSUTF8StringEncoding] forType: NSStringPboardType];
    
}

- (NSDragOperation)tableView: (NSTableView *)tableView validateDrop: (id <NSDraggingInfo>)info proposedRow: (int)row proposedDropOperation: (NSTableViewDropOperation)op
{
    if(row > 0 && row < [self numberOfRowsInTableView: tableView]) {
        [tableView setDropRow: row dropOperation: NSTableViewDropOn];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)tableView: (NSTableView *)tableView acceptDrop: (id <NSDraggingInfo>)info row: (int)row dropOperation: (NSTableViewDropOperation)op
{
    NSPasteboard *pb = [info draggingPasteboard];
    NSData *data = [pb dataForType: @"LJFriend"];

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSArray *friendArray = [[unarchiver decodeObjectForKey:@"LJFriend"] retain];
    [unarchiver finishDecoding];
    [unarchiver release];

    NSEnumerator *enumerator = [friendArray objectEnumerator];
    id object;

    LJAccount *acct = [self account];
    LJGroup *group = [self groupForRow: row];
    while (object = [enumerator nextObject]) {
        // Check that the friend is not just an incoming friendshup
		LJFriend *friendToAdd = [acct friendNamed:object];
		if([friendToAdd friendship] != LJIncomingFriendship)
			[group addFriend: [acct friendNamed: object]];
    }

    [[self window] setDocumentEdited: YES];
    return YES;
}

// from XJKeyHandlingTableView
- (void)handleDeleteKeyInTableView: (NSTableView *)aTableView
{
    if([aTableView isEqualTo: friendsTable]) {
        if([self allFriendsIsSelected]) {
            [self deleteSelectedFriend: self];
        }
        else if([self selectedGroup]) {
            LJGroup *grp = [self selectedGroup];
            [grp removeFriend: [self selectedFriend]];

            [self refreshWindow: nil];
            [self updateTabs];
            [[self window] setDocumentEdited: YES];
        }
    }
}

- (void) tableView: (NSTableView *) tableView didClickTableColumn: (NSTableColumn *) tableColumn
{
    if([tableView isEqualTo: groupTable]) return; // Don't sort the group view
    
    if([tableColumn isEqualTo: sortedColumn]) {
        if(sortDirection == XJColumnSortedDescending)
            sortDirection = XJColumnSortedAscending;
        else
            sortDirection = XJColumnSortedDescending;
    }
    else {
        // Unset the prior sorted column
        [tableView setIndicatorImage: nil inTableColumn: sortedColumn];
        
        sortDirection = XJColumnSortedAscending;
        sortedColumn = tableColumn;
    }

    // Hilight the sorted column
    [tableView setHighlightedTableColumn: sortedColumn];
    
    switch(sortDirection) {
        case XJColumnSortedAscending:
            [tableView setIndicatorImage: [NSImage imageNamed: @"NSAscendingSortIndicator"] inTableColumn: sortedColumn];
            break;
        case XJColumnSortedDescending:
            [tableView setIndicatorImage: [NSImage imageNamed: @"NSDescendingSortIndicator"] inTableColumn: sortedColumn];
            break;
    }

    // Ideally, we want to keep the same row selected after re-sort, so we'll store the selected friend
    LJFriend *selectedFriendBeforeSort = [self selectedFriend];
    
    [self sortFriendTableCacheOnColumn: sortedColumn direction: sortDirection];

    NSString *selectedGroupName;
    if([self allFriendsIsSelected])
        selectedGroupName = @"kAllFriendsXjournalItem";
    else
        selectedGroupName = [[self selectedGroup] name];

    [sortSettings setObject: [NSArray arrayWithObjects: [tableColumn identifier], [NSNumber numberWithInt: sortDirection], nil] forKey: selectedGroupName];
    
    [tableView reloadData];

    if(selectedFriendBeforeSort) {
        int theIndex = [friendTableCache indexOfObject: selectedFriendBeforeSort];
        [friendsTable selectRow: theIndex byExtendingSelection: NO];
        [friendsTable scrollRowToVisible: theIndex];
    }
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
    return ![self allFriendsIsSelected]; /*([self rendezvousIsSelected] ||*/ 
}

- (BOOL)canDeleteFriend
{
    // Can delete a friend only if All Friends is selected and a friend is selected
    return [self allFriendsIsSelected] && [self selectedFriend] != nil;
}

- (BOOL)canRemoveFriendFromGroup
{
    // Can remove a friend from a group if a friend is selected AND
    // a group other than Rendezvous and All Friends is selected
    return ![self allFriendsIsSelected] && ([self selectedFriend] != nil);
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
                          nil,
                          NSLocalizedString(@"Your changes will be lost if you don't save them.", @""));
        return NO;
    }
    return YES;
}

// ----------------------------------------------------------------------------------------
// WebView delegates
// ----------------------------------------------------------------------------------------
- (void) webView: (WebView *) sender  decidePolicyForNavigationAction: (NSDictionary *) actionInformation request: (NSURLRequest *) request frame: (WebFrame *) frame decisionListener: (id<WebPolicyDecisionListener>) listener
{
    int key = [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue];
    switch(key){
        case WebNavigationTypeLinkClicked:
            // Since a link was clicked, we want WebKit to ignore it
            [listener ignore];
            // Instead of opening it in the WebView, we want to open
            // the URL in the user's default browser
            [[NSWorkspace sharedWorkspace] openURL: [actionInformation objectForKey:WebActionOriginalURLKey]];
            break;
        default:
            [listener use];
            // You could also call [listener download] here.
    }
}

- (IBAction)refreshFriends: (id)sender {
	if([NetworkConfig destinationIsReachable:@"www.livejournal.com"]) {
		NS_DURING
			[[self account] downloadFriends];
			[self refreshWindow:nil];
		NS_HANDLER
			NSLog(@"Friends Download Exception");
		NS_ENDHANDLER
	}
}
@end
