/* XJFriendsController */

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>
#import <OmniAppKit/OmniAppKit.h>
#import <WebKit/WebKit.h>

#import "AddressBookDropView.h"

@interface XJFriendsController : NSWindowController
{
    IBOutlet id friendsTable;
    IBOutlet id groupTable;
    IBOutlet NSSplitView *splitView;
    
    IBOutlet id groupSheet, friendSheet, groupField, friendField, currentSheet;

    IBOutlet NSTextField *userNameField, *fullName, *dateOfBirth;
    IBOutlet NSColorWell *fgWell, *bgWell;

    IBOutlet AddressBookDropView *addressBookImageWell;
	IBOutlet NSTextField *addressBookName;
	IBOutlet NSButton *addressBookClearButton;

    // Table view sorting
    int sortDirection;
    NSTableColumn *sortedColumn;
    NSMutableArray *friendTableCache;
    NSMutableDictionary *sortSettings;
    
    // Cache the toolbar items
    NSMutableDictionary *toolbarItemCache;

    // Toolbar popups
    IBOutlet NSView *accountToolbarView, *showTypeToolbarView;
    IBOutlet NSPopUpButton *accountToolbarPopup, *showTypePopUp;
    
    // THe view type
    int viewType; // 0 = all, 1 = only users, 2 = only communities
    
    // The account we're working with
    LJAccount *account;
    
    // Images
    NSImage *userinfo;
    NSImage *folder;
    NSImage *community;
    NSImage *birthday;
    
    // WebKit
    IBOutlet WebView *recentEntriesView, *userInfoView;
    IBOutlet NSTabView *tabs;
    IBOutlet NSProgressIndicator *recentSpinner, *userInfoSpinner;
    
    // Birthdays
    IBOutlet NSButton *iCalButton;
    IBOutlet NSWindow *calChooserSheet;
    IBOutlet NSPopUpButton *calPopup;
    
    NSTimer *colorTimer;
}
- (IBAction)addFriend:(id)sender;
- (IBAction)addGroup:(id)sender;
- (IBAction)deleteSelectedFriend: (id)sender;
- (IBAction)deleteSelectedGroup: (id)sender;
- (IBAction)removeSelectedFriendFromGroup: (id)sender;
- (IBAction)removeAddressCard: (id)sender;

- (IBAction)addBirthdayToiCal: (id)sender;
- (NSDictionary *)getCalendars;
- (IBAction)commitBirthdaySheet: (id)sender;
- (IBAction)cancelBirthdaySheet: (id)sender;

- (IBAction)openSelectedFriendsJournal: (id)sender;
- (IBAction)openSelectedFriendsProfile: (id)sender;

- (IBAction)commitSheet: (id)sender;
- (IBAction)cancelSheet: (id)sender;
- (IBAction)saveDocument: (id)sender;

- (IBAction)launchAddressBook: (id)sender;

- (void)refreshWindow: (NSNotification *)note;

- (IBAction)setForegroundColor: (id)sender;
- (IBAction)setBackgroundColor: (id)sender;
- (void)sortFriendTableCacheOnColumn: (NSTableColumn *)column direction: (int)direction;

- (void)updateTabs;

- (BOOL)canDeleteGroup;
- (BOOL)canDeleteFriend;
- (BOOL)canRemoveFriendFromGroup;

- (LJFriend *) selectedFriend;
- (NSArray *)selectedFriendArray;
- (LJGroup *)selectedGroup;

- (LJAccount *)account;
- (void)setCurrentAccount: (LJAccount *)acct;
- (IBAction)switchAccount: (id)sender;

- (IBAction)setViewType: (id)sender;

- (void)updateFriendTableCache;

- (BOOL)allFriendsIsSelected;
- (IBAction)refreshFriends: (id)sender;
@end
