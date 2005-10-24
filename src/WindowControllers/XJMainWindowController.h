//
//  XJMainWindowController.h
//  Xjournal
//
//  Created by Fraser Speirs on Fri Mar 21 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <LJKit/LJKit.h>

#import "XJCalendar.h"

@interface XJMainWindowController : NSWindowController {
    IBOutlet NSDrawer *drawer;
    IBOutlet NSTableView *table;
    IBOutlet NSTextView *text;
    IBOutlet NSOutlineView *tree;

    XJCalendar *cal;
    NSDictionary *dayCounts;

    id outlineSelectedItem;
    NSArray *tableBackingStore;

    LJEntry *displayedEntry;
}

- (void)analyzeDayCounts;
- (BOOL)loadCachedHistory;
@end
