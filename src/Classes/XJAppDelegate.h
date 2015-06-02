//
//  XJAppDelegate.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "XJHistoryWindowController.h"
#import "XJFriendsController.h"
#import "XJGlossaryWindowController.h"
#import "XJBookmarksWindowController.h"
#import "XJAccountEditWindowController.h"

@class XJPollEditorController;
@class XJPreferencesController;

@interface XJAppDelegate : NSObject <NSApplicationDelegate>

// Connections to the progress panel
@property (weak) IBOutlet NSWindow *loginPanel;
@property (weak) IBOutlet NSProgressIndicator *spinner;
// cmd-delete menu outlets
@property (weak) IBOutlet NSMenuItem *deleteFriend;
@property (weak) IBOutlet NSMenuItem *deleteFromGroup;

//! The Accounts > top level menu item
@property (weak) IBOutlet NSMenuItem *accountItem;


    //! Are we showing the dock badge?
@property BOOL showingDockBadge;

//! Target for AppMenu -> Login
- (IBAction)logIn:(id)sender;

// Targets for Window menu items
- (IBAction)showPrefsWindow:(id)sender;
- (IBAction)showHistoryWindow:(id)sender;
- (IBAction)showFriendsWindow:(id)sender;
- (IBAction)showGlossaryWindow:(id)sender;
- (IBAction)showBookmarkWindow:(id)sender;
- (IBAction)showPollEditWindow:(id)sender;
- (IBAction)showAccountEditWindow:(id)sender;

// Target for Edit -> Edit Last Entry
- (IBAction) editLastEntry:(id)sender;

// Updates the dock menu with current account information
- (void)updateDockMenu;
- (void)buildAccountsMenu: (NSNotification *)note;

// Checks for (and creates if not found) the Application Support directories
- (void)checkForApplicationSupportDirs;

// Opens change notes and ReadMe
- (IBAction)openChangeNotes:(id)sender;
- (IBAction)openReadMe: (id)sender;
- (IBAction)openLicense: (id)sender;
- (IBAction)openXjournalBlog: (id)sender;
- (IBAction)openXjournalHomePage: (id)sender;

// Switching account
- (IBAction)switchAccount: (id)sender;

// Dock Badge
- (void)showDockBadge;
- (void)hideDockBadge;
@end
