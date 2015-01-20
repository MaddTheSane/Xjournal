//
//  XJPollEditorController+NSToolbarController.m
//  Xjournal
//
//  Created by Fraser Speirs on Wed Apr 09 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJPollEditorController+NSToolbarController.h"

#define kPollAddTextItemIdentifier @"kPollAddTextItemIdentifier"
#define kPollAddMultipleItemIdentifier @"kPollAddMultipleItemIdentifier"
#define kPollAddScaleItemIdentifier @"kPollAddScaleItemIdentifier"

#define kPollDeleteItemIdentifier @"kPollDeleteItemIdentifier"
#define kPollMoveUpItemIdentifier @"kPollMoveUpItemIdentifier"
#define kPollMoveDownItemIdentifier @"kPollMoveDownItemIdentifier"
#define kPollShowCodeItemIdentifier @"kPollShowCodeItemIdentifier"

@implementation XJPollEditorController (NSToolbarController)
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

        if([itemIdentifier isEqualToString: kPollAddTextItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Insert Text", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Insert Text Question", @"")];
            [item setTarget: self];
            [item setAction: @selector(addTextQuestion:)];
            [item setToolTip: NSLocalizedString(@"Add a Text question to the Poll", @"")];
            [item setImage: [NSImage imageNamed: @"InsertTextQuestion"]];
        }
        // Add Scale
        else if([itemIdentifier isEqualToString: kPollAddScaleItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Insert Scale", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Insert Scale Question", @"")];
            [item setTarget: self];
            [item setAction: @selector(addScaleQuestion:)];
            [item setToolTip: NSLocalizedString(@"Add a scale question to the poll", @"")];
            [item setImage: [NSImage imageNamed: @"InsertScaleQuestion"]];
        }
        // Multiple
        else if([itemIdentifier isEqualToString: kPollAddMultipleItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Insert Multiple", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Insert Multple Question", @"")];
            [item setTarget: self];
            [item setAction: @selector(addMultipleQuestion:)];
            [item setToolTip: NSLocalizedString(@"Add a multiple choice question to the poll", @"")];
            [item setImage: [NSImage imageNamed: @"InsertMultipleChoice"]];
        }
        // ----------------------------------------------------------------------------------------
        else if([itemIdentifier isEqualToString: kPollDeleteItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Delete", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Delete Question", @"")];
            [item setToolTip: NSLocalizedString(@"Delete selected question from poll", @"")];
            [item setImage: [NSImage imageNamed: @"delete"]];
            [item setTarget: self];
            [item setAction: @selector(deleteSelectedQuestion:)];
        }
        else if([itemIdentifier isEqualToString: kPollMoveDownItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Move Down", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Move Question Down", @"")];
            [item setToolTip: NSLocalizedString(@"Move the selected question down", @"")];
            [item setImage: [NSImage imageNamed: @"MoveDown"]];
            [item setTarget: self];
            [item setTag: 0];
            [item setAction: @selector(moveSelectedQuestionDown:)];
        }
        else if([itemIdentifier isEqualToString: kPollMoveUpItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Move Up", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Move Question Up", @"")];
            [item setToolTip: NSLocalizedString(@"Move the selected question up", @"")];
            [item setImage: [NSImage imageNamed: @"MoveUp"]];
            [item setTarget: self];
            [item setTag: 0];
            [item setAction: @selector(moveSelectedQuestionUp:)];
        }
        else if([itemIdentifier isEqualToString: kPollShowCodeItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Show Code", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Show Poll Code", @"")];
            [item setToolTip: NSLocalizedString(@"Open the code drawer", @"")];
            [item setImage: [NSImage imageNamed: @"ShowCode"]];
            [item setTarget: drawer];
            [item setAction: @selector(toggle:)];
        }
        [toolbarItemCache setObject: item forKey:itemIdentifier];
        [item release];
    }
    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        kPollAddTextItemIdentifier,
        kPollAddMultipleItemIdentifier,
        kPollAddScaleItemIdentifier,
        kPollDeleteItemIdentifier,
        kPollMoveUpItemIdentifier,
        kPollMoveDownItemIdentifier,
        kPollShowCodeItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        kPollAddTextItemIdentifier,
        kPollAddMultipleItemIdentifier,
        kPollAddScaleItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kPollMoveUpItemIdentifier,
        kPollMoveDownItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kPollShowCodeItemIdentifier,
        kPollDeleteItemIdentifier,nil];
}

@end
