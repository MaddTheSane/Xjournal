//
//  XJFriendsController-NSToolbarController.m
//  Xjournal
//
//  Created by Fraser Speirs on Fri Apr 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJFriendsController-NSToolbarController.h"
#import "LJFriend-ABExtensions.h"

#define kFriendsToolbarIdentifier @"FriendsToolbar"

#define kAddFriendToolbarItemIdentifier @"kFriendToolbarItemIdentifier"
#define kAddGroupToolbarItemIdentifier @"kAddGroupToolbarItemIdentifier"
#define kChatToolbarItemIdentifier @"kChatToolbarItemIdentifier"
#define kDeleteGroupToolbarItemIdentifier @"kDeleteGroupToolbarItemIdentifier"
#define kDeleteFriendToolbarItemIdentifier @"kDeleteFriendToolbarItemIdentifier"
#define kSaveChangesToolbarItemIdentifier @"kSaveChangesToolbarItemIdentifier"
#define kAddressBookToolbarItemIdentifier @"kAddressBookToolbarItemIdentifier"
#define kAddToAddressBookToolbarItemIdentifier @"kAddToAddressBookToolbarItemIdentifier"
#define kFriendsAccountSelectionPopup @"kFriendsAccountSelectionPopup"
#define kFriendsViewTypeSelectionPopup @"kFriendsViewTypeSelectionPopup"
#define kRefreshFriendsToolbarItemIdentifier @"kRefreshFriendsToolbarItemIdentifier"

@implementation XJFriendsController (NSToolbarController)
- (void)setUpToolbar
{
    // Set up NSToolbar
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: kFriendsToolbarIdentifier];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDelegate: self];
    [[self window] setToolbar: toolbar];
    [toolbar release];
}

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

        if([itemIdentifier isEqualToString: kAddFriendToolbarItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Add Friend", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Add Friend", @"")];
            [item setTarget: self];
            [item setAction: @selector(addFriend:)];
            [item setToolTip: NSLocalizedString(@"Add a user as a friend", @"")];
            [item setImage: [NSImage imageNamed: @"AddUser"]];
        }
        else if([itemIdentifier isEqualToString: kAddGroupToolbarItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Add Group", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Add New Group", @"")];
            [item setTarget: self];
            [item setAction: @selector(addGroup:)];
            [item setToolTip: NSLocalizedString(@"Add a new Friend Group", @"")];
            [item setImage: [NSImage imageNamed: @"AddGroup"]];
        }
        else if([itemIdentifier isEqualToString: kChatToolbarItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Chat", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Chat", @"")];
            [item setTarget: self];
            [item setAction: @selector(launchChatSession:)];
            [item setToolTip: NSLocalizedString(@"Chat with this user", @"")];
            [item setImage: [NSImage imageNamed: @"iChatToolbar"]];
        }
        else if([itemIdentifier isEqualToString: kDeleteFriendToolbarItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Delete Friend", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Delete Friend", @"")];
            [item setTarget: self];
            [item setAction: @selector(deleteSelectedFriend:)];
            [item setToolTip: NSLocalizedString(@"Remove this friend from your friends list", @"")];
            [item setImage: [NSImage imageNamed: @"DeleteFriend"]];
        }
        else if([itemIdentifier isEqualToString: kDeleteGroupToolbarItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Delete Group", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Delete Group", @"")];
            [item setTarget: self];
            [item setAction: @selector(deleteSelectedGroup:)];
            [item setToolTip: NSLocalizedString(@"Remove this friend group", @"")];
            [item setImage: [NSImage imageNamed: @"DeleteGroup"]];
        }
        else if([itemIdentifier isEqualToString: kSaveChangesToolbarItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Save", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Save Changes", @"")];
            [item setTarget: nil];
            [item setAction: @selector(saveDocument:)];
            [item setToolTip: NSLocalizedString(@"Save changes to LiveJournal", @"")];
            [item setImage: [NSImage imageNamed: @"disk"]];
        }
        else if([itemIdentifier isEqualToString: kAddressBookToolbarItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Addresses", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Address Book", @"")];
            [item setTarget: self];
            [item setAction: @selector(launchAddressBook:)];
            [item setToolTip: NSLocalizedString(@"Open Address Book", @"")];
            [item setImage: [NSImage imageNamed: @"addressbook"]];
        }
        else if([itemIdentifier isEqualToString: kAddToAddressBookToolbarItemIdentifier]) {
            [item setLabel: NSLocalizedString(@"Add Address", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Add to Address Book", @"")];
            [item setTarget: self];
            [item setAction: @selector(addSelectedFriendToAddressBook:)];
            [item setToolTip: NSLocalizedString(@"Add to Address Book", @"")];
            [item setImage: [NSImage imageNamed: @"addToAddressBook"]];
        }
        else if([itemIdentifier isEqualToString: kFriendsAccountSelectionPopup]) {
            [item setView: accountToolbarView];
            [item setLabel: NSLocalizedString(@"Account", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Account", @"")];
            [item setToolTip: NSLocalizedString(@"Selects an account to work with", @"")];
            [item setMinSize: NSMakeSize(130, 26)];
            [item setMaxSize: NSMakeSize(130, 26)];

            NSMenuItem *menuRep = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Account", @"") action: nil keyEquivalent: @""];
            [menuRep setSubmenu: [accountToolbarPopup menu]];
            [item setMenuFormRepresentation: menuRep];
            [menuRep release];
            
        }
        else if([itemIdentifier isEqualToString: kFriendsViewTypeSelectionPopup]) {
            [item setView: showTypeToolbarView];
            [item setLabel: NSLocalizedString(@"View", @"")];
            [item setPaletteLabel: NSLocalizedString(@"View", @"")];
            [item setToolTip: NSLocalizedString(@"Filter out Users or Communities", @"")];
            [item setMinSize: NSMakeSize(130, 26)];
            [item setMaxSize: NSMakeSize(130, 26)];
            
            NSMenuItem *menuRep = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"View", @"") action: nil keyEquivalent: @""];
            [menuRep setSubmenu: [accountToolbarPopup menu]];
            [item setMenuFormRepresentation: menuRep];
            [menuRep release];
        }
		else if([itemIdentifier isEqualToString: kRefreshFriendsToolbarItemIdentifier]) {
			[item setLabel: NSLocalizedString(@"Reload", @"")];
            [item setPaletteLabel: NSLocalizedString(@"Reload Friends List", @"")];
            [item setTarget: self];
            [item setAction: @selector(refreshFriends:)];
            [item setToolTip: NSLocalizedString(@"Reload Friends List from Server", @"")];
            [item setImage: [NSImage imageNamed: @"Refresh"]];
		}
        [toolbarItemCache setObject: item forKey:itemIdentifier];
        [item release];
    }
    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        kAddFriendToolbarItemIdentifier,
        kAddGroupToolbarItemIdentifier,
        kChatToolbarItemIdentifier,
        kDeleteFriendToolbarItemIdentifier,
        kDeleteGroupToolbarItemIdentifier,
        kSaveChangesToolbarItemIdentifier,
        kAddToAddressBookToolbarItemIdentifier,
        kAddressBookToolbarItemIdentifier,
        kFriendsAccountSelectionPopup,
        kFriendsViewTypeSelectionPopup,
		kRefreshFriendsToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        kSaveChangesToolbarItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        kAddFriendToolbarItemIdentifier,
        kAddGroupToolbarItemIdentifier,
        kDeleteFriendToolbarItemIdentifier,
        kDeleteGroupToolbarItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        kFriendsAccountSelectionPopup,
        kFriendsViewTypeSelectionPopup,
        NSToolbarFlexibleSpaceItemIdentifier,
        kAddToAddressBookToolbarItemIdentifier,
        kAddressBookToolbarItemIdentifier,
        kChatToolbarItemIdentifier,
		kRefreshFriendsToolbarItemIdentifier,
        nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if([[theItem itemIdentifier] isEqualToString: kChatToolbarItemIdentifier]) {
        LJFriend *selectedFriend = [self selectedFriend];
        if(!selectedFriend) return NO;
        
        return [[self selectedFriend] chatURL] != nil;
    }
    else if([[theItem itemIdentifier] isEqualToString: kDeleteFriendToolbarItemIdentifier]) {
        if(![self allFriendsIsSelected]) {
            [theItem setLabel: NSLocalizedString(@"Remove from Group", @"")];
            [theItem setAction: @selector(removeSelectedFriendFromGroup:)];
            return [self canRemoveFriendFromGroup];
        }
        else {
            [theItem setLabel: NSLocalizedString(@"Remove Friend", @"")];
            [theItem setAction: @selector(deleteSelectedFriend:)];
            return [self canDeleteFriend];
        }
    }
    else if([[theItem itemIdentifier] isEqualToString: kDeleteGroupToolbarItemIdentifier]) {
        return [self canDeleteGroup];
    }
    return YES;
}
@end
