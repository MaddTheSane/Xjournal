//
//  XJHistoryWindowController.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJHistoryWindowController.h"
#import "XJPreferences.h"
#import <LJKit/LJKit.h>
#import "XJDay.h"
#import "NSString+Extensions.h"
#import "LJEntryExtensions.h"
#import "XJAccountManager.h"
#import "XJDocument.h"
#import "NSDocumentController-CustomDocs.h"
#import "NetworkConfig.h"

#define kHistoryWindowToolbarIdentifier @"history.toolbar" 
#define kHistoryOpenItemIdentifier @"history.open.item"
#define kHistoryEditItemIdentifier @"history.edit.item"
#define kHistoryDeleteItemIdentifier @"history.delete.item"
#define kHistorySearchItemIdentifier @"kHistorySearchItemIdentifier"
#define kHistoryDownloadItemIdentifier @"kHistoryDownloadItemIdentifier"
#define kHistoryRefreshItemIdentifier @"kHistoryRefreshItemIdentifier"

#define kHistoryAutosaveName @"kHistoryAutosaveName"

#define CACHED_HISTORY_PATH [@"~/Library/Application Support/Xjournal/History.plist" stringByExpandingTildeInPath]

#define XJHistoryDownloadMadeProgressNotification @"XJHistoryDownloadMadeProgressNotification"
#define XJHistoryDownloadCompletedNotification @"XJHistoryDownloadCompletedNotification"
#define XJHistoryDownloadFailedNotification @"XJHistoryDownloadFailedNotification"

#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (254.0 / 255.0)

enum {
    XJHistorySearchResultSelected = 0,
    XJHistoryEntrySelected,
    XJHistoryDaySelected,
    XJHistoryMonthSelected,
    XJHistoryYearSelected,
    XJHistoryEmptySelection,
    XJHistorySearchGroupSelected
};

@interface XJHistoryWindowController (PrivateAPI)
- (void)showEncodingErrorSheetForDate: (NSCalendarDate *)date;
- (void)showGenericErrorSheet: (NSString *)message;

 - (int)browserSelectionType;
- (BOOL)columnZeroSelectionIsYear;
- (LJEntry *)selectedEntry;
- (XJDay *)selectedDay;
- (XJMonth *)selectedMonth;
- (XJYear *)selectedYear;

- (NSString *)selectedSearchString;
- (NSArray *)selectedSearchResultRoot;
- (LJEntry *)selectedSearchResult;

- (NSURL *)urlForBrowserSelection;

- (void)editEntry: (LJEntry *)entryToEdit;

- (NSString *)zeroizedString:(int)number;
@end

@implementation XJHistoryWindowController 

- (id)init
{
    if(self = [super initWithWindowNibName:@"HistoryWindow"]) {
        historyIsComplete = NO;
        userHasDeclinedDownload = NO;
        terminateDownloadThread = NO;
        downloadInProgress = NO;

        updateIsComplete = NO;
        userHasDeclinedUpdate = NO;
        terminateUpdateThread = NO;

        [[self window] setFrameAutosaveName: kHistoryAutosaveName];
                
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newEntryPosted:)
                                                     name:XJEntryEntryPostedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(historyDownloadFailed:)
                                                     name: XJHistoryDownloadFailedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadFinished:)
                                                            name:XJHistoryDownloadCompletedNotification
                                                          object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateHistoryDownloadProgress:)
                                                     name:XJHistoryDownloadMadeProgressNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name: NSApplicationWillTerminateNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(entryEdited:)
                                                     name:XJEntryEditedNotification
                                                   object:nil];

        // HTML view stuff
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotNotification:) name:NULL object:NULL];
        
        searchCache = [[NSMutableDictionary dictionaryWithCapacity: 10] retain];
        
        cal = [[XJCalendar alloc] init];
        
        if(![self loadCachedHistory]) {
            userHasDeclinedDownload = ![self analyzeDayCounts];
            if(userHasDeclinedDownload) {
                userHasDeclinedUpdate = YES;
                NSRunCriticalAlertPanel(NSLocalizedString(@"Network Error", @""),
                                        NSLocalizedString(@"Could not contact the server to get your post counts.  Please try again later.", @""),
                                        NSLocalizedString(@"OK", @""),nil,nil);
            }
        }

        selectedSearchType = XJSearchEntirePost;
        
        [browser loadColumnZero];
        
        return self;
    }
    return nil;
}

- (void)applicationWillTerminate: (NSNotification *)note
{
    [cal writeToFile: CACHED_HISTORY_PATH atomically: YES];
}

- (BOOL)loadCachedHistory
{
    NSFileManager *man = [NSFileManager defaultManager];
    BOOL isDir;
    if([man fileExistsAtPath: CACHED_HISTORY_PATH isDirectory: &isDir] && !isDir) {
        [cal configureWithContentsOfFile: CACHED_HISTORY_PATH];
        historyIsComplete = YES;
        return YES;
    }
    return NO;
}

- (void)windowDidLoad
{
    // Set up NSToolbar
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: kHistoryWindowToolbarIdentifier];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDelegate: self];
    [[self window] setToolbar: toolbar];
    [toolbar release];

    [browser setTarget: self];
    [browser setDoubleAction: @selector(editSelectedEntry:)];

    [webView setFrameLoadDelegate: self];
    [webView setPolicyDelegate: self];
    [webView setPreferencesIdentifier: XJ_HISTORY_PREF_IDENT];
    [[webView preferences] setAutosaves: YES];
}

- (LJAccount *)account
{
    return account;
}

- (void)setCurrentAccount: (LJAccount *)newAcct
{
    account = newAcct;
}

- (NSString *)historyArchivePath
{
    return [NSString stringWithFormat: [@"~/Library/Application Support/Xjournal/%@.plist" stringByExpandingTildeInPath], [[self account] username]];
}

/*
 - (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    BOOL didShowDLSheet = NO;
    
    if(!downloadInProgress && !userHasDeclinedDownload && !historyIsComplete) {
        NSBeginInformationalAlertSheet(NSLocalizedString(@"Download History", @""),
                                       NSLocalizedString(@"Download", @""),
                                       NSLocalizedString(@"Cancel", @""),
                                       nil,
                                       [self window],
                                       self,
                                       @selector(sheetDidEnd:returnCode:contextInfo:),
                                       nil,
                                       @"downloadHistory",
                                       NSLocalizedString(@"Do you want to download your LiveJournal History?  This could take a long time.", @""));
        didShowDLSheet = YES;
    }
    if(!didShowDLSheet) {
        if(!userHasDeclinedDownload && !downloadInProgress && !updateInProgress && !userHasDeclinedUpdate && !updateIsComplete) {
            NSBeginInformationalAlertSheet(NSLocalizedString(@"Update History", @""),
                                           NSLocalizedString(@"Update", @""),
                                           NSLocalizedString(@"Cancel", @""),
                                           nil,
                                           [self window],
                                           self,
                                           @selector(sheetDidEnd:returnCode:contextInfo:),
                                           nil,
                                           @"updateHistory",
                                           NSLocalizedString(@"Do you want to update your LiveJournal History?  This could take a little while.", @""));
        }
    }
    
    
     //if(downloadInProgress)
       // [self beginHistoryDownload: self];
    //else if(updateInProgress)
      //  [self beginHistoryUpdate: self];
}
*/
- (IBAction)deleteSelectedEntry:(id)sender
{
    NSBeginAlertSheet(@"Delete Journal Entry", @"Cancel", @"Delete", nil, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), nil, @"deleteEntry",
                      NSLocalizedString(@"Are you sure you want to delete the selected entry from your journal?  This cannot be undone.", @""));
}

// DidEndHandler for the delete confirmation sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSString *cmd = (NSString *)contextInfo;

    if([cmd isEqualToString: @"downloadHistory"]) {
        switch(returnCode) {
            case NSAlertDefaultReturn:
                downloadInProgress = YES;
                [self beginHistoryDownload: self];
                break;
            default:
                userHasDeclinedDownload = YES;
                return;
        }
    }
    else if([cmd isEqualToString: @"updateHistory"]) {
        switch(returnCode) {
            case NSAlertDefaultReturn:
                updateInProgress = YES;
                [self beginHistoryUpdate: self];
                break;
            default:
                userHasDeclinedUpdate = YES;
                return;
        }
    }
    else if([cmd isEqualToString: @"textEncoding"]) {
        switch(returnCode) {
            case NSAlertAlternateReturn:
                [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.livejournal.com/editinfo.bml"]];
                break;
                // do nothing on default return
        }
    }
    else  { // delete sheet
        if(returnCode == NSAlertAlternateReturn) {
			int selectionType = [self browserSelectionType];
			if(selectionType == XJHistorySearchResultSelected) {
				LJEntry *entryToDelete = [self selectedSearchResult];
				XJDay *day = [cal dayForCalendarDate: [[entryToDelete date] dateWithCalendarFormat:nil timeZone:nil]];
				NS_DURING
					[day deleteEntry: entryToDelete];
				NS_HANDLER
					NSLog(@"Connection Reset During Delete");
				NS_ENDHANDLER
				[self executeSearchForString: [self selectedSearchString]];
			}
			else {
				XJDay *day = [self selectedDay];
				NS_DURING
					[day deleteEntryAtIndex: [browser selectedRowInColumn:3]];
				NS_HANDLER
					NSLog(@"Connection Reset During Delete");
				NS_ENDHANDLER
				int row = [browser selectedRowInColumn: 2];
				[browser selectRow: row inColumn: 2];
				//[browser reloadColumn: [browser lastVisibleColumn]];
				[self setStatus: @""];
			}
        }
    }
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSString *cmd = (NSString *)contextInfo;
    if([cmd isEqualToString: @"downloadHistory"]) {
        userHasDeclinedDownload = YES;
    }
    else if([cmd isEqualToString: @"updateHistory"]){
        userHasDeclinedUpdate = YES;
    }
    else { // Text encoding sheet
        
    }
}

- (BOOL)analyzeDayCounts
{
    if([NetworkConfig destinationIsReachable: @"www.livejournal.com"]) {
        NSEnumerator *dates;
        NSCalendarDate *date;
        NSDictionary *tempDayCounts;
        
        // Cocoa (erroneously) believes we might fall through the NS_DURING loop,
        // and wants this variable 'nil'd so as to ensure it's not uninitialized memory.
        //      --sparks
        tempDayCounts = nil;
        
        NS_DURING
            tempDayCounts = [[[[XJAccountManager defaultManager] defaultAccount] defaultJournal] getDayCounts];
            [dayCounts release];
            dayCounts = nil;
            dayCounts = tempDayCounts;
            
            dates = [[dayCounts allKeys] objectEnumerator];
            
            while(date = [dates nextObject]) {
                XJDay *day = [cal dayForCalendarDate: date];
                [day setPostCount: [[dayCounts objectForKey: date] intValue]];
            }
        NS_HANDLER
            NSLog(@"getDayCounts failed");
        NS_ENDHANDLER
        return tempDayCounts != nil;
    }
    return NO;
}

// Search
- (IBAction)executeSearch:(id)sender {
	[self executeSearchForString: [sender stringValue]];
	[sender showCancelButton: YES];
}

- (void)executeSearchForString: (NSString *)target
{
    NSArray *results = [cal entriesContainingString: target searchType: selectedSearchType];
    [searchCache setObject: results forKey: target];

    // Get the index of the search
    int rowToSelect = [[searchCache allKeys] indexOfObject: target] + [cal numberOfYears];
    [browser loadColumnZero];
    [browser selectRow: rowToSelect inColumn: 0];
    //[browser becomeFirstResponder];
}

- (IBAction)clearSearch:(id)sender
{
    int base = [browser selectedRowInColumn: 0] - [cal numberOfYears];
    NSString *searchKey = [[searchCache allKeys] objectAtIndex: base];

    [searchCache removeObjectForKey: searchKey];
    [browser loadColumnZero];
}

- (IBAction)setSearchType:(id)sender
{
    [selectedMenuItem setState: NSOffState];
    [sender setState: NSOnState];
    selectedSearchType = [sender tag];
    selectedMenuItem = sender;
}

- (IBAction)editSelectedEntry: (id)sender
{

    LJEntry *entryToEdit = nil;
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    
    switch([self browserSelectionType]) {
		case XJHistoryEntrySelected:
        	entryToEdit = [self selectedEntry];
        	break;
		case XJHistorySearchResultSelected:
			entryToEdit = [self selectedSearchResult];
			break;
    	case XJHistoryDaySelected:
    	{
    		XJDay *day = [self selectedDay];
    		[[NSWorkspace sharedWorkspace] openURL: [day urlForDayArchiveForAccount: acct]];
    		break;
    	}
	    case XJHistoryMonthSelected:
	    {
	    	XJMonth *month = [self selectedMonth];
			[[NSWorkspace sharedWorkspace] openURL: [month urlForMonthArchiveForAccount: acct]];
	    	break;
		}
    	case XJHistoryYearSelected:
    	{
    		XJYear *year = [self selectedYear];
			[[NSWorkspace sharedWorkspace] openURL: [year urlForYearArchiveForAccount: acct]];    		
    		break;
		}
	}
    if(entryToEdit)
		[self editEntry: entryToEdit];
}

// Editing last entry
- (void)editLastEntry
{
	LJEntry *mrp = [cal mostRecentPost];
	NSAssert(mrp != nil, @"Most recent post from calendar is nil!");
    [self editEntry: mrp];
}

// ----------------------------------------------------------------------------------------
// Browser delegate
// ----------------------------------------------------------------------------------------
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column
{
    if(column == 0) {
        // return years;
        return [cal numberOfYears] + [[searchCache allKeys] count];
    }
    else if(column == 1) {
        // return months in year, or number of search results
        if([self browserSelectionType] == XJHistoryYearSelected)
            return [[self selectedYear] numberOfMonths];

        else {
            return [[self selectedSearchResultRoot] count];
        }
    }
    else if(column == 2) {
        if([self browserSelectionType] == XJHistoryMonthSelected) {
            // return days in month
            return [[self selectedMonth] numberOfDays];
        }else {
            return 0; // nothing in days column for a search result
        }
        
    }
    else if(column == 3) {
        // return subjects for day
        if([self browserSelectionType] == XJHistoryDaySelected) {
            return [[self selectedDay] postCount];
        } else {
            return 0;
        }
    }

    return 0;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column
{
    // Switch on Column
    switch(column){
        // Col 0 = showing years and search result roots
        case 0:
            if(row < [cal numberOfYears]) {
                XJYear *year = [cal yearAtIndex: row];
                [cell setTitle: [NSString stringWithFormat: @"%d", [year yearName]]];
                [cell setImage: nil];
            }
            else {
                int base = row - [cal numberOfYears];
                [cell setTitle: [[searchCache allKeys] objectAtIndex: base]];
                [cell setImage: [NSImage imageNamed: @"Magnifier"]];
            }
            [cell setLeaf: NO];
            break;

        case 1:
            // Col 1 = showing months and search result entries

            /* Probably need a selectedRowInColumnZero method or some such */
            if([self columnZeroSelectionIsYear]) {
                // Showing months
                XJMonth *selectedMonth = [[self selectedYear] monthAtIndex: row];
                [cell setTitle: [selectedMonth displayName]];
                [cell setLeaf: NO];
            }
            else {
                // showing search result entries
                NSArray *resultEntries = [self selectedSearchResultRoot];
                LJEntry *selectedEntry = [resultEntries objectAtIndex: row];

                NSString *subject = [selectedEntry subject];
                if(subject != nil) {
                    // remove slashes from subject
                    [cell setTitle: [NSString stringWithFormat: @"%@", [selectedEntry subject]]];
                }
                else {
                    NSString *proposedSubject = [selectedEntry content];
                    if([proposedSubject length] > 15)
                        proposedSubject = [proposedSubject substringToIndex: 15];

                    // Deslashify the subject
                    [cell setTitle: proposedSubject];
                }
                [cell setLeaf: YES];
                
                switch([selectedEntry securityMode]) {
                    case LJPrivateSecurityMode:
                        [cell setImage: [NSImage imageNamed: @"private"]];
                        break;
                    case LJFriendSecurityMode:
                    case LJGroupSecurityMode:
                        [cell setImage: [NSImage imageNamed: @"protected"]];
                        break;
                    default: // LJPublicSecurityMode
                        [cell setImage: nil];
                        break;
                }
            }
            break;

        case 2:
            // Col 2 = showing days in selected month
        { // <--- OK, severe compiler wierdness.
            XJDay *day = [[self selectedMonth] dayAtIndex: row];
            [cell setTitle: [NSString stringWithFormat: @"%d", [day dayName]]];
            [cell setLeaf: NO];
        } // <--- OK, severe compiler wierdness.
            break;

        case 3:
            // Col 3 = showing entries in selected day
        { // <--- OK, severe compiler wierdness.
            LJEntry *selectedEntry = [[self selectedDay] entryAtIndex: row];
            NSString *subject = [selectedEntry subject];
            if(subject != nil) {
                [cell setTitle: [selectedEntry subject]];
            } else {
                NSString *proposedSubject = [selectedEntry content];
                if([proposedSubject length] > 15)
                    proposedSubject = [proposedSubject substringToIndex: 15];
                
                [cell setTitle: proposedSubject];
            }

            switch([selectedEntry securityMode]) {
                case LJPrivateSecurityMode:
                    [cell setImage: [NSImage imageNamed: @"private"]];
                    break;
                case LJFriendSecurityMode:
                case LJGroupSecurityMode:
                    [cell setImage: [NSImage imageNamed: @"protected"]];
                    break;
                default: // LJPublicSecurityMode
                    [cell setImage: nil];
                    break;
            }
            
            [cell setLeaf: YES];
        }
            break;
    }

    NSURL *url = [self urlForBrowserSelection];
    if(url)
        [self setStatus: [url absoluteString]];
}

- (IBAction)browserChanged:(id)sender
{
    NSString *html, *fullHTML;
    LJEntry *selectedEntry;

    // There is a small chance (at least, in Cocoa's mind) we fall through the
    // if tree below, and so selectedEntry should be nil'd to avoid using
    // uninitialized memory. --sparks
    selectedEntry = nil;

    // Check if the first column selection is a search result.  If it is,
    // show the search cancel button and put the search string in the field

    int selectionType = [self browserSelectionType];
    
	if(selectionType == XJHistoryEmptySelection) 
		return;
	
    if(selectionType == XJHistorySearchGroupSelected) {
        [searchField setStringValue: [self selectedSearchString]];
        [searchField showCancelButton: YES];
    }
    else {
        [searchField setStringValue: @""];
        [searchField showCancelButton: NO];
    }

    if(selectionType == XJHistoryMonthSelected ||
       selectionType == XJHistoryDaySelected ||
       selectionType == XJHistoryYearSelected ||
       selectionType == XJHistorySearchGroupSelected)
    {
        //[text setString: @""];
        [[webView mainFrame] loadHTMLString: @"" baseURL: nil];
        [self setStatus: @""];
        return;
    }
        
    
    if(selectionType == XJHistoryEntrySelected)
        selectedEntry = [self selectedEntry];
    else if(selectionType == XJHistorySearchResultSelected)
        selectedEntry = [self selectedSearchResult];

	if(selectedEntry != nil) {
		html = [selectedEntry content];
		html = [html translateLJUser];
		html = [html translateLJComm];
		html = [html translateLJCutOpenTagWithText];
		html = [html translateBasicLJCutOpenTag];
		html = [html translateLJCutCloseTag];
		html = [html translateLJPoll];
		
		NSString *username = [[[XJAccountManager defaultManager] defaultAccount] username];
		html = [html translateLJPhonePostWithItemURL: [[selectedEntry readCommentsHttpURL] absoluteString] userName: username];
		
		if(![selectedEntry optionPreformatted])
			html = [html translateNewLines];
		
		fullHTML = [[selectedEntry metadataHTML] stringByAppendingString: html];
		
		fullHTML = [NSString stringWithFormat: @"<html><head><style type=\"text/css\">.xjljcut { background-color: #CCFFFF; padding-top: 5px; padding-bottom: 5px }</style></head><body>%@</body</html>", fullHTML];
		
		[[webView mainFrame] loadHTMLString: fullHTML baseURL: nil];
		
		[self setStatus: [[self urlForBrowserSelection] absoluteString]];
	}
}

- (IBAction)openSelectionInBrowser:(id)sender
{
    NSURL *urlToOpen = [self urlForBrowserSelection];
    NSURL *webKitURL = [[[[webView mainFrame] dataSource] request] URL];
    if(!webKitURL)
        webKitURL = [[[[webView mainFrame] provisionalDataSource] request] URL];
             
    NSString *wkurl = [webKitURL absoluteString];
    NSString *browserURL = [urlToOpen absoluteString];

    if([wkurl isEqualToString: browserURL] || [wkurl isEqualToString:@"about:blank"]) {
        if(urlToOpen)
            [[NSWorkspace sharedWorkspace] openURL: urlToOpen];
    }else {
        [[NSWorkspace sharedWorkspace] openURL: webKitURL];
    }
}

- (IBAction)editSelectionInBrowser:(id)sender
{
    NSURL *urlToOpen;
    NSArray *selectedArray = [[browser path] componentsSeparatedByString: [browser pathSeparator]];    
    LJEntry *selectedEntry;
    NSString *urlFormatString = @"http://www.livejournal.com/editjournal_do.bml?journal=%@&itemid=%d";

    int mo = [XJMonth numberForMonth: [selectedArray objectAtIndex: 2]];
    int selectedRow = [browser selectedRowInColumn: [browser lastVisibleColumn]];
    XJDay *day = [cal day: [[selectedArray objectAtIndex: 3] intValue]
                ofMonth: mo
                 inYear: [[selectedArray objectAtIndex: 1] intValue]];

    // Shouldn't happen since the button is only enabled if this is true
    NSAssert([selectedArray count] == 5, @"An entry must be selected in the browser");

    selectedEntry = [day entryAtIndex: selectedRow];

    urlToOpen = [NSURL URLWithString: [NSString stringWithFormat: urlFormatString, [[[XJAccountManager defaultManager] defaultAccount] username], [(LJEntryRoot *)selectedEntry webItemID]]];
    [[NSWorkspace sharedWorkspace] openURL: urlToOpen];
}

- (void)newEntryPosted: (NSNotification *)note
{
    LJEntry *entry = (LJEntry *)[note object];
    
    if([[[entry journal] name] isEqualToString: [[[[XJAccountManager defaultManager] defaultAccount] defaultJournal] name]]) {
        XJDay *today = [cal dayForCalendarDate: [[entry date] dateWithCalendarFormat: nil timeZone: nil]];
        [today addPostedEntry: [note object]];
        [browser reloadColumn: [browser lastVisibleColumn]];
    }
}

- (void)setStatus: (NSString *)status
{
    [urlField setStringValue: status];
}

- (BOOL)validateToolbarItem:(id)item
{
    // Open should *always* be selected, unless a search result is selected
    // Edit and Delete should only be selected if an entry is selected
    //  i.e. selectedArray = 5 || (selectedArray == 2 & searchIsSelected)

    if([[item itemIdentifier] isEqualToString: kHistoryDownloadItemIdentifier] ||
       [[item itemIdentifier] isEqualToString: kHistoryRefreshItemIdentifier])
        return YES;

    int selectionType = [self browserSelectionType];
    switch(selectionType) {
        case XJHistorySearchResultSelected: // Delete, Open and Edit should be selected
        case XJHistoryEntrySelected:
            return YES;    
        case XJHistoryDaySelected:
        case XJHistoryMonthSelected:
        case XJHistoryYearSelected:
            return [[item itemIdentifier] isEqualToString: kHistoryOpenItemIdentifier];
        case XJHistoryEmptySelection:
        case XJHistorySearchGroupSelected:
            return NO;
        default: return NO;
    }
}

- (void)beginHistoryDownload: (id)sender
{
    if([NetworkConfig destinationIsReachable:@"www.livejournal.com"]) {
        int calTotal = [cal totalEntriesInCalendar];
        [downloadTitle setStringValue: NSLocalizedString(@"Downloading History", @"")];
        
        [NSApp beginSheet: progressSheet modalForWindow: [self window] modalDelegate: nil didEndSelector: nil contextInfo: nil];
        
        [downloadBar setMaxValue: calTotal];
        [downloadBar setMinValue: 0.0];
        [downloadBar setDoubleValue: 0.0];
        [downloadBar setIndeterminate: NO];
        [downloadStatus setStringValue: [NSString stringWithFormat: @"0 of %d", calTotal]];
        
        [NSThread detachNewThreadSelector: @selector(downloadEntireHistory) toTarget: self withObject: nil];
    } else {
        NSBeginCriticalAlertSheet(NSLocalizedString(@"Network Error", @""),
                                  NSLocalizedString(@"OK", @""),nil,nil,
                                  [self window],nil,nil,nil,nil,
                                  NSLocalizedString(@"Could not contact the server to update your history.  Please try again later.", @""));
    }
}

- (IBAction)cancelHistoryDownload: (id)sender
{
	
    userHasDeclinedDownload = YES;
    terminateDownloadThread = YES;
    downloadInProgress = NO;

    userHasDeclinedUpdate = YES;
    terminateUpdateThread = YES;
    updateInProgress = NO;
    
    [NSApp endSheet: progressSheet];
    [progressSheet orderOut: nil];   
}

- (void)downloadFinished: (NSNotification *)note
{
    if([[note object] isEqualToString: @"downloadCompleted"]) {
        historyIsComplete = YES;
        [cal writeToFile: CACHED_HISTORY_PATH atomically: YES];
        [self cancelHistoryDownload: self];
        downloadInProgress = NO;
    }
    else {
        updateIsComplete = YES;
        updateInProgress = NO;
        [NSApp endSheet: progressSheet];
        [progressSheet orderOut: nil];   
	}
	
	// Here, note the selected rows in each column and select them again
	int zero = [browser selectedRowInColumn: 0];
	int one  = [browser selectedRowInColumn: 1];
	int two  = [browser selectedRowInColumn: 2];
	int three = [browser selectedRowInColumn: 3];
	
	[browser selectRow: zero inColumn: 0];
	[browser selectRow: one inColumn: 1];
	[browser selectRow: two inColumn: 2];
	[browser selectRow: three inColumn: 3];
}

- (void)downloadEntireHistory
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    int calTotal = [cal totalEntriesInCalendar];
    int numberDownloaded = 0;

    BOOL downloadFailed = NO;
    NSException *exc = nil;
    
    NSEnumerator *years = [cal yearEnumerator];
    XJYear *currentYear;
    while(!terminateDownloadThread && (currentYear = [years nextObject])) {
        NSEnumerator *monthsInYear = [currentYear monthEnumerator];
        XJMonth *currentMonth;
        while(!terminateDownloadThread && (currentMonth = [monthsInYear nextObject])) {
            NSEnumerator *daysInMonth = [currentMonth dayEnumerator];
            XJDay *currentDay;
            while(!terminateDownloadThread && (currentDay = [daysInMonth nextObject])) {
                int postsInDay = [currentDay postCount];
                NS_DURING
                    // This can vomit if the network goes away
                    [currentDay downloadEntries];
                NS_HANDLER
                    terminateDownloadThread = YES;
                    NSLog(@"%@ - %@", [localException name], [localException reason]);

                    // Network has failed, so bail
                    downloadFailed = YES;
                    exc = [localException retain];
                NS_ENDHANDLER
                
                if(downloadFailed) {
                    terminateDownloadThread = NO;
                    NSNotification *notice = [NSNotification notificationWithName:XJHistoryDownloadFailedNotification
                                                                           object: [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: exc, currentDay, nil]
																											   forKeys: [NSArray arrayWithObjects: @"exception", @"day", nil]]
                                                                         userInfo: nil];
                    
                    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                                           withObject:notice
                                                                        waitUntilDone:YES];
                    [exc release];
                    
                    return;
                }
                
                numberDownloaded += postsInDay;

                NSNotification *notice = [NSNotification notificationWithName:XJHistoryDownloadMadeProgressNotification
                                                                       object:[NSArray arrayWithObjects:
                                                                           [NSNumber numberWithInt: numberDownloaded],
                                                                           [NSNumber numberWithInt: calTotal],
                                                                           nil]
                                                                     userInfo:nil];
                
                [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                                       withObject:notice
                                                                    waitUntilDone:NO];
                
            }
        }

    }

    if(!terminateDownloadThread) { // don't fire this unless we completed the download
        NSNotification *notice = [NSNotification notificationWithName:XJHistoryDownloadCompletedNotification
                                                               object: @"downloadCompleted"
                                                             userInfo:nil];

        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                               withObject:notice
                                                            waitUntilDone:NO];
    }
    
    terminateDownloadThread = NO;
    [pool release];
}

- (void)updateHistoryDownloadProgress: (NSNotification *)note
{
    NSArray *info = [note object];
    int progressMax = [[info objectAtIndex: 1] intValue];
    if(![downloadBar isIndeterminate] && [downloadBar maxValue] != progressMax)
        [downloadBar setMaxValue: progressMax];
    
    [downloadStatus setStringValue: [NSString stringWithFormat: @"%d of %d", [[info objectAtIndex: 0] intValue], [[info objectAtIndex: 1] intValue]]];
    [downloadBar setDoubleValue: [[info objectAtIndex: 0] intValue]];
}

- (void)historyDownloadFailed: (NSNotification *)note
{
    id exception = [[note object] objectForKey: @"exception"];
	XJDay *day = [[note object] objectForKey: @"day"];
    
    userHasDeclinedDownload = YES;
    downloadInProgress = NO;
    historyIsComplete = NO;

    updateInProgress = NO;
    userHasDeclinedUpdate = YES;
    
    [NSApp endSheet: progressSheet];
    [progressSheet orderOut: nil];
    NSLog(@"historyDownloadFailed: %@", [exception name]);
    
    if([[exception name] isEqualToString: @"LJServerError"])
        [self showEncodingErrorSheetForDate: [day calendarDate]];
    else
        [self showGenericErrorSheet: [exception reason]];
}

- (void)beginHistoryUpdate: (id)sender
{
    if([NetworkConfig destinationIsReachable:@"www.livejournal.com"]) {
        [downloadTitle setStringValue: NSLocalizedString(@"Updating History", @"")];
        [NSApp beginSheet: progressSheet modalForWindow: [self window] modalDelegate: nil didEndSelector: nil contextInfo: nil];
        [downloadBar setIndeterminate: NO];
        [downloadStatus setStringValue: @""];
        
        [NSThread detachNewThreadSelector: @selector(updateAgainstDayCounts) toTarget: self withObject: nil];
    } else {
        NSBeginCriticalAlertSheet(NSLocalizedString(@"Network Error", @""),
                                  NSLocalizedString(@"OK", @""),nil,nil,
                                  [self window],nil,nil,nil,nil,
                                  NSLocalizedString(@"Could not contact the server to update your history.  Please try again later.", @""));
    }
}

- (void)updateAgainstDayCounts
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSArray *dates;

    NSDictionary *currentDayCounts = [[[[XJAccountManager defaultManager] defaultAccount] defaultJournal] getDayCounts];
    dates = [currentDayCounts allKeys];
    int i;
    
    NSMutableArray *daysToUpdate = [[NSMutableArray array] retain];
    
    for(i=0; !terminateUpdateThread && i < [dates count]; i++) {
        id date = [dates objectAtIndex: i];
        XJDay *day = [cal dayForCalendarDate: date];
        NSNumber *countForDay = [currentDayCounts objectForKey: date];
        if([day postCount] != [countForDay intValue])
        	[daysToUpdate addObject: day];
    }
    
    
	NSEnumerator *enumerator = [daysToUpdate objectEnumerator];
	XJDay *dayToUpdate;
	i=0;
	while(dayToUpdate = [enumerator nextObject]) {
		NSNotification *notice = [NSNotification notificationWithName:XJHistoryDownloadMadeProgressNotification
                                                               object:[NSArray arrayWithObjects:
                                                                   [NSNumber numberWithInt: i],
                                                                   [NSNumber numberWithInt: [daysToUpdate count]],
                                                                   nil]
                                                             userInfo:nil];

        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                               withObject:notice
                                                            waitUntilDone:NO];
        NS_DURING
            //[dayToUpdate validatePostCountAndUpdate: [[daysToUpdate objectForKey: dayToUpdate] intValue]];
            [dayToUpdate downloadEntries];
        NS_HANDLER
            NSLog(@"Exception in -[XJHistoryWindowController updateAgainstDayCounts]: %@", [localException name]);
            terminateUpdateThread = YES;
        NS_ENDHANDLER
        i++;
	}

    if(!terminateUpdateThread) { // don't fire this unless we completed the update
        NSNotification *notice = [NSNotification notificationWithName:XJHistoryDownloadCompletedNotification
                                                               object: @"updateCompleted"
                                                             userInfo:nil];

        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                               withObject:notice
                                                            waitUntilDone:NO];
    } 
    terminateUpdateThread = NO;
    
    [pool release];
}

// Gets fired when HTML preview finishes loading the images
- (void)gotNotification: (NSNotification *)notification
{
    if ([[notification name] hasPrefix:@"HTML"]) {
        [self browserChanged: self];
    }
}

// Gets fired when an entry that was downlaoded got edited
- (void)entryEdited: (NSNotification *)note
{
    [self browserChanged: self];

    // Also, here, reload the column where the entry is selected
    if([self browserSelectionType] == XJHistorySearchResultSelected) {
        [browser reloadColumn: 1];
    }
    else {
        [browser reloadColumn: 3];
    }
}

// ----------------------------------------------------------------------------------------
//WebKit notification
// ----------------------------------------------------------------------------------------
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]){
        if(![sender canGoBack]) {
            [backButton setEnabled: NO];
        }
        else {
            [backButton setEnabled: YES];
        }

        if(![sender canGoForward]) {
            [forwardButton setEnabled: NO];
        }
        else {
            [forwardButton setEnabled: YES];
        }
    }

    // In case the frame got redirected, update the URL bar
    NSString *currentFrameURL = [[[[[webView mainFrame] dataSource] request] URL] absoluteString];
    if(![currentFrameURL isEqualToString: @"about:blank"])
        [urlField setStringValue: currentFrameURL];
    
    [wvSpinner stopAnimation: self];
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    [wvSpinner startAnimation: self];

    if (frame == [sender mainFrame]){
        NSString *url = [[[[frame provisionalDataSource] request] URL] absoluteString];
        [self setStatus:url];
    }    
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if (frame == [sender mainFrame]){
        [wvSpinner stopAnimation: self];
    }
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if (frame == [sender mainFrame]){
        [wvSpinner stopAnimation: self];
    }    
}
// ----------------------------------------------------------------------------------------
// Web View delegates
// ----------------------------------------------------------------------------------------
- (void) webView: (WebView *) sender  decidePolicyForNavigationAction: (NSDictionary *) actionInformation request: (NSURLRequest *) request frame: (WebFrame *) frame decisionListener: (id<WebPolicyDecisionListener>) listener
{
    NSString *targetURL = [[actionInformation objectForKey: WebActionOriginalURLKey] absoluteString];
    if([targetURL isEqualToString: @"about:blank"]) {
        [listener use]; // Generated HTML
    }
    else {
        if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJHistoryOpenLinksInApp"] boolValue])
            [listener use];
        else {
            [listener ignore];
            // Instead of opening it in the WebView, we want to open
            // the URL in the user's default browser
            [[NSWorkspace sharedWorkspace] openURL: [actionInformation objectForKey:WebActionOriginalURLKey]];
        }
    }
}
@end

@implementation XJHistoryWindowController (PrivateAPI)

// Information sheet
- (void)showEncodingErrorSheetForDate: (NSCalendarDate *)date
{
    NSBeginCriticalAlertSheet(@"Text Encoding Error",
                              @"OK",
                              @"Open Info Page",
                              nil,
                              [self window],
                              self,
                              @selector(sheetDidEnd:returnCode:contextInfo:),
                              @selector(sheetDidDismiss:returnCode:contextInfo:),
                              @"textEncoding",
                              [NSString stringWithFormat: @"There is a problem with your text encoding in an entry on %@.  Please visit your LiveJournal information page and set the \"Auto Convert Older Entries From\" setting appropriately.", [date descriptionWithLocale: nil]]);
}

- (void)showGenericErrorSheet: (NSString *)message
{
    NSBeginCriticalAlertSheet(@"Error",
                              @"OK",
                              nil,
                              nil,
                              [self window],
                              self,
                              @selector(sheetDidEnd:returnCode:contextInfo:),
                              @selector(sheetDidDismiss:returnCode:contextInfo:),
                              @"textEncoding",
                              message);
}

- (BOOL)columnZeroSelectionIsYear
{
    /* Note that calling this when there is *no* first column selection 
     will return NO
    */
    int firstColumnSelection = [browser selectedRowInColumn: 0];
    return firstColumnSelection < [cal numberOfYears];
}

- (int)browserSelectionType
{
    if([browser selectedRowInColumn: 3] != -1)
        return XJHistoryEntrySelected;

    if([browser selectedRowInColumn: 2] != -1)
        return XJHistoryDaySelected;

    if([browser selectedRowInColumn: 1] != -1) {
        int firstColumnSelection = [browser selectedRowInColumn: 0];
            if(firstColumnSelection < [cal numberOfYears])
                return XJHistoryMonthSelected;
            else
                return XJHistorySearchResultSelected;
    }

    int firstColumnSelection = [browser selectedRowInColumn: 0];
    if(firstColumnSelection != -1) {
        if(firstColumnSelection < [cal numberOfYears])
            return XJHistoryYearSelected;
        else
            return XJHistorySearchGroupSelected;
    }

    return XJHistoryEmptySelection;    
}

- (NSString *)selectedSearchString
{
    int base = [browser selectedRowInColumn: 0] - [cal numberOfYears];
    NSAssert(base >= 0, @"Error in selectedSearchString - base < 0");
    return [[searchCache allKeys] objectAtIndex: base];
}

- (NSArray *)selectedSearchResultRoot
{
    return [searchCache objectForKey: [self selectedSearchString]];
}

- (LJEntry *)selectedSearchResult
{
    return [[self selectedSearchResultRoot] objectAtIndex: [browser selectedRowInColumn: 1]];
}

- (void)editEntry: (LJEntry *)entryToEdit
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    id doc = [docController openUntitledDocumentOfType: @"Xjournal Entry" display: NO];
    [doc setEntry: entryToEdit];
    [doc showWindows];
}

/*
 Note that calling this method when a search result is selected will cause an exception.
 Best to check first, eh?
*/
- (LJEntry *)selectedEntry
{
    XJDay *day = [self selectedDay];
    return [day entryAtIndex: [browser selectedRowInColumn: 3]];
}

- (XJDay *)selectedDay
{
    XJMonth *month = [self selectedMonth];
    return [month dayAtIndex: [browser selectedRowInColumn: 2]];
}

- (XJMonth *)selectedMonth
{
    XJYear *year = [self selectedYear];
    return [year monthAtIndex: [browser selectedRowInColumn: 1]];
}

- (XJYear *)selectedYear
{
    int firstColumnSelection = [browser selectedRowInColumn: 0];
    XJYear *year = [cal yearAtIndex: firstColumnSelection];
    return year;
}

- (NSURL *)urlForBrowserSelection
{
    NSURL *urlToOpen = nil;
    int selectionType = [self browserSelectionType];

    switch(selectionType) {
        case XJHistoryYearSelected:
        {
            XJYear *selectedYear = [self selectedYear];
            NSString *URLFormat = @"http://www.livejournal.com/users/%@/%d";
            urlToOpen = [NSURL URLWithString: [NSString stringWithFormat: URLFormat, [[[XJAccountManager defaultManager] defaultAccount] username], [selectedYear yearName]]];
        }
            break;

        case XJHistoryMonthSelected:
        {
            XJMonth *selectedMonth = [self selectedMonth];
            XJYear *selectedYear = [self selectedYear];
            NSString *URLFormat = @"http://www.livejournal.com/users/%@/%d/%@";
            urlToOpen = [NSURL URLWithString: [NSString stringWithFormat: URLFormat, [[[XJAccountManager defaultManager] defaultAccount] username], [selectedYear yearName], [self zeroizedString: [selectedMonth monthName]]]];
        }
            break;

        case XJHistoryDaySelected:
        {
            XJDay *selectedDay = [self selectedDay];
            XJMonth *selectedMonth = [self selectedMonth];
            XJYear *selectedYear = [self selectedYear];
            NSString *URLFormat = @"http://www.livejournal.com/users/%@/%d/%@/%@";
            urlToOpen = [NSURL URLWithString: [NSString stringWithFormat: URLFormat, [[[XJAccountManager defaultManager] defaultAccount] username], [selectedYear yearName],
                [self zeroizedString: [selectedMonth monthName]],
                [self zeroizedString: [selectedDay dayName]]]];
        }
            break;

        case XJHistoryEntrySelected:
            urlToOpen = [[self selectedEntry] readCommentsHttpURL];
            break;

        case XJHistorySearchResultSelected:
            urlToOpen = [[self selectedSearchResult] readCommentsHttpURL];
            break;
    }

    return urlToOpen;
}

- (NSString *)zeroizedString:(int)number
{
    if(number < 10)
        return [NSString stringWithFormat: @"0%d", number];
    else
        return [NSString stringWithFormat: @"%d", number];
}
// ----------------------------------------------------------------------------------------
// Toolbar delegate
// ----------------------------------------------------------------------------------------
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item;

    if(!toolbarItemCache) {
        toolbarItemCache = [[NSMutableDictionary dictionaryWithCapacity: 5] retain];
    }

    item = [toolbarItemCache objectForKey: itemIdentifier];
    if(!item) {
        item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];

        if([itemIdentifier isEqualToString: kHistoryOpenItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Open in Browser", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Open in Browser", @"")];
            [item setTarget: self];
            [item setAction: @selector(openSelectionInBrowser:)];
            [item setToolTip: NSLocalizedString(@"Open Selected Item in Browser", @"")];
            [item setImage: [NSImage imageNamed: @"Internet"]];
        }
        else if([itemIdentifier isEqualToString: kHistoryDeleteItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Delete", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Delete from Journal", @"")];
            [item setTarget: self];
            [item setAction: @selector(deleteSelectedEntry:)];
            [item setToolTip: NSLocalizedString(@"Delete Selected Item from Journal", @"")];
            [item setImage: [NSImage imageNamed: @"delete"]];
        }
        else if([itemIdentifier isEqualToString: kHistoryDownloadItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Download", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Download History", @"")];
            [item setTarget: self];
            [item setAction: @selector(beginHistoryDownload:)];
            [item setToolTip: NSLocalizedString(@"Download your entire LiveJournal History", @"")];
            [item setImage: [NSImage imageNamed: @"HistoryDownload"]];
        }
        else if([itemIdentifier isEqualToString: kHistoryRefreshItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Refresh", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Refresh History", @"")];
            [item setTarget: self];
            [item setAction: @selector(beginHistoryUpdate:)];
            [item setToolTip: NSLocalizedString(@"Refresh your LiveJournal History cache", @"")];
            [item setImage: [NSImage imageNamed: @"Refresh"]];
        }
        else if([itemIdentifier isEqualToString: kHistorySearchItemIdentifier]) {
            [item setView: searchView];
            [item setLabel: NSLocalizedString(@"Search", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Search", @"")];
            [item setToolTip: NSLocalizedString(@"Search History", @"")];
            [item setMinSize: NSMakeSize(130, 26)];
            [item setMaxSize: NSMakeSize(200, 26)];
            [item setTarget: self];
            [item setAction: @selector(runSearchSheet:)];
        }
        else if([itemIdentifier isEqualToString: kHistoryEditItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Edit", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Edit", @"")];
            [item setToolTip: NSLocalizedString(@"Edit Post", @"")];
            [item setTarget: self];
            [item setAction: @selector(editSelectedEntry:)];
            [item setImage: [NSImage imageNamed: @"compose"]];
        }
        
        [toolbarItemCache setObject: item forKey:itemIdentifier];
        [item release];
    }
    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: kHistoryOpenItemIdentifier,
        kHistoryEditItemIdentifier,
        kHistoryDeleteItemIdentifier,
        kHistoryRefreshItemIdentifier,
        kHistoryDownloadItemIdentifier,
        kHistorySearchItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        kHistoryOpenItemIdentifier,
        kHistoryEditItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        kHistoryDeleteItemIdentifier,
        kHistoryRefreshItemIdentifier,
        kHistoryDownloadItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kHistorySearchItemIdentifier, nil];
}
@end