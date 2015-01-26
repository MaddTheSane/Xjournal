//
//  XJHistoryWindowController.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class XJAccountManager, LJAccount, XJHistoryFilterArrayController, XJExportController;

@interface XJHistoryWindowController : NSWindowController <NSToolbarDelegate> {
    // The NSBrowser for dates
    IBOutlet NSTableView *table;
	IBOutlet NSTableColumn *subjectColumn;
	IBOutlet NSTableColumn *dateColumn;
	NSTableColumn *relevanceColumn;
	
    // The WebView
    IBOutlet WebView *webView;
    IBOutlet NSButton *backButton, *forwardButton;
    IBOutlet NSTextField *urlField;

    // To save us making lots of toolbar items, cache them
    NSMutableDictionary *toolbarItemCache;

    // Search toolbar view
    IBOutlet NSView *searchView;
    IBOutlet NSSearchField *searchField;

    LJAccount *account;
	XJAccountManager *accountManager;
	IBOutlet XJHistoryFilterArrayController *arrayController;
	NSMutableArray *searchKitResults;
	
	NSString *message;
	
	// Export
	XJExportController *exportController;
}

- (IBAction)editEntry: (id)sender;
- (IBAction)beginHistoryExport: (id)sender;

@property (assign) LJAccount *account;
@property (assign) XJAccountManager *accountManager;

- (IBAction)skSearch: (id)sender;
- (NSMutableArray *)searchKitResults;
- (void)setSearchKitResults:(NSMutableArray *)aSearchKitResults;

@property (copy) NSString *message;
@end
