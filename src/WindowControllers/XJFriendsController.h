/* XJFriendsController */

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>
#import <WebKit/WebKit.h>

#import "AddressBookDropView.h"

@interface XJFriendsController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSTableView *friendsTable;
    IBOutlet NSTableView *groupTable;
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
    NSInteger viewType; // 0 = all, 1 = only users, 2 = only communities
    
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
@property (getter=getCalendars, readonly, copy) NSDictionary *calendars;
- (IBAction)commitBirthdaySheet: (id)sender;
- (IBAction)cancelBirthdaySheet: (id)sender;

- (IBAction)openSelectedFriendsJournal: (id)sender;
- (IBAction)openSelectedFriendsProfile: (id)sender;

- (IBAction)commitSheet: (id)sender;
- (IBAction)cancelSheet: (id)sender;
- (IBAction)saveDocument: (id)sender;

- (IBAction)launchChatSession: (id)sender;
- (IBAction)addSelectedFriendToAddressBook: (id)sender;
- (IBAction)launchAddressBook: (id)sender;

- (void)refreshWindow: (NSNotification *)note;

- (IBAction)setForegroundColor: (id)sender;
- (IBAction)setBackgroundColor: (id)sender;
- (void)sortFriendTableCacheOnColumn: (NSTableColumn *)column direction: (int)direction;

- (void)updateTabs;

@property (readonly) BOOL canDeleteGroup;
@property (readonly) BOOL canDeleteFriend;
@property (readonly) BOOL canRemoveFriendFromGroup;

@property (readonly, strong) LJFriend *selectedFriend;
@property (readonly, copy) NSArray *selectedFriendArray;
@property (readonly, strong) LJGroup *selectedGroup;

@property (readonly, strong) LJAccount *account;
- (void)setCurrentAccount: (LJAccount *)acct;
- (IBAction)switchAccount: (id)sender;

- (IBAction)setViewType: (id)sender;

- (void)updateFriendTableCache;

@property (readonly) BOOL allFriendsIsSelected;
- (IBAction)refreshFriends: (id)sender;

@end
