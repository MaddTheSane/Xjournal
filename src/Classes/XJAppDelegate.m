//
//  XJAppDelegate.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJAppDelegate.h"
#import <LJKit/LJKit.h>
#import "XJPreferences.h"
#import "NetworkConfig.h"
#import "XJCheckFriendsSessionManager.h"
#import "XJAccountManager.h"
#import "CCFSoftwareUpdate.h"
#import "LJKit-URLLaunching.h"
#import "XJDocument.h"
#import "NSString+Extensions.h"
#import "XJMarkupRemovalVT.h"
#import "XJPreferencesController.h"
#import "XJSyndicationData.h"
#import "NSString+Templating.h"
#import "XJFontNameToDisplayVT.h"

#define PREF_LJ_ACCOUNTS @"preferences.accounts"

// Constant local strings
#define LJ_LOGIN_MESSAGE NSLocalizedString(@"Message from LiveJournal.com", @"")
#define LJ_FRIENDS_UPDATED_TITLE NSLocalizedString(@"Friends Updated", @"")
#define LJ_FRIENDS_UPDATED_MSG NSLocalizedString(@"Your friends page has been updated", @"")
#define LJ_FRIENDS_UPDATED_ALT_BUTTON NSLocalizedString(@"Open Friends Page", @"")

// Menu tags
#define kHistoryMenuTag 102
#define kFriendsMenuTag 103
#define kLoginMenuTag 104

// NetNewsWire Integration
const AEKeyword NNWEditDataItemAppleEventClass = 'EBlg';
const AEKeyword NNWEditDataItemAppleEventID = 'oitm';
const AEKeyword NNWDataItemTitle = 'titl';
const AEKeyword NNWDataItemDescription = 'desc';
const AEKeyword NNWDataItemSummary = 'summ';
const AEKeyword NNWDataItemLink = 'link';
const AEKeyword NNWDataItemPermalink = 'plnk';
const AEKeyword NNWDataItemSubject = 'subj';
const AEKeyword NNWDataItemCreator = 'crtr';
const AEKeyword NNWDataItemCommentsURL = 'curl';
const AEKeyword NNWDataItemGUID = 'guid';
const AEKeyword NNWDataItemSourceName = 'snam';
const AEKeyword NNWDataItemSourceHomeURL = 'hurl';
const AEKeyword NNWDataItemSourceFeedURL = 'furl';

@implementation XJAppDelegate
+ (void)initialize {
	// Register user defaults
	NSDictionary *defs = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"ApplicationDefaults" ofType: @"plist"]];
	// You have to do both of the following, apparently
	// http://www.cocoabuilder.com/archive/message/cocoa/2004/4/27/105492
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defs];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defs];
		
	[NSValueTransformer setValueTransformer: [[[XJMarkupRemovalVT alloc] init] autorelease] forName: @"XJMarkupRemoval"];
	[NSValueTransformer setValueTransformer: [[[XJFontNameToDisplayVT alloc] init] autorelease] forName: @"XJFontNameToDisplay"];
}

- (void)awakeFromNib
{	
    /* To find out when the login process will start, so we can show the progress dialog */
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(loginStarted:)
                                                 name: LJAccountWillLoginNotification
                                               object: nil];

    /* Need to know whether login succeeds or fails.  In both cases, we dismiss the progress dialog. */
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(loginCompleted:)
                                                 name: LJAccountDidLoginNotification
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginFailed:)
                                                    name:LJAccountDidNotLoginNotification
                                                  object:nil];

    /* Register to get checkfriends update notifications */
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(friendsUpdated:)
                                                 name: LJFriendsPageUpdatedNotification
                                               object: nil];

    /* Register to get checkfriends update errors */
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(checkFriendsError:)
                                                 name: LJCheckFriendsErrorNotification
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildAccountsMenu:)
                                                 name:XJAccountAddedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildAccountsMenu:)
                                                 name:XJAccountWillRemoveNotification
                                               object:nil];

    /* Check for and create app support directories */
    [self checkForApplicationSupportDirs];
    
    /* Register the NNW Handlers */
     [[NSAppleEventManager sharedAppleEventManager]
        setEventHandler: self
        andSelector: @selector (editDataItem: withReplyEvent:)
        forEventClass: NNWEditDataItemAppleEventClass
        andEventID: NNWEditDataItemAppleEventID];
}

#pragma mark -
#pragma mark NSApplicationDelegate
/*
 * Notification method that we use to start the login process
 */
- (void)applicationDidFinishLaunching: (NSNotification *)note
{
    XJAccountManager *acctManager = [XJAccountManager defaultManager];
    // Check that we've got a username to log into
    if(![acctManager defaultAccount]) {
        // Show the initial-run username and password dialog
        [self showAccountEditWindow: self];
        [accountController addAccount: self];
    }
    else {
        [XJCheckFriendsSessionManager sharedManager]; // Initialise the shared session

        // Once accounts support other LJ services, we should move these reachability tests into the login method
		BOOL shouldLogin = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJShouldAutoLogin"] boolValue];
        if(shouldLogin && [NetworkConfig destinationIsReachable: @"www.livejournal.com"]) {
            NS_DURING

                [acctManager logInAccount: [acctManager defaultAccount]];
                if([[acctManager defaultAccount] isLoggedIn])
					[[acctManager defaultAccount] downloadFriends];
                // Be a good client and show the LiveJournal login message, if any
                NSString *serverMsg = [[acctManager loggedInAccount] loginMessage];
                if(serverMsg != nil && 
				   ![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJSuppressLoginMessage"] boolValue])
                    NSRunAlertPanel(LJ_LOGIN_MESSAGE, serverMsg, @"OK", nil, nil);
            NS_HANDLER
                NSRunAlertPanel([localException name], [localException reason], @"OK", nil, nil);
            NS_ENDHANDLER
        }
    }
    [self updateDockMenu];
    [self buildAccountsMenu: nil];

    // Reopen palettes that were open
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJBookmarkWindowIsOpen"] boolValue])
        [self showBookmarkWindow: self];

    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJGlossaryWindowIsOpen"] boolValue])
        [self showGlossaryWindow: self];

    [[CCFSoftwareUpdate sharedUpdateChecker] runScheduledUpdateCheckIfRequired];
    [NSApp setServicesProvider:self];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender { return YES; }

#pragma mark -
#pragma mark NetNewsWire Protocol Handler

	/* NetNewsWire Handler */
- (void) editDataItem: (NSAppleEventDescriptor *) event withReplyEvent: (NSAppleEventDescriptor *) reply {
	
	LJJournal *currentJournal = [[[XJAccountManager defaultManager] defaultAccount] defaultJournal];
	LJEntry *newPost = [[LJEntry alloc] init];	
	
	XJSyndicationData *synData = [XJSyndicationData syndicationDataWithAppleEvent: event];
	NSString *postBody = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] valueForKey: @"XJRSSFormatString"];
	postBody = [postBody stringByParsingTagsWithStartDelimeter: @"<$" endDelimeter: @"/>" usingObject: synData];
	
	NSString *postTitle = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] valueForKey: @"XJRSSSubjectFormatString"];
	postTitle = [postTitle stringByParsingTagsWithStartDelimeter: @"<$" endDelimeter: @"/>" usingObject: synData];
	
	[newPost setSubject: postTitle];
	[newPost setContent: postBody];
	
	NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    id doc = [docController openUntitledDocumentOfType: @"Xjournal Entry" display: NO];
    [doc setEntry: newPost];
    [newPost setJournal: currentJournal];
    [doc showWindows];
	
    [NSApp activateIgnoringOtherApps: YES];
} /*editDataItem: withReplyEvent:*/

#pragma mark -
#pragma mark Handling Checkfriends Error
- (void)checkFriendsError: (NSNotification *)note
{
    NSException *exc = [[note userInfo] objectForKey: @"LJException"];
    NSLog(@"Check friends error: %@ - %@", [exc name], [exc reason]);
}

#pragma mark -
#pragma mark Software Update
// Target for AppMenu -> Check for updates
- (IBAction)checkForUpdate:(id)sender { [[CCFSoftwareUpdate sharedUpdateChecker] runSoftwareUpdate:NO]; }

#pragma mark -
#pragma mark Dock Menu Handling
- (void)updateDockMenu
{
    /*
     The dock menu looks like:
     + Compose New Entry
     + Open Friends Page
     -
     - %d Updated Friends Groups:
     + FG1
     ...
     + FGn

     ... or it would, if the protocol allowed...
     */
    NSMenuItem *item, *subItem;

    // Release the dock menu if we have one
    if(dynDockMenu)
        [dynDockMenu release];

    dynDockMenu = [[NSMenu alloc] initWithTitle: @""];

    // Create the New Entry item at the top level
    item = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Compose New Entry", @"") action: @selector(newDocument:) keyEquivalent: @""];
    [dynDockMenu addItem: item];
    [item release];

    // Create the top-level Friend page item....
    item = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Friends Page", @"") action: @selector(openFriendsPage:) keyEquivalent: @""];

    // Create a submenu...
    NSMenu *subMenu = [[NSMenu alloc] initWithTitle: @""];

    // And an item to atach it to
    subItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"All Friends", @"") action: @selector(openFriendsPage:) keyEquivalent: @""];
    [subMenu addItem: subItem];
    [subItem release];

    if([[XJAccountManager defaultManager] loggedInAccount]) {
        // Only add friends if we have them.....
        [subMenu addItem: [NSMenuItem separatorItem]];
    
        // Now, add an item for each group
        NSEnumerator *enu = [[[[XJAccountManager defaultManager] defaultAccount] groupArray] objectEnumerator];
        LJGroup *grp;
        while(grp = [enu nextObject]) {
            subItem = [[NSMenuItem alloc] initWithTitle: [grp name] action: @selector(openFriendGroup:) keyEquivalent: @""];
            [subItem setRepresentedObject: grp];
            [subMenu addItem: subItem];
            [subItem release];
        }
    }

    // Clean up
    [item setSubmenu: subMenu];
    [subMenu release];
    [dynDockMenu addItem: item];
    [item release];
}

/* Called whenever the Dock needs the app menu */
- (NSMenu *)applicationDockMenu:(NSApplication *)sender{ return dynDockMenu; }

#pragma mark -
#pragma mark Dock Icon Handling
- (void)showDockBadge {
	NSImage *appIcon = [NSImage imageNamed: @"NSApplicationIcon"];
	NSImage *starburst = [NSImage imageNamed: @"starburst"];
	NSImage *bufferImage = [[NSImage alloc] initWithSize:[appIcon size]];

	NSPoint starburstPoint = NSMakePoint([bufferImage size].height-[starburst size].height,
										 [bufferImage size].width-[starburst size].width);
	
	[bufferImage setFlipped: YES];
	[bufferImage lockFocus];
	[appIcon compositeToPoint:NSMakePoint(0, [bufferImage size].height) operation:NSCompositeSourceOver];
	[starburst compositeToPoint: starburstPoint operation:NSCompositeSourceOver];
	[bufferImage unlockFocus];
	
	[NSApp setApplicationIconImage: bufferImage];
	[bufferImage autorelease];
	
	[self setShowingDockBadge: YES];
}

- (void)hideDockBadge {
	[NSApp setApplicationIconImage: [NSImage imageNamed: @"NSApplicationIcon"]];	
	[self setShowingDockBadge: NO];
}

- (BOOL)showingDockBadge { return showingDockBadge; }
- (void)setShowingDockBadge:(BOOL)flag { showingDockBadge = flag; }

#pragma mark -
#pragma mark Accounts Menu Handling
- (void) buildAccountsMenu: (NSNotification *)note
{
	if([accountItem hasSubmenu]) {
		NSMenu *oldSub = [[accountItem submenu] retain];
		[accountItem setSubmenu: nil];
		[oldSub release];
	}
	
	NSMenu *newSubmenu = [[NSMenu alloc] init];
	NSDictionary *accounts = [[XJAccountManager defaultManager] accounts];
	NSArray *dictionaryKeys = [[accounts allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	int i;
	for(i=0; i < [dictionaryKeys count]; i++) {
		NSString *key = [dictionaryKeys objectAtIndex: i];
		LJAccount *acc = [accounts objectForKey: key];
		
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: [acc username] action: @selector(switchAccount:) keyEquivalent: @""];
        [item setTarget: nil];
        [item setRepresentedObject: acc];
		
		if([[XJAccountManager defaultManager] loggedInAccount] && 
		   [[acc username] isEqualToString: [[[XJAccountManager defaultManager] loggedInAccount] username]])
		{
            [item setState: NSOnState];
		}
        else {
            // If there's no logged in account, set to the default account
            if(![[XJAccountManager defaultManager] loggedInAccount] && [[acc username] isEqualToString: [[XJAccountManager defaultManager] defaultUsername]])
                [item setState: NSOnState];
        }
		[newSubmenu addItem: item];
		[item release];
	}

    [newSubmenu addItem: [NSMenuItem separatorItem]];
    
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Edit Accounts", @"")
												  action: @selector(showWindow:)
										   keyEquivalent: @""];

    // Make sure the account window controller is initialised here
    if(!accountController)
        accountController = [[XJAccountEditWindowController alloc] init];
    [item setTarget: accountController];

    [newSubmenu addItem: item];
    [item release];
	
	[accountItem setSubmenu: newSubmenu];
	[newSubmenu release];
}

#pragma mark -
#pragma mark WindowController Initialisation
/*
 * The following show*Window methods are used to initialise
 * (if required) the subsidiary window controllers and to
 * show their windows
 */
- (IBAction)showPrefsWindow:(id)sender
{
	if(!prefsController)
		prefsController = [[XJPreferencesController alloc] init];
	[prefsController showWindow: self];
}

- (IBAction)showBookmarkWindow:(id)sender
{
    if(!bookmarkController) {
        bookmarkController = [[XJBookmarksWindowController alloc] init];
    }
    [bookmarkController showWindow: self];
}

- (IBAction)showHistoryWindow:(id)sender
{
    if(!histController) {
        histController = [[XJHistoryWindowController alloc] init];
    }
    [histController showWindow: self];
}

- (IBAction)showFriendsWindow:(id)sender
{
    if(!friendController) {
        friendController = [[XJFriendsController alloc] init];
    }
    [friendController showWindow: self];
}

- (IBAction)showGlossaryWindow:(id)sender
{
    if(!glossaryController) {
        glossaryController = [[XJGlossaryWindowController alloc] init];
    }
    [glossaryController showWindow: self];
}

- (IBAction)showAccountEditWindow:(id)sender
{
    if(!accountController) {
        accountController = [[XJAccountEditWindowController alloc] init];
    }
    [accountController showWindow: self];
}

- (IBAction)showPollEditWindow:(id)sender
{
    if(!pollController) {
        pollController = [[XJPollEditorController alloc] init];
    }
    [pollController showWindow: self];
}

#pragma mark -
#pragma mark Edit Last Entry Menu Handler
// Target for Edit -> Edit Last Entry
- (IBAction) editLastEntry:(id)sender
{
	LJJournal *currentJournal = [[[XJAccountManager defaultManager] loggedInAccount] defaultJournal];
	LJEntry *lastEntry = [currentJournal getMostRecentEntry];
	NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    id doc = [docController openUntitledDocumentOfType: @"Xjournal Entry" display: NO];
    [doc setEntry: lastEntry];
    [doc showWindows];
}



// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Switching accounts
// ----------------------------------------------------------------------------------------
- (IBAction)switchAccount: (id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: XJAccountSwitchedNotification object: [sender representedObject]];
	[[XJAccountManager defaultManager] logInAccount: [sender representedObject]];
    [self buildAccountsMenu: nil];
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Notifications
// ----------------------------------------------------------------------------------------
/* Called when the user clicks on the dock icon */
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	NSLog(@"applicationShouldHandleReopen");
    // If the dock icon is showing, ir (friendsDialogIsShowing=YES) we open the friends page
    // and we DON'T open a new window
    if([self showingDockBadge]) {
        if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJCheckFriendsShouldOpenFriendsPage"] boolValue])
            [[[XJAccountManager defaultManager] defaultAccount] launchFriendsPage];
        
		[self hideDockBadge];
        [self updateDockMenu];
        
        // User operated here, so restart checkfriends
        [[XJCheckFriendsSessionManager sharedManager] startCheckingFriends];
        return NO;
    }
	[self hideDockBadge];
    return YES;
}

/* Called from LJKit when the checked-for friends pages have been updated. */
- (void)friendsUpdated:(NSNotification *)aNotification
{
    // If the user wants a sound, play it.
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJCheckFriendsPlaySound"] boolValue]) {
		NSString *path = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJCheckFriendsAlertSound"];
		NSSound *snd = [[NSSound alloc] initWithContentsOfFile: path byReference: NO];
        if(snd) [snd play];
    }

    // If they want a dock icon, show it.
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJCheckFriendsShouldShowDockIcon"] boolValue]) {
		[self showDockBadge];
    }

    // If they want a dialog, show that too.
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJCheckFriendsShouldShowDialog"] boolValue]) {
        friendsDialogIsShowing = YES;
        int result = NSRunAlertPanel(LJ_FRIENDS_UPDATED_TITLE, LJ_FRIENDS_UPDATED_MSG, @"OK", LJ_FRIENDS_UPDATED_ALT_BUTTON, nil);
        friendsDialogIsShowing = NO;
        if(result == NSAlertAlternateReturn) {
            // alt button is "Open Friends Page"
            [[[XJAccountManager defaultManager] defaultAccount] launchFriendsPage];
        }

        // User operated here, so restart checkfriends
		[self hideDockBadge];
        [[XJCheckFriendsSessionManager sharedManager] startCheckingFriends];
    }
}

/* Notifications about login beginning and ending */
- (void)loginStarted:(NSNotification *)notification
{
     [loginPanel makeKeyAndOrderFront: self];
    [spinner setUsesThreadedAnimation: YES];
    [spinner startAnimation:self];
}

- (void)loginCompleted: (NSNotification *)notification
{
    [spinner stopAnimation:self];
    [loginPanel orderOut: nil];
    [self updateDockMenu];
}

- (void)loginFailed: (NSNotification *)notification
{
    [spinner stopAnimation:self];
    [loginPanel orderOut: nil];
}

// -----------------------------------------
#pragma mark -
#pragma mark Actions for LJ menu items
// -----------------------------------------
- (IBAction)openRecent: (id)sender {
    [[[XJAccountManager defaultManager] defaultAccount] launchRecentEntries];
}

- (IBAction)openFriendsPage: (id)sender {
    [[[XJAccountManager defaultManager] defaultAccount] launchFriendsPage];
}

- (IBAction)openUserInfo: (id)sender {
    [[[XJAccountManager defaultManager] defaultAccount] launchUserInfo];
}

// -----------------------------------------
#pragma mark -
#pragma mark Actions for Dock Menu
// -----------------------------------------
- (IBAction)openURLFromDockMenu: (id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [sender representedObject]];
}

- (IBAction)openFriendGroup: (id)sender {
    LJGroup *group = [sender representedObject];
    [group launchMembersEntries];
	[self hideDockBadge];
}

// -----------------------------------------
#pragma mark -
#pragma mark Application Support Directories
// -----------------------------------------
/* Checks for (and creates if not found) the Application Support directories */
- (void)checkForApplicationSupportDirs {
    BOOL isDir;
    NSFileManager *man = [NSFileManager defaultManager];
    if(![man fileExistsAtPath: GLOBAL_APPSUPPORT isDirectory: &isDir]) {
        [man createDirectoryAtPath: GLOBAL_APPSUPPORT attributes: nil];
    }

    if(![man fileExistsAtPath: LOCAL_APPSUPPORT isDirectory: &isDir]) {
        [man createDirectoryAtPath: LOCAL_APPSUPPORT attributes: nil];
    }
}

// -----------------------------------------
#pragma mark -
#pragma mark Action for login menu item
// -----------------------------------------
- (IBAction)logIn:(id)sender {
    XJAccountManager *man = [XJAccountManager defaultManager];
    if(![man defaultAccount]) {
        int result = NSRunCriticalAlertPanel(NSLocalizedString(@"No accounts defined", @""),
                                             NSLocalizedString(@"Please define at least one account before attempting to log in", @""),
                                             NSLocalizedString(@"OK", @""),
                                             NSLocalizedString(@"Open Accounts Window", @""),
                                             nil);

        if(result == NSAlertAlternateReturn)
            [self showAccountEditWindow: self];
    }
    else {
        if([NetworkConfig destinationIsReachable:@"www.livejournal.com"])
            [man logInAccount: [man defaultAccount]];
        else
            [NetworkConfig showUnreachableDialog];
    }
}

// -----------------------------------------
#pragma mark -
#pragma mark Menu Item Validation
// -----------------------------------------
/*
 * Validation for some menu items, mostly to disable stuff when we're not logged in
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    int tag = [item tag];
    if(tag == kHistoryMenuTag) {
        // Must be logged in to use this menu items.
        //return [[[XJAccountManager defaultManager] defaultAccount] isLoggedIn];
        return YES;
    }
    else if(tag == kFriendsMenuTag) {
        // Must be logged in to use this menu items.
        return [[[XJAccountManager defaultManager] defaultAccount] isLoggedIn];
    }
    else if(tag == kLoginMenuTag) {
        // Must be logged out to use this menu items.
        return ![[[XJAccountManager defaultManager] defaultAccount] isLoggedIn];
    }
    else {
        return YES;
    }
}

// -----------------------------------------
#pragma mark -
#pragma mark Menu Items to open Change Notes, ReadMe and URLs
// -----------------------------------------
// Opens change notes and ReadMe
- (IBAction)openChangeNotes:(id)sender {
    NSString *notesPath = [[NSBundle mainBundle] pathForResource: @"ChangeNotes" ofType: @"rtf"];
    [[NSWorkspace sharedWorkspace] openFile: notesPath];
}

- (IBAction)openReadMe: (id)sender {
    NSString *readMePath = [[NSBundle mainBundle] pathForResource: @"ReadMe" ofType: @"rtf"];
    [[NSWorkspace sharedWorkspace] openFile: readMePath];
}

- (IBAction)openLicense: (id)sender {
    NSString *readMePath = [[NSBundle mainBundle] pathForResource: @"CFPSL_1_0" ofType: @"rtf"];
    [[NSWorkspace sharedWorkspace] openFile: readMePath];
}

- (IBAction)openXjournalHomePage: (id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.speirs.org/xjournal"]];
}

- (IBAction)openXjournalBlog: (id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://www.livejournal.com/community/xjournal"]];   
}

// -----------------------------------------
#pragma mark -
#pragma mark Services
// -----------------------------------------
// Services support
- (void)newJournalItem: (NSPasteboard *)pboard userData: (NSString *)userData error: (NSString **)error {
    NSString *pboardString;
    NSArray *types;
    
    types = [pboard types];
    if (![types containsObject:NSStringPboardType]) {
        *error = NSLocalizedString(@"Error: couldn't create Xjournal entry.",
                                   @"pboard couldn't give string.");
        return;
    }
    pboardString = [pboard stringForType:NSStringPboardType];
    if (!pboardString) {
        *error = NSLocalizedString(@"Error: couldn't create Xjournal entry.",
                                   @"pboard couldn't give string.");
        return;
    }
    
    LJEntry *entry = [[LJEntry alloc] init];
    [entry setContent:pboardString];
    
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    XJDocument *doc = (XJDocument *)[docController openUntitledDocumentOfType: @"Xjournal Entry" display: NO];
    [doc setEntry: entry];
    [doc showWindows];
    [doc updateChangeCount:NSChangeDone];
    [entry release];
}
@end
