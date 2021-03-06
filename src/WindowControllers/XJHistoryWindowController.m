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
//#import "NSDocumentController-CustomDocs.h"

#import "Xjournal-Swift.h"

#define kHistoryWindowToolbarIdentifier @"history.toolbar" 
#define kHistoryOpenItemIdentifier @"history.open.item"
#define kHistoryEditItemIdentifier @"history.edit.item"
#define kHistoryDeleteItemIdentifier @"history.delete.item"
#define kHistorySearchItemIdentifier @"kHistorySearchItemIdentifier"
#define kHistoryDownloadItemIdentifier @"kHistoryDownloadItemIdentifier"
#define kHistoryRefreshItemIdentifier @"kHistoryRefreshItemIdentifier"

#define kHistoryAutosaveName @"kHistoryAutosaveName"

#define CACHED_HISTORY_PATH [XJGetLocalAppSupportDir() stringByAppendingPathComponent: @"History.plist"]

#define XJHistoryDownloadMadeProgressNotification @"XJHistoryDownloadMadeProgressNotification"
#define XJHistoryDownloadCompletedNotification @"XJHistoryDownloadCompletedNotification"
#define XJHistoryDownloadFailedNotification @"XJHistoryDownloadFailedNotification"

#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (254.0 / 255.0)

@protocol SearchSheetRunner <NSObject>
- (IBAction)runSearchSheet:(id)sender;
@end

typedef NS_ENUM(int, XJHistorySelection) {
    XJHistorySearchResultSelected = 0,
    XJHistoryEntrySelected,
    XJHistoryDaySelected,
    XJHistoryMonthSelected,
    XJHistoryYearSelected,
    XJHistoryEmptySelection,
    XJHistorySearchGroupSelected
};

@interface XJHistoryWindowController ()
- (void)showEncodingErrorSheetForDate: (NSDate *)date;
- (void)showGenericErrorSheet: (NSString *)message;

 @property (readonly) int browserSelectionType;
@property (readonly) BOOL columnZeroSelectionIsYear;
@property (readonly, strong) LJEntry *selectedEntry;
@property (readonly, strong) XJDay *selectedDay;
@property (readonly, strong) XJMonth *selectedMonth;
@property (readonly, strong) XJYear *selectedYear;

@property (readonly, copy) NSString *selectedSearchString;
@property (readonly, copy) NSArray *selectedSearchResultRoot;
@property (readonly, strong) LJEntry *selectedSearchResult;

@property (readonly, copy) NSURL *urlForBrowserSelection;

- (void)editEntry: (LJEntry *)entryToEdit;
@end

@implementation XJHistoryWindowController 
@synthesize account;

- (instancetype)init
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
        
        searchCache = [[NSMutableDictionary alloc] initWithCapacity: 10];
        
        cal = [[XJCalendar alloc] init];
        
        if(![self loadCachedHistory]) {
            userHasDeclinedDownload = ![self analyzeDayCounts];
            if(userHasDeclinedDownload) {
                userHasDeclinedUpdate = YES;
                NSAlert *alert = [NSAlert new];
                alert.messageText = NSLocalizedString(@"Network Error", @"");
                alert.informativeText = NSLocalizedString(@"Could not contact the server to get your post counts.  Please try again later.", @"");
                [alert runModal];
            }
        }

        selectedSearchType = XJSearchEntirePost;
        
        [browser loadColumnZero];
    }
    return self;
}

- (void)applicationWillTerminate: (NSNotification *)note
{
    if (historyIsComplete) {
        [cal writeToFile: [self historyArchivePath] atomically: YES];
	}
}

- (BOOL)loadCachedHistory
{
    NSFileManager *man = [NSFileManager defaultManager];
    BOOL isDir;
    if([man fileExistsAtPath: [self historyArchivePath] isDirectory: &isDir] && !isDir) {
        [cal configureWithContentsOfFile: [self historyArchivePath]];
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

    [browser setTarget: self];
    [browser setDoubleAction: @selector(editSelectedEntry:)];

    [webView setFrameLoadDelegate: self];
    [webView setPolicyDelegate: self];
    [webView setPreferencesIdentifier: XJ_HISTORY_PREF_IDENT];
    [[webView preferences] setAutosaves: YES];
}

- (NSString *)historyArchivePath
{
    return [XJGetLocalAppSupportDir() stringByAppendingPathComponent:[[[[XJAccountManager defaultManager] defaultAccount] defaultJournal] name]];
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
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Delete Journal Entry";
    alert.informativeText = NSLocalizedString(@"Are you sure you want to delete the selected entry from your journal?  This cannot be undone.", @"");
    [alert addButtonWithTitle: @"Cancel"];
    [alert addButtonWithTitle: @"Delete"];
    [alert beginSheetModalForWindow: self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertSecondButtonReturn) {
            XJHistorySelection selectionType = [self browserSelectionType];
            if (selectionType == XJHistorySearchResultSelected) {
                LJEntry *entryToDelete = [self selectedSearchResult];
                XJDay *day = [cal dayForDate: [entryToDelete date]];
                @try {
                    [day deleteEntry: entryToDelete];
                } @catch (NSException *localException) {
                    NSLog(@"Connection Reset During Delete");
                }
                [self executeSearchForString: [self selectedSearchString]];
            } else {
                XJDay *day = [self selectedDay];
                @try {
                    [day deleteEntryAtIndex: [browser selectedRowInColumn:3]];
                } @catch (NSException *localException) {
                    NSLog(@"Connection Reset During Delete");
                }
                NSInteger row = [browser selectedRowInColumn: 2];
                [browser selectRow: row inColumn: 2];
                //[browser reloadColumn: [browser lastVisibleColumn]];
                [self setStatus: @""];
            }
        }
    }];
}

#if 0
// DidEndHandler for the delete confirmation sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSString *cmd = (__bridge NSString *)contextInfo;

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
				XJDay *day = [cal dayForDate: [entryToDelete date]];
				@try {
					[day deleteEntry: entryToDelete];
				} @catch (NSException *localException) {
					NSLog(@"Connection Reset During Delete");
				}
				[self executeSearchForString: [self selectedSearchString]];
			}
			else {
				XJDay *day = [self selectedDay];
				@try {
					[day deleteEntryAtIndex: [browser selectedRowInColumn:3]];
				} @catch (NSException *localException) {
					NSLog(@"Connection Reset During Delete");
				}
				NSInteger row = [browser selectedRowInColumn: 2];
				[browser selectRow: row inColumn: 2];
				//[browser reloadColumn: [browser lastVisibleColumn]];
				[self setStatus: @""];
			}
        }
    }
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSString *cmd = (__bridge NSString *)contextInfo;
    if([cmd isEqualToString: @"downloadHistory"]) {
        userHasDeclinedDownload = YES;
    }
    else if([cmd isEqualToString: @"updateHistory"]){
        userHasDeclinedUpdate = YES;
    }
    else { // Text encoding sheet
        
    }
}
#endif

- (BOOL)analyzeDayCounts
{
    if([NetworkConfig destinationIsReachable: @"www.livejournal.com"]) {
        NSDictionary *tempDayCounts;
        
        // Cocoa (erroneously) believes we might fall through the NS_DURING loop,
        // and wants this variable 'nil'd so as to ensure it's not uninitialized memory.
        //      --sparks
        tempDayCounts = nil;
        
        @try {
            tempDayCounts = [[[[XJAccountManager defaultManager] defaultAccount] defaultJournal] getDayCounts];
            dayCounts = nil;
            dayCounts = tempDayCounts;
            
            for (NSDate *date in dayCounts) {
                XJDay *day = [cal dayForDate: date];
                [day setPostCount: [dayCounts[date] integerValue]];
            }
        } @catch (NSException *localException) {
            NSLog(@"getDayCounts failed");
        }
        return tempDayCounts != nil;
    }
    return NO;
}

// Search
- (IBAction)executeSearch:(id)sender {
	[self executeSearchForString: [sender stringValue]];
}

- (void)executeSearchForString: (NSString *)target
{
    NSArray *results = [cal entriesContainingString: target searchType: selectedSearchType];
    searchCache[target] = results;

    // Get the index of the search
    NSInteger rowToSelect = [[searchCache allKeys] indexOfObject: target] + [cal numberOfYears];
    [browser loadColumnZero];
    [browser selectRow: rowToSelect inColumn: 0];
    //[browser becomeFirstResponder];
}

- (IBAction)clearSearch:(id)sender
{
    NSInteger base = [browser selectedRowInColumn: 0] - [cal numberOfYears];
    NSString *searchKey = [searchCache allKeys][base];

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
- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column
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

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column
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
                NSInteger base = row - [cal numberOfYears];
                [cell setTitle: [searchCache allKeys][base]];
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
                LJEntry *selectedEntry = resultEntries[row];

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
                    case LJSecurityModePrivate:
                        [cell setImage: [NSImage imageNamed: @"private"]];
                        break;
                    case LJSecurityModeFriend:
                    case LJSecurityModeGroup:
                        [cell setImage: [NSImage imageNamed: @"protected"]];
                        break;
                    default: // LJSecurityModePublic
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
                case LJSecurityModePrivate:
                    [cell setImage: [NSImage imageNamed: @"private"]];
                    break;
                case LJSecurityModeFriend:
                case LJSecurityModeGroup:
                    [cell setImage: [NSImage imageNamed: @"protected"]];
                    break;
                default: // LJSecurityModePublic
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
    }
    else {
        [searchField setStringValue: @""];
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
			html = [html translateNewLinesOutsideTables];
		
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

    int mo = [XJMonth numberForMonth: selectedArray[2]];
    NSInteger selectedRow = [browser selectedRowInColumn: [browser lastVisibleColumn]];
    XJDay *day = [cal day: [selectedArray[3] intValue]
                ofMonth: mo
                 inYear: [selectedArray[1] intValue]];

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
        XJDay *today = [cal dayForDate: [entry date]];
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
        NSInteger calTotal = [cal totalEntriesInCalendar];
        [downloadTitle setStringValue: NSLocalizedString(@"Downloading History", @"")];
        
        [self.window beginSheet: progressSheet completionHandler:^(NSModalResponse returnCode) {
            
        }];
        
        [downloadBar setMaxValue: calTotal];
        [downloadBar setMinValue: 0.0];
        [downloadBar setDoubleValue: 0.0];
        [downloadBar setIndeterminate: NO];
        [downloadStatus setStringValue: [NSString stringWithFormat: @"0 of %ld", (long)calTotal]];
        
        [NSThread detachNewThreadSelector: @selector(downloadEntireHistory) toTarget: self withObject: nil];
    } else {
        NSAlert *alert = [NSAlert new];
        alert.messageText = NSLocalizedString(@"Network Error", @"");
        alert.informativeText = NSLocalizedString(@"Could not contact the server to update your history.  Please try again later.", @"");
        alert.alertStyle = NSAlertStyleCritical;
        [alert beginSheetModalForWindow: self.window completionHandler:^(NSModalResponse returnCode) {
            // Do nothing
        }];
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
    
    [self.window endSheet: progressSheet];
    [progressSheet orderOut: nil];   
}

static inline void RunOnMainThreadSync(dispatch_block_t theBlock)
{
    if ([NSThread isMainThread]) {
        theBlock();
    } else {
        dispatch_sync(dispatch_get_main_queue(), theBlock);
    }
}

- (void)downloadFinished: (NSNotification *)note
{
    if([[note object] isEqualToString: @"downloadCompleted"]) {
        historyIsComplete = YES;
        [cal writeToFile:[self historyArchivePath] atomically: YES];
        [self cancelHistoryDownload: self];
        downloadInProgress = NO;
    }
    else {
        updateIsComplete = YES;
        updateInProgress = NO;
        [self.window endSheet: progressSheet];
        [progressSheet orderOut: nil];
	}
	
	// Here, note the selected rows in each column and select them again
	NSInteger zero = [browser selectedRowInColumn: 0];
	NSInteger one  = [browser selectedRowInColumn: 1];
	NSInteger two  = [browser selectedRowInColumn: 2];
	NSInteger three = [browser selectedRowInColumn: 3];
	
	[browser selectRow: zero inColumn: 0];
	[browser selectRow: one inColumn: 1];
	[browser selectRow: two inColumn: 2];
	[browser selectRow: three inColumn: 3];
}

- (void)downloadEntireHistory
{
    @autoreleasepool {
    
        NSInteger calTotal = [cal totalEntriesInCalendar];
        NSInteger numberDownloaded = 0;

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
                    NSInteger postsInDay = [currentDay postCount];
                    @try {
                        // This can vomit if the network goes away
                        [currentDay downloadEntries];
                    } @catch (NSException *localException) {
                        terminateDownloadThread = YES;
                        NSLog(@"%@ - %@", [localException name], [localException reason]);

                        // Network has failed, so bail
                        downloadFailed = YES;
                        exc = localException;
                    }
                    
                    if(downloadFailed) {
                        terminateDownloadThread = NO;
                        NSNotification *notice = [NSNotification notificationWithName:XJHistoryDownloadFailedNotification
                                                                               object: @{@"exception": exc, @"day": currentDay}
                                                                             userInfo: nil];
                        
                        RunOnMainThreadSync(^{
                            [[NSNotificationCenter defaultCenter] postNotification:notice];
                        });
                        
                        return;
                    }
                    
                    numberDownloaded += postsInDay;

                    NSNotification *notice = [NSNotification notificationWithName:XJHistoryDownloadMadeProgressNotification
                                                                           object:@[@(numberDownloaded),
                                                                               @(calTotal)]
                                                                         userInfo:nil];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotification:notice];
                    });
                    
                }
            }

        }

        if(!terminateDownloadThread) { // don't fire this unless we completed the download
            NSNotification *notice = [NSNotification notificationWithName:XJHistoryDownloadCompletedNotification
                                                                   object: @"downloadCompleted"
                                                                 userInfo:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotification:notice];
            });
        }
        
        terminateDownloadThread = NO;
    }
}

- (void)updateHistoryDownloadProgress: (NSNotification *)note
{
    NSArray *info = [note object];
    NSInteger progressMax = [info[1] integerValue];
    if(![downloadBar isIndeterminate] && [downloadBar maxValue] != progressMax)
        [downloadBar setMaxValue: progressMax];
    
    [downloadStatus setStringValue: [NSString stringWithFormat: @"%d of %d", [info[0] intValue], [info[1] intValue]]];
    [downloadBar setDoubleValue: [info[0] integerValue]];
}

- (void)historyDownloadFailed: (NSNotification *)note
{
    id exception = [note object][@"exception"];
	XJDay *day = [note object][@"day"];
    
    userHasDeclinedDownload = YES;
    downloadInProgress = NO;
    historyIsComplete = NO;

    updateInProgress = NO;
    userHasDeclinedUpdate = YES;
    
    [self.window endSheet: progressSheet];
    [progressSheet orderOut: nil];
    NSLog(@"historyDownloadFailed: %@", [exception name]);
    
    if([[exception name] isEqualToString: @"LJServerError"])
        [self showEncodingErrorSheetForDate: day.date];
    else
        [self showGenericErrorSheet: [exception reason]];
}

- (void)beginHistoryUpdate: (id)sender
{
    if([NetworkConfig destinationIsReachable:@"www.livejournal.com"]) {
        [downloadTitle setStringValue: NSLocalizedString(@"Updating History", @"")];
        [self.window beginSheet: progressSheet completionHandler:^(NSModalResponse returnCode) {
            // Do nothing
        }];
        [downloadBar setIndeterminate: NO];
        [downloadStatus setStringValue: @""];
        
        [NSThread detachNewThreadSelector: @selector(updateAgainstDayCounts) toTarget: self withObject: nil];
    } else {
        NSAlert *alert = [NSAlert new];
        alert.messageText = NSLocalizedString(@"Network Error", @"");
        alert.informativeText = NSLocalizedString(@"Could not contact the server to update your history.  Please try again later.", @"");
        alert.alertStyle = NSAlertStyleCritical;
        [alert beginSheetModalForWindow: self.window completionHandler:^(NSModalResponse returnCode) {
            // Do nothing
        }];
    }
}

- (void)updateAgainstDayCounts
{
    @autoreleasepool {
        NSArray *dates;

        NSDictionary *currentDayCounts = [[[[XJAccountManager defaultManager] defaultAccount] defaultJournal] getDayCounts];
        dates = [currentDayCounts allKeys];
        NSInteger i;
        
        NSMutableArray *daysToUpdate = [NSMutableArray array];
        
        for (i=0; !terminateUpdateThread && i < [dates count]; i++) {
            id date = dates[i];
            XJDay *day = [cal dayForDate: date];
            NSNumber *countForDay = currentDayCounts[date];
            if([day postCount] != [countForDay integerValue])
            	[daysToUpdate addObject: day];
        }
        
        
	i=0;
	for (XJDay *dayToUpdate in daysToUpdate) {
		NSNotification *notice = [NSNotification notificationWithName:XJHistoryDownloadMadeProgressNotification
                                                                   object:@[@(i),
                                                                       @([daysToUpdate count])]
                                                                 userInfo:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotification:notice];
        });
            @try {
                //[dayToUpdate validatePostCountAndUpdate: [[daysToUpdate objectForKey: dayToUpdate] intValue]];
                [dayToUpdate downloadEntries];
            } @catch (NSException *localException) {
                NSLog(@"Exception in -[XJHistoryWindowController updateAgainstDayCounts]: %@", [localException name]);
                terminateUpdateThread = YES;
            }
            i++;
	}

        if(!terminateUpdateThread) { // don't fire this unless we completed the update
            NSNotification *notice = [NSNotification notificationWithName:XJHistoryDownloadCompletedNotification
                                                                   object: @"updateCompleted"
                                                                 userInfo:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotification:notice];
            });
        }
        terminateUpdateThread = NO;
    
    }
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
    NSString *targetURL = [actionInformation[WebActionOriginalURLKey] absoluteString];
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
            [[NSWorkspace sharedWorkspace] openURL: actionInformation[WebActionOriginalURLKey]];
        }
    }
}

// Information sheet
- (void)showEncodingErrorSheetForDate: (NSDate *)date
{
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Text Encoding Error";
    alert.informativeText = [NSString stringWithFormat: @"There is a problem with your text encoding in an entry on %@.  Please visit your LiveJournal information page and set the \"Auto Convert Older Entries From\" setting appropriately.", [date descriptionWithLocale: nil]];
    alert.alertStyle = NSAlertStyleCritical;
    [alert addButtonWithTitle: NSLocalizedString(@"OK", @"")];
    [alert addButtonWithTitle: NSLocalizedString(@"Open Info Page", @"")];
    [alert beginSheetModalForWindow: self.window completionHandler:^(NSModalResponse returnCode) {
        switch(returnCode) {
            case NSAlertSecondButtonReturn:
                [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.livejournal.com/editinfo.bml"]];
                break;
                // do nothing on default return
        }
    }];
}

- (void)showGenericErrorSheet: (NSString *)message
{
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Error";
    alert.informativeText = message;
    alert.alertStyle = NSAlertStyleCritical;
    [alert beginSheetModalForWindow: self.window completionHandler:^(NSModalResponse returnCode) {
        //Do nothing
    }];
}

- (BOOL)columnZeroSelectionIsYear
{
    /* Note that calling this when there is *no* first column selection 
     will return NO
    */
    NSInteger firstColumnSelection = [browser selectedRowInColumn: 0];
    return firstColumnSelection < [cal numberOfYears];
}

- (int)browserSelectionType
{
    if([browser selectedRowInColumn: 3] != -1)
        return XJHistoryEntrySelected;

    if([browser selectedRowInColumn: 2] != -1)
        return XJHistoryDaySelected;

    if([browser selectedRowInColumn: 1] != -1) {
        NSInteger firstColumnSelection = [browser selectedRowInColumn: 0];
            if(firstColumnSelection < [cal numberOfYears])
                return XJHistoryMonthSelected;
            else
                return XJHistorySearchResultSelected;
    }

    NSInteger firstColumnSelection = [browser selectedRowInColumn: 0];
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
    NSInteger base = [browser selectedRowInColumn: 0] - [cal numberOfYears];
    NSAssert(base >= 0, @"Error in selectedSearchString - base < 0");
    return [searchCache allKeys][base];
}

- (NSArray *)selectedSearchResultRoot
{
    return searchCache[[self selectedSearchString]];
}

- (LJEntry *)selectedSearchResult
{
    return [self selectedSearchResultRoot][[browser selectedRowInColumn: 1]];
}

- (void)editEntry: (LJEntry *)entryToEdit
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    XJDocument *doc = [docController openUntitledDocumentAndDisplay:NO error:NULL];
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
    NSInteger firstColumnSelection = [browser selectedRowInColumn: 0];
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
            urlToOpen = [NSURL URLWithString: [NSString stringWithFormat: @"http://www.livejournal.com/users/%@/%d/%02d", [[[XJAccountManager defaultManager] defaultAccount] username], [selectedYear yearName], selectedMonth.monthName]];
        }
            break;

        case XJHistoryDaySelected:
        {
            XJDay *selectedDay = [self selectedDay];
            XJMonth *selectedMonth = [self selectedMonth];
            XJYear *selectedYear = [self selectedYear];
            urlToOpen = [NSURL URLWithString: [NSString stringWithFormat: @"http://www.livejournal.com/users/%@/%d/%02d/%02d", [[[XJAccountManager defaultManager] defaultAccount] username], [selectedYear yearName],
                selectedMonth.monthName,
                selectedDay.dayName]];
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

// ----------------------------------------------------------------------------------------
// Toolbar delegate
// ----------------------------------------------------------------------------------------
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item;

    if(!toolbarItemCache) {
        toolbarItemCache = [NSMutableDictionary dictionaryWithCapacity: 5];
    }

    item = toolbarItemCache[itemIdentifier];
    if(!item) {
        item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];

        if([itemIdentifier isEqualToString: kHistoryOpenItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Open in Browser", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Open in Browser", @"")];
            [item setTarget: self];
            [item setAction: @selector(openSelectionInBrowser:)];
            [item setToolTip: NSLocalizedString(@"Open Selected Item in Browser", @"")];
            [item setImage: [NSImage imageNamed: NSImageNameNetwork]];
        }
        else if([itemIdentifier isEqualToString: kHistoryDeleteItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Delete", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Delete from Journal", @"")];
            [item setTarget: self];
            [item setAction: @selector(deleteSelectedEntry:)];
            [item setToolTip: NSLocalizedString(@"Delete Selected Item from Journal", @"")];
            [item setImage: [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarDeleteIcon)]];
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
        
        toolbarItemCache[itemIdentifier] = item;
    }
    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return @[kHistoryOpenItemIdentifier,
        kHistoryEditItemIdentifier,
        kHistoryDeleteItemIdentifier,
        kHistoryRefreshItemIdentifier,
        kHistoryDownloadItemIdentifier,
        kHistorySearchItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return @[kHistoryOpenItemIdentifier,
        kHistoryEditItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        kHistoryDeleteItemIdentifier,
        kHistoryRefreshItemIdentifier,
        kHistoryDownloadItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kHistorySearchItemIdentifier];
}

@end
