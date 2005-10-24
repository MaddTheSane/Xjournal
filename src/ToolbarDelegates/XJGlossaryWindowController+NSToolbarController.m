//
//  XJGlossaryWindowController+NSToolbarController.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Apr 10 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJGlossaryWindowController+NSToolbarController.h"


@implementation XJGlossaryWindowController (NSToolbarController)
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

        if([itemIdentifier isEqualToString: kGlossaryRefreshItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Refresh", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Refresh", @"")];
            [item setTarget: self];
            [item setAction: @selector(refresh:)];
            [item setToolTip: NSLocalizedString(@"Refresh Glossary", @"")];
            [item setImage: [NSImage imageNamed: @"Refresh"]];
        }
        else if([itemIdentifier isEqualToString: kGlossaryInsertItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Insert", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Insert", @"")];
            [item setTarget: self];
            [item setAction: @selector(insertSelection:)];
            [item setToolTip: NSLocalizedString(@"Insert Selected Glossary item at Insertion Point", @"")];
            [item setImage: [NSImage imageNamed: @"Insert"]];
        }
        else if([itemIdentifier isEqualToString: kGlossaryOpenItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Open Folder", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Open Glossary Folder", @"")];
            [item setTarget: self];
            [item setAction: @selector(openLocalGlossary:)];
            [item setToolTip: NSLocalizedString(@"Open the Glossary Folder", @"")];
            [item setImage: [NSImage imageNamed: @"Folder"]];
        }
        [toolbarItemCache setObject: item forKey:itemIdentifier];
        [item release];
    }
    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: kGlossaryInsertItemIdentifier,
        kGlossaryOpenItemIdentifier,
        kGlossaryRefreshItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects: kGlossaryInsertItemIdentifier,
        kGlossaryOpenItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kGlossaryRefreshItemIdentifier, nil];
}
@end
