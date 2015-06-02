//
//  XJBookmarksWindowController.h
//  Xjournal
//
//  Created by Fraser Speirs on Fri Jan 31 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

/*
 * Implements the controller class for the Bookmarks palette.
 */
#import <Cocoa/Cocoa.h>

#define kBookmarkWindowToolbarIdentifier @"BookmarkWindowToolbarIdentifier"
#define kBookmarkRefreshItemIdentifier @"BookmarkRefreshItemIdentifier"
#define kBookmarkExpandAllItemIdentifier @"BookmarkExpandAllItemIdentifier"
#define kBookmarkCollapseAllItemIdentifier @"BookmarkCollapseAllItemIdentifier"

@class SafariBookmarkParser;

@interface XJBookmarksWindowController : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate> {
    IBOutlet NSOutlineView* outline;
    NSMutableDictionary *toolbarItemCache;
    SafariBookmarkParser *parser;
}

- (IBAction)refreshBookmarks:(id)sender;

- (IBAction)expandAll: (id)sender;
- (IBAction)collapseAll: (id) sender;


@end
