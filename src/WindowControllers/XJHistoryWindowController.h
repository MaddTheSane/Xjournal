//
//  XJHistoryWindowController.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "XJCalendar.h"
#import "WBSearchTextField.h"

#import <WebKit/WebKit.h>

@interface XJHistoryWindowController : NSWindowController {
    // The NSBrowser for dates
    IBOutlet NSBrowser *browser;

    // The WebView
    IBOutlet WebView *webView;
    IBOutlet NSButton *backButton, *forwardButton;
    IBOutlet NSTextField *urlField;
    IBOutlet NSProgressIndicator *wvSpinner;
    
    NSDictionary *dayCounts;

    // To save us making lots of toolbar items, cache them
    NSMutableDictionary *toolbarItemCache;

    // The actual data.
    XJCalendar *cal;

    // Progress sheet
    IBOutlet NSWindow *progressSheet;
    IBOutlet NSProgressIndicator *downloadBar;
    IBOutlet NSTextField *downloadStatus, *downloadTitle;

    BOOL historyIsComplete, userHasDeclinedDownload, terminateDownloadThread, downloadInProgress, updateInProgress, userHasDeclinedUpdate, terminateUpdateThread, updateIsComplete;

    // Search toolbar view
    IBOutlet NSView *searchView;
    IBOutlet WBSearchTextField *searchField;

    NSMutableDictionary *searchCache;
    int selectedSearchType;
    IBOutlet NSMenuItem *selectedMenuItem;

    // Search sheet (for when the toolbar is in Text only mode)
    //IBOutlet NSWindow *searchSheet;
    //IBOutlet WBSearchTextField *searchSheetTextField;

    LJAccount *account;
}

- (LJAccount *)account;
- (void)setCurrentAccount: (LJAccount *)newAcct;
- (NSString *)historyArchivePath;

// Notification of user selection in the browser
- (IBAction)browserChanged:(id)sender;

// get day counts from the LJ server
- (BOOL)analyzeDayCounts;

// Actions for the toolbar items
- (IBAction)openSelectionInBrowser:(id)sender;
- (IBAction)editSelectionInBrowser:(id)sender;
- (IBAction)deleteSelectedEntry:(id)sender;

// Convenience for setting the status field
- (void)setStatus: (NSString *)status;

// Export
- (IBAction)exportHistory: (id)sender;
- (BOOL)loadCachedHistory;

- (void)beginHistoryUpdate: (id)sender;
- (void)beginHistoryDownload: (id)sender;
- (IBAction)cancelHistoryDownload: (id)sender;

// Search
- (IBAction)executeSearch:(id)sender;
- (void)executeSearchForString: (NSString *)target;
- (IBAction)clearSearch:(id)sender;
- (IBAction)setSearchType:(id)sender;

// Editing last entry
- (void)editLastEntry;
@end
