//
//  XJMainWindowController.m
//  Xjournal
//
//  Created by Fraser Speirs on Fri Mar 21 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJMainWindowController.h"
#import "XJPreferences.h"
#import "XJAccountManager.h"

#define kMainWindowAutoSaveName @"MainWindowAutoSaveName"
#define CACHED_HISTORY_PATH [@"~/Library/Application Support/Xjournal/History.plist" stringByExpandingTildeInPath]

@implementation XJMainWindowController
- (id)init
{
    if(self == [super initWithWindowNibName: @"XJMainWindow"]) {
        [[self window] setFrameAutosaveName: kMainWindowAutoSaveName];
        cal = [[XJCalendar alloc] init];
        if(![self loadCachedHistory])
            [self analyzeDayCounts];
        [tree reloadData];
        return self;
    }
    return nil;
}

- (BOOL)loadCachedHistory
{
    NSFileManager *man = [NSFileManager defaultManager];
    BOOL isDir;
    if([man fileExistsAtPath: CACHED_HISTORY_PATH isDirectory: &isDir] && !isDir) {
        [cal configureWithContentsOfFile: CACHED_HISTORY_PATH];
        return YES;
    }
    return NO;
}

- (void)analyzeDayCounts
{
    NSEnumerator *dates;
    NSCalendarDate *date;

    dayCounts = [[[[XJAccountManager defaultManager] loggedInAccount] defaultJournal] getDayCounts];
    dates = [[dayCounts allKeys] objectEnumerator];

    while(date = [dates nextObject]) {
        XJDay *day = [cal dayForCalendarDate: date];
        [day setPostCount: [[dayCounts objectForKey: date] intValue]];
    }
}

// ----------------------------------------------------------------------------------------
// OutlineView Data Source
// ----------------------------------------------------------------------------------------
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil) {
        // Return root item's child
        return [cal yearAtIndex: index];
    }
    else {
        // return child of item
        return [(XJYear *)item monthAtIndex: index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    // Only years are expandable
    return [item isKindOfClass: [XJYear class]];
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil) {
        return [cal numberOfYears];
    }
    else {
        NSAssert([item isKindOfClass: [XJYear class]], @"Wrong type");
        return [(XJYear *)item numberOfMonths];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if([item isKindOfClass: [XJYear class]])
        return [NSString stringWithFormat: @"%d", [(XJYear *)item yearName]];
    else
        return [NSString stringWithFormat: @"%@", [(XJMonth *)item displayName]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item { return NO; }

/*
- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if(![[tableColumn identifier] isEqualToString: @"title"]) {
        if([item isKindOfClass: [XJBookmarkFolder class]])
            [(NSTextFieldCell*)cell setTextColor: [NSColor grayColor]];
        else
            [(NSTextFieldCell*)cell setTextColor: [NSColor blackColor]];
    }
}
*/

// ----------------------------------------------------------------------------------------
// Outline and table selection target
// ----------------------------------------------------------------------------------------
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    outlineSelectedItem = [tree itemAtRow: [tree selectedRow]];
    [tableBackingStore release];
    tableBackingStore = nil;
    displayedEntry = nil;
    [table reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if([table selectedRow] != -1) {
        displayedEntry = [tableBackingStore objectAtIndex: [table selectedRow]];
        [text setString: [displayedEntry content]];
    }else{
        [text setString: @""];
    }
}

// ----------------------------------------------------------------------------------------
// NSTableDataSource
// ----------------------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(!outlineSelectedItem) return 0;

    if([outlineSelectedItem isKindOfClass: [XJYear class]])
        return 0;
    else
        return [(XJMonth *)outlineSelectedItem numberOfDays];
}

- (id)tableView:(NSTableView *)aTableView
	objectValueForTableColumn:(NSTableColumn *)aTableColumn
	row:(int)rowIndex
{
    if(!outlineSelectedItem) return @"";

    if([outlineSelectedItem isKindOfClass: [XJYear class]])
        return @"";
    else {
        if(!tableBackingStore) {
            XJMonth *month = (XJMonth *)outlineSelectedItem;
            tableBackingStore = [[month entriesInMonth] retain];
        }

        LJEntry *entry = [tableBackingStore objectAtIndex: rowIndex];

        if([[aTableColumn identifier] isEqualToString: @"subject"])
            return [entry subject];
        else
            return [[entry date] description];
    }
}
@end
