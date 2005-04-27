//
//  XJBookmarksWindowController+ToolbarDelegate.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Apr 10 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJBookmarksWindowController+ToolbarDelegate.h"


@implementation XJBookmarksWindowController (NSToolbarDelegate)
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
        [item setImage: [NSImage imageNamed: @"Placeholder"]];

        if([itemIdentifier isEqualToString: kBookmarkRefreshItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Refresh", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Refresh", @"")];
            [item setTarget: self];
            [item setAction: @selector(refreshBookmarks:)];
            [item setToolTip: NSLocalizedString(@"Refresh bookmarks", @"")];
            [item setImage: [NSImage imageNamed: @"Refresh"]];
        }
        else if([itemIdentifier isEqualToString: kBookmarkCollapseAllItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Collapse All", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Collapse All", @"")];
            [item setTarget: self];
            [item setAction: @selector(collapseAll:)];
            [item setToolTip: NSLocalizedString(@"Collapse all bookmarks", @"")];
            [item setImage: [NSImage imageNamed: @"CollapseAll"]];
        }
        else if([itemIdentifier isEqualToString: kBookmarkExpandAllItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Expand All", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Expand All", @"")];
            [item setTarget: self];
            [item setAction: @selector(expandAll:)];
            [item setToolTip: NSLocalizedString(@"Expand all bookmarks", @"")];
            [item setImage: [NSImage imageNamed: @"ExpandAll"]];
        }

        [toolbarItemCache setObject: item forKey:itemIdentifier];
        [item release];
    }
    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: kBookmarkRefreshItemIdentifier,
        kBookmarkExpandAllItemIdentifier,
        kBookmarkCollapseAllItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: kBookmarkExpandAllItemIdentifier, kBookmarkCollapseAllItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, kBookmarkRefreshItemIdentifier, nil];
}

@end
