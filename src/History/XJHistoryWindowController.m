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
#import "NSString+Extensions.h"
#import "LJEntryExtensions.h"
#import "XJAccountManager.h"
#import "XJDocument.h"
#import "NetworkConfig.h"
#import "XJHistoryFilterArrayController.h"
#import "XJSearchResult.h"
#import "XJRelevanceCell.h"
#import "XJExportController.h"

#import <CoreServices/CoreServices.h>

#define kHistoryWindowToolbarIdentifier @"HistoryWindowToolbarIdentifier" 
#define kHistoryOpenItemIdentifier @"HistoryOpenItemIdentifier"
#define kHistoryEditItemIdentifier @"HistoryEditItemIdentifier"
#define kHistoryDeleteItemIdentifier @"HistoryDeleteItemIdentifier"
#define kHistorySearchItemIdentifier @"HistorySearchItemIdentifier"

#define kHistoryAutosaveName @"kHistoryAutosaveName"


@interface XJHistoryWindowController (PrivateAPI)
- (NSString *)zeroizedString:(int)number;
@end

@implementation XJHistoryWindowController 

- (id)init
{
	self = [super initWithWindowNibName:@"HistoryWindow"];
    if(self) {
        [[self window] setFrameAutosaveName: kHistoryAutosaveName];
		
		[self setAccountManager: [XJAccountManager defaultManager]];
		[self setAccount: [[self accountManager] defaultAccount]];
		
		relevanceColumn = [[NSTableColumn alloc] initWithIdentifier: @"relevance"];
		[[relevanceColumn headerCell] setTitle: @"Relevance"];
		[relevanceColumn setDataCell: [[[XJRelevanceCell alloc] init] autorelease]];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updateStarted:)
													 name: LJHistoryDownloadStartedNotification
												   object: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updateEnded:)
													 name: LJHistoryDownloadEndedNotification
												   object: nil];
		
		if([[[self account] history] isUpdating])
			[self setMessage: @"Synchronizing with server"];
	}
	return self;
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

    [webView setFrameLoadDelegate: self];
    [webView setPolicyDelegate: self];
    [webView setPreferencesIdentifier: XJ_HISTORY_PREF_IDENT];
    [[webView preferences] setAutosaves: YES];
	
	[table setTarget: self];
	[table setDoubleAction: @selector(openSelectionInBrowser:)];
}

- (LJAccount *)account
{
    return account;
}

- (void)setAccount: (LJAccount *)newAcct
{
    account = newAcct;
}

- (void)updateStarted: (NSNotification *)note {
	[self setMessage: @"Synchronizing with server"];	
}

- (void)updateEnded: (NSNotification *)note {
	[self setMessage: @""];	
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
	accountManager = anAccountManager;
}


// =========================================================== 
// - searchKitResults:
// =========================================================== 
- (NSMutableArray *)searchKitResults {
    return searchKitResults; 
}

// =========================================================== 
// - setSearchKitResults:
// =========================================================== 
- (void)setSearchKitResults:(NSMutableArray *)aSearchKitResults {
    if (searchKitResults != aSearchKitResults) {
        [aSearchKitResults retain];
        [searchKitResults release];
        searchKitResults = aSearchKitResults;
    }
}


- (IBAction)openSelectionInBrowser:(id)sender
{
	LJEntry *selectedItem = [[LJEntry alloc] init];
	if([[self searchKitResults] count] > 0) {
		XJSearchResult *result = [[arrayController selectedObjects] objectAtIndex: 0];
		[selectedItem configureWithContentsOfFile: [[result fileURL] path]];
	}
	else {
		LJLightwieghtHistoryIndexItem *item = [[arrayController selectedObjects] objectAtIndex: 0];
		[selectedItem configureWithContentsOfFile: [item filePath]];
	}
	
	NSURL *urlToOpen = [selectedItem readCommentsHttpURL];
	[[NSWorkspace sharedWorkspace] openURL: urlToOpen];
}

- (IBAction)skSearch: (id)sender {
	[self willChangeValueForKey: @"searchKitResults"];	
	[self setSearchKitResults: [NSMutableArray array]];

	[arrayController unbind: @"contentArray"];
	[subjectColumn unbind: @"value"];
	[dateColumn unbind: @"value"];
	
	if([[sender stringValue] length] > 0) {
		
		[arrayController bind: @"contentArray" toObject: self
				  withKeyPath: @"searchKitResults" options: nil];
		
		/*[relevanceColumn bind: @"value" toObject: arrayController
					  withKeyPath: @"arrangedObjects.relevance" options: nil];
		*/
		[subjectColumn bind: @"value" toObject: arrayController
				withKeyPath: @"arrangedObjects.displayName" options: nil];
		
		if(![[table tableColumns] containsObject: relevanceColumn]) {
			[dateColumn retain];
			[table removeTableColumn: dateColumn];
			[table addTableColumn: relevanceColumn];
		}

		
	} 
	else {
		[arrayController bind: @"contentArray" toObject: self
				  withKeyPath: @"account.history.lightIndex.entries" options: nil];
		
		[dateColumn bind: @"value" toObject: arrayController
			 withKeyPath: @"arrangedObjects.date" options: nil];
		
		[subjectColumn bind: @"value" toObject: arrayController
				withKeyPath: @"arrangedObjects.displaySubject" options: nil];
		
		[table removeTableColumn: relevanceColumn];
		[table addTableColumn: dateColumn];
	}
	
	SKIndexRef indexArray[1];
	indexArray[0] = [[[self account] history] searchKitIndex];
	CFArrayRef searchArray = CFArrayCreate(NULL,
										   (void *)indexArray,
										   1,
										   &kCFTypeArrayCallBacks);
	SKSearchGroupRef searchGroup = SKSearchGroupCreate(searchArray);

	SKSearchResultsRef searchResults
		= SKSearchResultsCreateWithQuery(searchGroup, // the search group
													  // reference
										 (CFStringRef)[sender stringValue], //our query
										 kSKSearchPrefixRanked, // the kind of search
										 1000, // the maximum number of results
										 NULL, // context, may be null
										 NULL); // callback function for hit
												// testing during searching.
												// May be NULL
	
    // now to go through the results, we can create an array for each Search Kit
    // document and another for the scores, and then populate them from the
    // SearchResults
    SKDocumentRef outDocumentsArray[1000];
    float scoresArray[1000];
    
    CFIndex resultCount = 
        SKSearchResultsGetInfoInRange(searchResults, // the search result set
                                      CFRangeMake(0,1000), // which results we're
														   // interested in seeing
                                      outDocumentsArray, // an array of SKDocumentRef
                                      NULL, // An array of indexes in which the
                                            // found docouments reside.
                                            // May be NULL provided that the
                                            // client does not care. And we
                                            // don't because there's only one
                                            // index we're searching
                                      scoresArray); // an array of scores
    
    NSLog([NSString stringWithFormat:@"%d Results Found\n",resultCount]);
	
	int i;

    for (i=0;i<resultCount;i++) {
		float score = scoresArray[i];
        SKDocumentRef hit = outDocumentsArray[i];
        
		NSURL *url = (NSURL *)SKDocumentCopyURL(hit);
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL: url];
		
		XJSearchResult *result = [[XJSearchResult alloc] init];
		[result setFileURL: url];
		if([dict objectForKey: @"Subject"])
			[result setDisplayName: [dict objectForKey: @"Subject"]];
		else
			[result setDisplayName: [dict objectForKey: @"Content"]];
				
		[result setRelevance: score];
		[[self mutableArrayValueForKey: @"searchKitResults"] addObject: result];
		NSLog(@"Added result: %@", [result displayName]);
    }
	[self didChangeValueForKey: @"searchKitResults"];
}


// =========================================================== 
// - message:
// =========================================================== 
- (NSString *)message {
    return message; 
}

// =========================================================== 
// - setMessage:
// =========================================================== 
- (void)setMessage:(NSString *)aMessage {
    if (message != aMessage) {
        [aMessage retain];
        [message release];
        message = aMessage;
		NSLog(message);
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	LJEntry *selectedEntry = [[LJEntry alloc] init];
	
	if([[arrayController selectedObjects] count] == 0)
		return;
	
	id item = [[arrayController selectedObjects] objectAtIndex: 0];
	if([item isKindOfClass: [XJSearchResult class]])
		[selectedEntry configureWithContentsOfFile: [[item fileURL] path]];
	else
		[selectedEntry configureWithContentsOfFile:[item filePath]];
	
	
	NSString *html = [selectedEntry content];
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

	NSString *fullHTML = [[selectedEntry metadataHTML] stringByAppendingString: html];
	
	fullHTML = [NSString stringWithFormat: @"<html><head><style type=\"text/css\">.xjljcut { background-color: #CCFFFF; padding-top: 5px; padding-bottom: 5px }</style></head><body>%@</body</html>", fullHTML];
	
	[[webView mainFrame] loadHTMLString: fullHTML baseURL: nil];
	
}

- (void)tableView:(NSTableView *)aTableView 
  willDisplayCell:(id)aCell 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(int)rowIndex
{
	if([[aTableColumn identifier] isEqualToString: @"relevance"]) {
		if([[self searchKitResults] count] > 0) {
			XJSearchResult *result = [[self searchKitResults] objectAtIndex: rowIndex];
			[(XJRelevanceCell *)aCell setRelevance: [result relevance]];
		}
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
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    if (frame == [sender mainFrame]){

    }    
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if (frame == [sender mainFrame]){
    }
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if (frame == [sender mainFrame]){
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
		[listener ignore];
 // Instead of opening it in the WebView, we want to open
// the URL in the user's default browser
		[[NSWorkspace sharedWorkspace] openURL: [actionInformation objectForKey:WebActionOriginalURLKey]];
    }
}

- (IBAction)editEntry: (id)sender
{
	if([[arrayController selectedObjects] count] > 0) {
		LJEntry *selectedItem = [[LJEntry alloc] init];
		if([[self searchKitResults] count] > 0) {
			XJSearchResult *result = [[arrayController selectedObjects] objectAtIndex: 0];
			[selectedItem configureWithContentsOfFile: [[result fileURL] path]];
		}
		else {
			LJLightwieghtHistoryIndexItem *item = [[arrayController selectedObjects] objectAtIndex: 0];
			[selectedItem configureWithContentsOfFile: [item filePath]];
		}
	
		NSDocumentController *docController = [NSDocumentController sharedDocumentController];
		id doc = [docController openUntitledDocumentOfType: @"Xjournal Entry" display: NO];

		[doc showWindows];
		[doc setEntry: selectedItem];
	}
}

- (IBAction)deleteEntry: (id)sender {
	if([[arrayController selectedObjects] count] > 0) {
		NSEnumerator *en = [[arrayController selectedObjects] objectEnumerator];
		LJLightwieghtHistoryIndexItem *histItem;
		while(histItem = [en nextObject]) {
			LJEntry *entry = [[LJEntry alloc] init];
			[entry configureWithContentsOfFile: [histItem filePath]];
			[[[self account] history] deleteEntry: entry];
			
			[entry release];
		}
	}
}

- (IBAction)beginHistoryExport: (id)sender {
	if(!exportController)
		exportController = [[XJExportController alloc] init];
	[exportController exportFromAccount: [self account]];
}
@end

@implementation XJHistoryWindowController (PrivateAPI)


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
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
	 itemForItemIdentifier:(NSString *)itemIdentifier 
 willBeInsertedIntoToolbar:(BOOL)flag
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
            [item setAction: @selector(deleteEntry:)];
            [item setToolTip: NSLocalizedString(@"Delete Selected Item from Journal", @"")];
            [item setImage: [NSImage imageNamed: @"delete"]];
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
            [item setAction: @selector(editEntry:)];
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
        NSToolbarFlexibleSpaceItemIdentifier,
        kHistorySearchItemIdentifier, nil];
}
@end