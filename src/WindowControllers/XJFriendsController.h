/* XJFriendsController */

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>
#import <WebKit/WebKit.h>
#import <AddressBook/ABPeoplePickerView.h>

#import "AddressBookDropView.h"
#import "FriendsFilterArrayController.h"
#import "MetaItemArrayController.h"

@class XJAccountManager;

@interface XJFriendsController : NSWindowController
{
	// Models
	XJAccountManager *accountManager;
    
	// The account we're working with
    LJAccount *account;
	
	// What we show:
	BOOL showUsers;
	BOOL showCommunities;
	
	// Array Controllers
	IBOutlet FriendsFilterArrayController *friendsForSelectedGroupController;
	IBOutlet MetaItemArrayController *groupController;
		
    IBOutlet id friendsTable;
    IBOutlet id groupTable;
    
    IBOutlet id groupSheet, friendSheet, groupField, friendField, currentSheet;

	IBOutlet NSButton *addressBookClearButton;

    // Cache the toolbar items
    NSMutableDictionary *toolbarItemCache;
    
    // Birthdays
    IBOutlet NSButton *iCalButton;
    IBOutlet NSWindow *calChooserSheet;
    IBOutlet NSPopUpButton *calPopup;
	
	// Address Book Sheet
	IBOutlet NSWindow *abSheet;
	IBOutlet ABPeoplePickerView *abPicker;
}

// Model accessors
- (XJAccountManager *)accountManager;
- (void)setAccountManager:(XJAccountManager *)anAccountManager;

- (BOOL)showUsers;
- (void)setShowUsers:(BOOL)flag;

- (BOOL)showCommunities;
- (void)setShowCommunities:(BOOL)flag;

- (IBAction)addFriend:(id)sender;
- (IBAction)addGroup:(id)sender;
- (IBAction)deleteFriendButtonAction: (id)sender;
- (IBAction)deleteSelectedFriend: (id)sender;
- (IBAction)deleteSelectedGroup: (id)sender;
- (IBAction)removeSelectedFriendFromGroup: (id)sender;
- (IBAction)removeAddressCard: (id)sender;

- (IBAction)addBirthdayToiCal: (id)sender;
- (NSDictionary *)getCalendars;
- (IBAction)commitBirthdaySheet: (id)sender;
- (IBAction)cancelBirthdaySheet: (id)sender;

- (IBAction)runABSelectSheet:(id)sender;
- (IBAction)commitABSelectSheet:(id)sender;
- (IBAction)cancelABSelectSheet:(id)sender;

- (IBAction)openSelectedFriendsJournal: (id)sender;
- (IBAction)openSelectedFriendsProfile: (id)sender;

- (IBAction)commitSheet: (id)sender;
- (IBAction)cancelSheet: (id)sender;
- (IBAction)saveDocument: (id)sender;

- (IBAction)launchAddressBook: (id)sender;

- (void)updateTabs;

- (BOOL)canDeleteGroup;
- (BOOL)canDeleteFriend;
- (BOOL)canRemoveFriendFromGroup;

- (LJAccount *)account;
- (void)setAccount: (LJAccount *)acct;

@end
