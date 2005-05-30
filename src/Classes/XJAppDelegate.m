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
#import "XJDonationWindowController.h"
#import "NSString+Extensions.h"
#import "XJGrowlManager.h"
#import "XJSyndicationData.h"
#import "NSString+Templating.h"
#import "XJScriptWindowController.h"
#import "XJFilePathToBaseNameValueTransformer.h"
#import "XJDockStatusItem.h"
#import "XJEditToolsController.h"

#import <ILCrashReporter/ILCrashReporter.h>
 
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
	if([self isExpired]) {
		int result = NSRunAlertPanel(@"Beta Version Expired",
									 @"This beta version of Xjournal has expired.  Please visit the Xjournal home page to download a newer version.",
									 @"Quit", @"Open Home Page", nil);
		
		if(result == NSAlertAlternateReturn) {
			[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://speirs.org/xjournal"]];
		}
		
		[NSApp terminate: self];
	}
	else {
		[XJPreferences installPreferences];
		[[ILCrashReporter defaultReporter]
	launchReporterForCompany:@"Fraser Speirs"
				  reportAddr:@"fraser@speirs.org"];
		
		[XJGrowlManager defaultManager];
	}
}

- (void)awakeFromNib
{	
	 [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(loginCompleted:)
                                                 name: LJAccountDidLoginNotification
                                               object: nil];

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

    
    /* Initialise the dock icon badge */
    dockItem = [[XJDockStatusItem alloc] initWithIcon: [NSImage imageNamed:@"usericon"]];

    /* Check for and create app support directories */
    [self checkForApplicationSupportDirs];
    
    /* Register the NNW Handlers */
     [[NSAppleEventManager sharedAppleEventManager]
        setEventHandler: self
        andSelector: @selector (editDataItem: withReplyEvent:)
        forEventClass: NNWEditDataItemAppleEventClass
        andEventID: NNWEditDataItemAppleEventID];
	 
	 /* Register the XJFilePathToBaseNameValueTransformer */
	 [NSValueTransformer setValueTransformer: [[[XJFilePathToBaseNameValueTransformer alloc] init] autorelease]
									 forName: @"XJFilePathToBaseNameValueTransformer"];
}

/*
 * Notification method that we use to start the login process
 */
- (void)applicationDidFinishLaunching: (NSNotification *)note
{
	if([[[XJAccountManager defaultManager] accounts] count] == 0) {
		firstAccountController = [[XJFAWizardController alloc] init];
		[firstAccountController showWindow:self];
	}
	
	if([XJPreferences showDonationWindow])
		[[XJDonationWindowController alloc] init];
	
	syncManager = [[XJHistorySyncManager alloc] init];
	
	[self updateDockMenu];
	
	// Reopen palettes that were open
	if([PREFS boolForKey: XJBookmarkWindowIsOpenPreference])
		[self showBookmarkWindow: self];
	
	if([PREFS boolForKey: XJGlossaryWindowIsOpenPreference])
		[self showGlossaryWindow: self];
	
	[[CCFSoftwareUpdate sharedUpdateChecker] runScheduledUpdateCheckIfRequired];
	[NSApp setServicesProvider:self];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    return YES;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication 
					hasVisibleWindows:(BOOL)flag
{
	return [[[XJAccountManager defaultManager] accounts] count] != 0;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	return [[[XJAccountManager defaultManager] accounts] count] != 0;	
}

- (void)loginCompleted: (NSNotification *)note {
	XJGrowlManager *gMan = [XJGrowlManager defaultManager];

	[gMan notifyWithTitle: @"Account Logged In" 
			  description: [[note object] username] 
		 notificationName: XJGrowlAccountDidLogInNotification
				   sticky: NO];
}

/* NetNewsWire Handler */
- (void) editDataItem: (NSAppleEventDescriptor *) event withReplyEvent: (NSAppleEventDescriptor *) reply {

	LJJournal *currentJournal = [[[XJAccountManager defaultManager] defaultAccount] defaultJournal];
	LJEntry *newPost = [[LJEntry alloc] init];	
	
	XJSyndicationData *synData = [XJSyndicationData syndicationDataWithAppleEvent: event];

	NSString *postBody = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] objectForKey: @"RSSFormatString"];
	postBody = [postBody stringByParsingTagsWithStartDelimeter: @"<$" endDelimeter: @"/>" usingObject: synData];
	
	NSString *postTitle = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] objectForKey: @"RSSSubjectFormatString"];
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

- (void)checkFriendsError: (NSNotification *)note
{
    NSException *exc = [[note userInfo] objectForKey: @"LJException"];
    NSLog(@"Check friends error: %@ - %@", [exc name], [exc reason]);
}

// Target for AppMenu -> Check for updates
- (IBAction)checkForUpdate:(id)sender
{
    [[CCFSoftwareUpdate sharedUpdateChecker] runSoftwareUpdate:NO];
}

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
	
    // Clean up
    [item setSubmenu: subMenu];
    [subMenu release];
    [dynDockMenu addItem: item];
    [item release];
}

/* Called whenever the Dock needs the app menu */
- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
    return dynDockMenu;
}

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

- (IBAction)showScriptsPalette: (id)sender
{
	if(!scriptsController) {
		scriptsController = [[XJScriptWindowController alloc] initWithWindowNibName: @"Scripts"];
	}
	[scriptsController showWindow: self];
}

- (IBAction)showToolsPalette:(id)sender {
	if(!toolsController) {
		toolsController = [[XJEditToolsController alloc] init];
	}
	[toolsController showWindow: self];
}

// Target for Edit -> Edit Last Entry
- (IBAction) editLastEntry:(id)sender
{
	LJJournal *currentJournal = [[[XJAccountManager defaultManager] defaultAccount] defaultJournal];
	LJEntry *lastEntry = [currentJournal getMostRecentEntry];
	NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    id doc = [docController openUntitledDocumentOfType: @"Xjournal Entry" display: NO];
    [doc setEntry: lastEntry];
    [doc showWindows];
}

- (IBAction)showPollEditWindow:(id)sender
{
    if(!pollController) {
        pollController = [[XJPollEditorController alloc] init];
    }
    [pollController showWindow: self];
}


// ----------------------------------------------------------------------------------------
// Notifications
// ----------------------------------------------------------------------------------------

/* Called from LJKit when the checked-for friends pages have been updated. */
- (void)friendsUpdated:(NSNotification *)aNotification
{
	NSLog(@"**** Friends page updated ****");
    // If the user wants a sound, play it.
    if([PREFS boolForKey: XJCheckFriendsShouldPlaySoundPreference]) {
        NSSound *snd = [PREFS objectForKey: XJCheckFriendsSelectedAlertSoundPreference];
        if(snd) [snd play];
    }

    // If they want a dock icon, show it.
    if([PREFS boolForKey: XJCheckFriendsShouldShowDockIconPreference]) {
        [dockItem show];
    }

    // If they want a dialog, show that too.
    if([PREFS boolForKey: XJCheckFriendsShouldShowDialogPreference]) {
		
		if([PREFS boolForKey: XJCheckFriendsShouldUseGrowlPreference]) {
			[[XJGrowlManager defaultManager] notifyWithTitle: @"Friends Page Updated"
												 description: [NSString stringWithFormat: @"%@'s friends page has changed", [[[aNotification object] account] username]]
																		notificationName: XJFriendsUpdatedGrowlNotification
																				  sticky: YES];
		}
		else {
			friendsDialogIsShowing = YES;
			int result = NSRunAlertPanel(LJ_FRIENDS_UPDATED_TITLE, LJ_FRIENDS_UPDATED_MSG, @"OK", LJ_FRIENDS_UPDATED_ALT_BUTTON, nil);
			friendsDialogIsShowing = NO;
			if(result == NSAlertAlternateReturn) {
				// alt button is "Open Friends Page"
				[[[XJAccountManager defaultManager] defaultAccount] launchFriendsPage];
			}
			
			// Hide the dock item.
			if(![dockItem isHidden])
				[dockItem hide];
		}
    }
	
	[[aNotification object] startChecking];
}

/* Actions for LJ menu items */
- (IBAction)openRecent: (id)sender
{
    [[[XJAccountManager defaultManager] defaultAccount] launchRecentEntries];
}

- (IBAction)openFriendsPage: (id)sender
{
    [[[XJAccountManager defaultManager] defaultAccount] launchFriendsPage];
}

- (IBAction)openUserInfo: (id)sender
{
    [[[XJAccountManager defaultManager] defaultAccount] launchUserInfo];
}

- (IBAction)openDonate: (id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"https://www.paypal.com/xclick/business=fraser%40speirs.org&item_name=Xjournal+Donations&no_note=1&tax=0&currency_code=USD"]];
}

- (IBAction) openDonationInfo: (id)sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.livejournal.com/community/xjournal/35968.html"]];
}

- (IBAction)openMarkdownReference: (id)sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://daringfireball.net/projects/markdown/syntax"]];	
}

/* Actions called from Dock menu */
- (IBAction)openURLFromDockMenu: (id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: [sender representedObject]];
}

- (IBAction)openFriendGroup: (id)sender
{
    LJGroup *group = [sender representedObject];
    [group launchMembersEntries];
    [dockItem hide];
}

/* Checks for (and creates if not found) the Application Support directories */
- (void)checkForApplicationSupportDirs
{
    BOOL isDir;
    NSFileManager *man = [NSFileManager defaultManager];
    if(![man fileExistsAtPath: GLOBAL_APPSUPPORT isDirectory: &isDir]) {
        [man createDirectoryAtPath: GLOBAL_APPSUPPORT attributes: nil];
    }

    if(![man fileExistsAtPath: LOCAL_APPSUPPORT isDirectory: &isDir]) {
        [man createDirectoryAtPath: LOCAL_APPSUPPORT attributes: nil];
    }
}

/*
 * Validation for some menu items, mostly to disable stuff when we're not logged in
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    int tag = [item tag];
    if(tag == kHistoryMenuTag) {
        // Must be logged in to use this menu items.
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

// Opens change notes and ReadMe
- (IBAction)openChangeNotes:(id)sender
{
    NSString *notesPath = [[NSBundle mainBundle] pathForResource: @"ChangeNotes" ofType: @"rtf"];
    [[NSWorkspace sharedWorkspace] openFile: notesPath];
}

- (IBAction)openReadMe: (id)sender
{
    NSString *readMePath = [[NSBundle mainBundle] pathForResource: @"ReadMe" ofType: @"rtf"];
    [[NSWorkspace sharedWorkspace] openFile: readMePath];
}

- (IBAction)openXjournalHomePage: (id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.speirs.org/xjournal"]];
}

- (IBAction)openXjournalBlog: (id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://www.livejournal.com/community/xjournal"]];   
}

// Services support
- (void)newJournalItem: (NSPasteboard *)pboard userData: (NSString *)userData error: (NSString **)error
{
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

+ (BOOL)isExpired {
	// Do expiry check
	NSCalendarDate *expiry = [NSCalendarDate dateWithYear: 2005
													month: 6
													  day: 30
													 hour: 12
												   minute: 00
												   second: 00 timeZone: nil];
	
	return [expiry timeIntervalSinceNow] <= 0;
}
@end
