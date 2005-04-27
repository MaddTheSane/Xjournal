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
#import <AppKit/AppKit.h>
#import "XJSafariBookmarkParser.h"

#define kBookmarkWindowToolbarIdentifier @"BookmarkWindowToolbarIdentifier"
#define kBookmarkRefreshItemIdentifier @"BookmarkRefreshItemIdentifier"
#define kBookmarkExpandAllItemIdentifier @"BookmarkExpandAllItemIdentifier"
#define kBookmarkCollapseAllItemIdentifier @"BookmarkCollapseAllItemIdentifier"

@interface XJBookmarksWindowController : NSWindowController {
    IBOutlet NSOutlineView* outline;
    NSMutableDictionary *toolbarItemCache;
    XJSafariBookmarkParser *parser;
}

- (IBAction)refreshBookmarks:(id)sender;

@end
