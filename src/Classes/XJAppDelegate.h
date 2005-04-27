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
#import "XJSafariBookmarkParser.h"
#import "XJBookmarksWindowController.h"
#import "XJPollEditorController.h"
#import "XJPreferencesController.h"
#import "XJPollEditorController.h"
#import "XJFAWizardController.h"

@class XJDockStatusItem;
@class XJHistorySyncManager;
@class XJScriptWindowController;
@class XJEditToolsController;

@interface XJAppDelegate : NSObject {
    /*
     These controller objects control subsidiary windows in the app.
     Because the windows are singletons, their controllers are too.
     */
    XJHistoryWindowController *histController;
    XJFriendsController *friendController;
    XJGlossaryWindowController *glossaryController;
    XJBookmarksWindowController *bookmarkController;
    XJPollEditorController *pollController;
	//XJPollController *pollController;
	XJPreferencesController *prefsController;
	XJScriptWindowController *scriptsController;
	XJFAWizardController *firstAccountController;
	XJEditToolsController *toolsController;
	
    // The dock menu
    NSMenu *dynDockMenu;
    
    // Omni dock badge
    XJDockStatusItem *dockItem;
    
    // Flag to tell us if the friends updated dialog is showing
    BOOL friendsDialogIsShowing;

    // cmd-delete menu outlets
    IBOutlet NSMenuItem *deleteFriend, *deleteFromGroup;
	
	XJHistorySyncManager *syncManager;
}

// Target for AppMenu -> Check for updates
- (IBAction)checkForUpdate:(id)sender;

// Targets for Window menu items
- (IBAction)showPrefsWindow:(id)sender;
- (IBAction)showHistoryWindow:(id)sender;
- (IBAction)showFriendsWindow:(id)sender;
- (IBAction)showGlossaryWindow:(id)sender;
- (IBAction)showBookmarkWindow:(id)sender;
- (IBAction)showPollEditWindow:(id)sender;
- (IBAction)showScriptsPalette: (id)sender;
- (IBAction)showToolsPalette:(id)sender;

// Target for Edit -> Edit Last Entry
- (IBAction) editLastEntry:(id)sender;

// Updates the dock menu with current account information
- (void)updateDockMenu;

// Checks for (and creates if not found) the Application Support directories
- (void)checkForApplicationSupportDirs;

// Opens change notes and ReadMe
- (IBAction)openChangeNotes:(id)sender;
- (IBAction)openReadMe: (id)sender;
- (IBAction)openXjournalBlog: (id)sender;
- (IBAction)openXjournalHomePage: (id)sender;
- (IBAction)openDonate: (id)sender;
- (IBAction)openMarkdownReference: (id)sender;
@end