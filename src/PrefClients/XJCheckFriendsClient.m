//
//  XJCheckFriendsClient.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Feb 13 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJCheckFriendsClient.h"
#import <LJKit/LJKit.h>
#import <OmniAppKit/OmniAppKit.h>

#import "XJPreferences.h"
#import "XJCheckFriendsSessionManager.h"
#import "XJAccountManager.h"

@interface XJCheckFriendsClient (PrivateAPI)
- (NSString *)nullCheck:(NSString *)test;
- (NSMutableDictionary *)makeMutable: (NSDictionary *)dict;
@end

@implementation XJCheckFriendsClient
- (void)awakeFromNib
{
    // Set up the group check table
    NSButtonCell *tPrototypeCell = [[NSButtonCell alloc] initTextCell: @""];
    
    [tPrototypeCell setEditable: YES];
    [tPrototypeCell setButtonType:NSSwitchButton];
    [tPrototypeCell setImagePosition:NSImageOnly];
    [tPrototypeCell setControlSize:NSSmallControlSize];

    [[selectedFriendsTable tableColumnWithIdentifier: @"check"] setDataCell: tPrototypeCell];
    [tPrototypeCell release];
    
    [selectedFriendsTable reloadData];

    // Build menu of system sounds
    [self buildSoundMenu];
}

- (void)buildSoundMenu
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSEnumerator *locs = [[NSArray arrayWithObjects: @"/System/Library/Sounds", [@"~/Library/Sounds" stringByExpandingTildeInPath], nil] objectEnumerator];
    NSString *path;

    NSMenu *menu = [[NSMenu alloc] init];
    
    while(path = [locs nextObject]) {
        NSDirectoryEnumerator *dEnum = [manager enumeratorAtPath: path];
        NSString *file, *baseName;

        while(file = [dEnum nextObject]) {
            NSMenuItem *item;
            if(![file hasPrefix: @"."]) {
                baseName = [[[file lastPathComponent] componentsSeparatedByString: @"."] objectAtIndex: 0];
                item = [[NSMenuItem alloc] initWithTitle: baseName action: @selector(setValueForSender:) keyEquivalent: @""];
                [item setTarget: self];
                [item setRepresentedObject: [NSString stringWithFormat: @"%@/%@", path,file]];
                [menu addItem: item];
                [item release];
            }
        }
    }
    [soundSelection setMenu: menu];
    [menu release];
}

- (void)setValueForSender:(id)sender
{
    if([sender isEqualTo: checkFriends]) {
        [defaults setBool: [sender state] forKey: CHECKFRIENDS_DO_CHECK];
        if([sender state]) {
            [[XJCheckFriendsSessionManager sharedManager] startCheckingFriends];
        }
        else {
            [[XJCheckFriendsSessionManager sharedManager] stopCheckingFriends];
        }
        
        [self updateUI];
    }
    else if([sender isEqualTo: showDialog])
        [defaults setBool: [sender state] forKey: CHECKFRIENDS_SHOW_DIALOG];
    else if([sender isEqualTo: showDock]) {
        [defaults setBool: [sender state] forKey: CHECKFRIENDS_DOCK_ICON];
        [openFriends setEnabled: [sender state]];
    }
    else if([sender isEqualTo: openFriends]) {
        [defaults setBool: [sender state] forKey: CHECKFRIENDS_OPEN_PAGE];
    }
    else if([sender isEqualTo: checkType]) {
        // Tag 0 == All friends
        // Tag 1 == Specific groups
        int tag = [[sender selectedCell] tag];
        [defaults setInteger: tag forKey: CHECKFRIENDS_GROUP_TYPE];

        // Also push this through to the session manager
        [[XJCheckFriendsSessionManager sharedManager] setCheckingMode: tag];
        
        [selectedFriendsTable reloadData];
    }
    else if([sender isEqualTo: playSound]) {
        [soundSelection setEnabled: [sender state]];
        [defaults setBool: [sender state] forKey: CHECKFRIENDS_PLAY_SOUND];
    }
    else if([sender isKindOfClass: [NSMenuItem class]]) {
        NSSound *sound = [[NSSound alloc] initWithContentsOfFile: [sender representedObject] byReference: NO];
        if(sound)
            [sound play];
        [defaults setObject: [sender representedObject] forKey: CHECKFRIENDS_SELECTED_SOUND];
    }
}

- (void)updateUI
{
    BOOL shouldBeEnabled = [defaults boolForKey: CHECKFRIENDS_DO_CHECK];
    [checkFriends setState: [defaults boolForKey: CHECKFRIENDS_DO_CHECK]];
    
    [showDialog setState: [defaults boolForKey: CHECKFRIENDS_SHOW_DIALOG]];
    [showDialog setEnabled: shouldBeEnabled];
    
    [showDock setState: [defaults boolForKey: CHECKFRIENDS_DOCK_ICON]];
    [showDock setEnabled: shouldBeEnabled];
    
    [openFriends setState: [defaults boolForKey: CHECKFRIENDS_OPEN_PAGE]];
    [openFriends setEnabled: shouldBeEnabled];
    
    [playSound setState: [defaults boolForKey: CHECKFRIENDS_PLAY_SOUND]];
    [playSound setEnabled: shouldBeEnabled];

    [soundSelection setEnabled: (shouldBeEnabled && [defaults boolForKey: CHECKFRIENDS_PLAY_SOUND]) ];
    [soundSelection selectItemAtIndex: [soundSelection indexOfItemWithRepresentedObject: [defaults stringForKey: CHECKFRIENDS_SELECTED_SOUND]]];
    
    [checkType selectCellWithTag: [defaults integerForKey: CHECKFRIENDS_GROUP_TYPE]];
    [checkType setEnabled: shouldBeEnabled];
    [selectedFriendsTable reloadData];
}

// ----------------------------------------------------------------------------------------
// NSTableDataSource - friend group security
// ----------------------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    if(!acct)
        return 1;
    
    return [[acct groupArray] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    if(!acct) {
        if([[aTableColumn identifier] isEqualToString: @"name"])
            return @"(not logged in)";
        else
            return [NSNumber numberWithInt: 0];
    }
    else {
        NSArray *groups = [acct groupArray];
        LJGroup *rowGroup = [groups objectAtIndex: rowIndex];

        if([[aTableColumn identifier] isEqualToString: @"name"])
            return [rowGroup name];
        else {
            // Here return an NSNumber signifying whether the group is being checked for.
            return [NSNumber numberWithBool: [XJPreferences shouldCheckForGroup: rowGroup]];
        }
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    NSArray *groups = [acct groupArray];
    LJGroup *rowGroup = [groups objectAtIndex: rowIndex];

    if([[aTableColumn identifier] isEqualToString: @"check"]) {
        [XJPreferences setShouldCheck: [anObject boolValue] forGroup: rowGroup];
    }
    [aTableView reloadData];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return [[aTableColumn identifier] isEqualToString: @"check"];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    
    if([[aTableColumn identifier] isEqualToString: @"check"]) {
        [aCell setEnabled: ([defaults boolForKey: CHECKFRIENDS_DO_CHECK] && (acct && [defaults integerForKey: CHECKFRIENDS_GROUP_TYPE] == 1) ) ];
    }
}

- (IBAction)openAccountWindow: (id)sender
{
    [NSApp sendAction: @selector(showAccountEditWindow:) to: nil from: self];
}
@end

@implementation XJCheckFriendsClient (PrivateAPI)
- (NSString *)nullCheck:(NSString *)test
{
    if(test != nil)
        return test;
    else
        return @"";
}

- (NSMutableDictionary *)makeMutable: (NSDictionary *)dict
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary addEntriesFromDictionary: dict];
    return dictionary;
}
@end