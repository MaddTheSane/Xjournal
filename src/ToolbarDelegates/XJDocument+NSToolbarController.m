//
//  XJDocument+NSToolbarController.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Apr 10 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJDocument+NSToolbarController.h"


@implementation XJDocument (NSToolbarController)
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

        if([itemIdentifier isEqualToString: kEditPostItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Post", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Post Entry", @"")];
            [item setTarget: self];
            //[item setAction: @selector(postEntry:)];
            [item setAction: @selector(postEntryAndDiscardLocalCopy:)];
            [item setToolTip: NSLocalizedString(@"Post Entry to Journal", @"")];
            [item setTag: kPostToolbarItemTag];
            [item setImage: [NSImage imageNamed: @"Post"]];
        }
        // Save item
        else if([itemIdentifier isEqualToString: kEditSaveItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Save", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Save Entry", @"")];
            [item setTarget: self];
            [item setAction: @selector(saveDocument:)];
            [item setToolTip: NSLocalizedString(@"Save Entry to Disk", @"")];
            [item setImage: [NSImage imageNamed: @"disk"]];
        }
        // ----------------------------------------------------------------------------------------
        // URL Link
        else if([itemIdentifier isEqualToString: kEditURLLinkItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Link", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Insert Link", @"")];
            [item setTarget: self];
            [item setAction: @selector(insertLink:)];
            [item setToolTip: NSLocalizedString(@"Open the sheet for building hyperlinks", @"")];
            [item setImage: [NSImage imageNamed: @"Internet"]];
        }
        // IMG Link
        else if([itemIdentifier isEqualToString: kEditImageLinkItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Image", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Insert Image", @"")];
            [item setTarget: self];
            [item setAction: @selector(insertImage:)];
            [item setToolTip: NSLocalizedString(@"Open the sheet for building image links", @"")];
            [item setImage: [NSImage imageNamed: @"Images"]];
        }
        // User Link
        else if([itemIdentifier isEqualToString: kEditUserLinkItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Journal", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Link to Journal", @"")];
            [item setTarget: self];
            [item setAction: @selector(insertLJUser:)];
            [item setToolTip: NSLocalizedString(@"Make a link to a journal", @"")];
            [item setImage: [NSImage imageNamed: @"usericon"]];
        }
        // Cut Link
        else if([itemIdentifier isEqualToString: kEditLJCutItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"LJ Cut", @"")];
            [item setPaletteLabel: NSLocalizedString(@"LiveJournal Cut", @"")];
            [item setTarget: self];
            [item setAction: @selector(insertLJCut:)];
            [item setToolTip: NSLocalizedString(@"Make a LiveJournal cut tag", @"")];
            [item setImage: [NSImage imageNamed: @"LJCutTag"]];
        }
        // ----------------------------------------------------------------------------------------
        // Bold Tag
        else if([itemIdentifier isEqualToString: kEditBoldItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Bold", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Insert Bold Tag", @"")];
            [item setTarget: self];
            [item setAction: @selector(insertBold:)];
            [item setToolTip: NSLocalizedString(@"Insert an HTML Bold Tag", @"")];
            [item setImage: [NSImage imageNamed: @"BoldText"]];
        }
        // Italic Tag
        else if([itemIdentifier isEqualToString: kEditItalicItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Italic", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Insert Italic Tag", @"")];
            [item setTarget: self];
            [item setAction: @selector(insertItalic:)];
            [item setToolTip: NSLocalizedString(@"Insert an HTML Italic Tag", @"")];
            [item setImage: [NSImage imageNamed: @"ItalicText"]];
        }
        // Unserline Tag
        else if([itemIdentifier isEqualToString: kEditUnderlineItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Underline", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Insert Underline Tag", @"")];
            [item setTarget: self];
            [item setAction: @selector(insertUnderline:)];
            [item setToolTip: NSLocalizedString(@"Insert an HTML Underline Tag", @"")];
            [item setImage: [NSImage imageNamed: @"UnderlineText"]];
        }
        // Blockquote Tag
        else if([itemIdentifier isEqualToString: kEditBlockquoteItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Blockquote", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Insert Blockquote Tag", @"")];
            [item setTarget: self];
            [item setAction: @selector(insertBlockquote:)];
            [item setToolTip: NSLocalizedString(@"Insert an HTML Blockquote Tag", @"")];
            [item setImage: [NSImage imageNamed: @"Blockquote"]];
        }
        else if([itemIdentifier isEqualToString: kEditDrawerToggleItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Info", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Toggle Info Drawer", @"")];
            [item setToolTip: NSLocalizedString(@"Show Info Drawer", @"")];
            [item setImage: [NSImage imageNamed: @"Info"]];
            [item setTarget: drawer];
            [item setAction: @selector(toggle:)];
        }
        else if([itemIdentifier isEqualToString: kEditDetectMusicItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Get Music", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Get Current Music", @"")];
            [item setToolTip: NSLocalizedString(@"Get Music from iTunes", @"")];
            [item setImage: [NSImage imageNamed: @"cd"]];
            [item setTarget: self];
            [item setAction: @selector(detectMusicNow:)];
        }
        [toolbarItemCache setObject: item forKey:itemIdentifier];
        [item release];
    }
    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        kEditPostItemIdentifier,
        /*kEditPostAndDiscardItemIdentifier,*/
        kEditSaveItemIdentifier,
        kEditDetectMusicItemIdentifier,
        kEditURLLinkItemIdentifier,
        kEditImageLinkItemIdentifier,
        kEditUserLinkItemIdentifier,
        kEditLJCutItemIdentifier,
        kEditBlockquoteItemIdentifier,
        kEditBoldItemIdentifier,
        kEditItalicItemIdentifier,
        kEditUnderlineItemIdentifier,
        kEditDrawerToggleItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        kEditPostItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        kEditURLLinkItemIdentifier,
        kEditImageLinkItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        kEditBoldItemIdentifier,
        kEditItalicItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        kEditDetectMusicItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier, kEditDrawerToggleItemIdentifier, nil];
}
@end
