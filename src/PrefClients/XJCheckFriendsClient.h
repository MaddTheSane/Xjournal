//
//  XJCheckFriendsClient.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Feb 13 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniAppKit/OmniAppKit.h>

@interface XJCheckFriendsClient : OAPreferenceClient {
    IBOutlet NSButton *checkFriends, *showDialog, *showDock, *openFriends, *playSound;
    IBOutlet NSMatrix *checkType;
    IBOutlet NSTableView *selectedFriendsTable;
    IBOutlet NSPopUpButton *soundSelection;
}
- (void)buildSoundMenu;
- (IBAction)openAccountWindow: (id)sender;
@end
