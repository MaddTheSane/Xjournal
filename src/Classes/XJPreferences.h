//
//  XJPreferences.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniAppKit/OmniAppKit.h>
#import <LJKit/LJKit.h>
#import <WebKit/WebKit.h>

#define LJ_USERNAME @"livejournal.username"
#define PREFS [OFPreferenceWrapper sharedPreferenceWrapper]

#define NOTE_LOGIN_START @"note.login.start"
#define NOTE_LOGIN_END @"note.login.end"

// Keys for track info dictionary
#define PREFS_MUSIC_ARTIST_PREFIX @"XJMusicArtistPrefix"
#define PREFS_MUSIC_ARTIST_SUFFIX @"XJMusicArtistSuffix"
#define PREFS_MUSIC_TRACK_PREFIX @"XJMusicTrackPrefix"
#define PREFS_MUSIC_TRACK_SUFFIX @"XJMusicTrackSuffix"
#define PREFS_MUSIC_ALBUM_PREFIX @"XJMusicAlbumPrefix"
#define PREFS_MUSIC_ALBUM_SUFFIX @"XJMusicAlbumSuffix"
#define PREFS_MUSIC_SEPARATOR @"XJMusicSeparator"
#define PREFS_MUSIC_ORDERING @"XJMusicOrdering"
#define PREFS_MUSIC_INCLUDE_EMPTY @"XJMusicIncludeEmpty"
#define PREFS_MUSIC_AUTO_DETECT @"XJMusicShouldAutoDetect"
#define LINK_MUSIC_TO_STORE @"XJLinkMusicToStore"
#define ITMS_LINK_PREFIX @"XJiTMSLinkPrefix"
#define ITMS_LINK_SUFFIX @"XJiTMSLinkSuffix"

// Default posting
// When @"0", use posting time.  When @"1" use window creation (these match the NSMatrix tags)
#define PREFS_DEFAULT_POST_DATE @"XJPostingDate"
#define PREFS_OPEN_DRAWER @"XJShouldOpenDrawerInNewWindow"

// Auto login
#define PREFS_AUTO_LOGIN @"XJShouldAutoLogin"

// Prefs for checkfriends
#define CHECKFRIENDS_DO_CHECK @"XJCheckFriendsShouldCheck"
#define CHECKFRIENDS_SHOW_DIALOG @"XJCheckFriendsShouldShowDialog"
#define CHECKFRIENDS_DOCK_ICON @"XJCheckFriendsShouldShowDockIcon"
#define CHECKFRIENDS_OPEN_PAGE @"XJCheckFriendsShouldOpenFriendsPage"
#define CHECKFRIENDS_OPEN_IN_BG @"checkfriends.open.in.background" // ???? USED ????
#define CHECKFRIENDS_GROUP_TYPE @"XJCheckFriendsGroupType"
#define PREFS_CHECKFRIENDS_GROUPS @"checkfriends.groups"
#define CHECKFRIENDS_PLAY_SOUND @"XJCheckFriendsPlaySound"
#define CHECKFRIENDS_SELECTED_SOUND @"XJCheckFriendsAlertSound"

// Window Options
#define SPELLCHECK_BY_DEFAULT @"XJSpellCheckByDefault"
#define ENTRY_WINDOW_SIZE @"XJEntryWindowSize"
#define ENTRY_WINDOW_FONT @"XJEntryWindowFont"
#define SHOW_POST_CONFIRM_DIALOG @"XJShouldShowPostingConfirmationDialog"
#define XJ_UNSAVED_OPTION @"XJUnsavedOption"

// Rendezvous prefs
#define SHARE_RENDEZVOUS @"XJShareAccountOverRendezvous"

// WebKit Prefs
#define XJ_HISTORY_PREF_IDENT @"XJHistory"
#define XJ_OPEN_LINKS_IN_APP @"XJHistoryOpenLinksInApp"
#define XJ_HISTORY_LOAD_IMAGES @"XJHistoryLoadImages"

// App dirs
#define GLOBAL_APPSUPPORT @"/Library/Application Support/Xjournal"
#define LOCAL_APPSUPPORT [@"~/Library/Application Support/Xjournal" stringByExpandingTildeInPath]

// Glossary Dirs
#define GLOBAL_GLOSSARY @"/Library/Application Support/Xjournal/Glossary"
#define LOCAL_GLOSSARY [@"~/Library/Application Support/Xjournal/Glossary" stringByExpandingTildeInPath]

// Notifications
#define XJEntryDownloadStartedNotification @"entry.download.started"
#define XJEntryDownloadEndedNotification @"entry.download.ended"
#define XJManualLoginSuccessNotification @"manual.login.success"
#define XJEntryEntryPostedNotification @"entry.posted"
#define XJGlossaryInsertEvent @"XJGlossaryInsertEvent"
#define XJAccountInfoProvided @"XJAccountInfoProvided"

#define XJFirstAccountInstalled @"XJFirstAccountInstalled"
#define XJAccountAddedNotification @"XJAccountAddedNotification"
#define XJAccountRemovedNotification @"XJAccountRemovedNotification"
#define XJAccountWillRemoveNotification @"XJAccountWillRemoveNotification"
#define XJAccountSwitchedNotification @"XJAccountSwitchedNotification"
#define XJEntryEditedNotification @"XJEntryEditedNotification"

#define XJAddressCardDroppedNotification @"XJAddressCardDroppedNotification"

// Pref keys for whether palettes are open
#define kBookmarkWindowOpen @"XJBookmarkWindowIsOpen"
#define kGlossaryWindowOpen @"XJGlossaryWindowIsOpen"
#define kShortcutWindowOpen @"XJShortcutWindowIsOpen"

// Pref key for default entry security
#define XJ_DEFAULT_SECURITY @"XJDefaultSecurityLevel"

// Suppress login message
#define XJ_SUPPRESS_LOGIN_MSG @"XJSuppressLoginMessage"
#define SHOW_DONATION_WINDOW @"XJShowDonationWindow"

@interface XJPreferences : NSObject {
}

+ (NSArray *)pictureKeywords;
+ (NSImage *)imageForURL: (NSURL *)imageURL; // May return nil if offline

// Entry date setters
+ (int)entryDateDefault; // 0 = window creation time. 1 = posting time
+ (void)setEntryDateDefault: (int)newPref;

// Auto login
+ (BOOL)shouldAutoLogin;
+ (void)setShouldAutoLogin: (BOOL)should;

// Default Security Setting
// These return LJPublicSecurityMode, LJPrivateSecurityMode or LJFriendSecurityMode
+ (int)defaultSecuritySetting;
+ (void)setDefaultSecuritySetting:(int)newSetting;

// What to do with unsaved files
// 0 == ask, 1 == save, 2 == don't save
+ (int)unsavedOption;
+ (void)setUnsavedOption: (int)newOption;

// Checkfriends API
+ (BOOL)shouldCheckFriends;
+ (void)setShouldCheckFriends: (BOOL)should;

+ (BOOL)showFriendsDialog;
+ (void)setShowFriendsDialog: (BOOL)show;

+ (BOOL)showDockIcon;
+ (void)setShowDockIcon: (BOOL)show;

+ (BOOL)openFriendsPage;
+ (void)setOpenFriendsPage: (BOOL)open;

+ (BOOL)openInBackground;
+ (void)setOpenInBackground: (BOOL)openInBG;

+ (BOOL)shouldCheckForGroup: (LJGroup *)grp;
+ (void)setShouldCheck: (BOOL)chk forGroup: (LJGroup *)grp;

// Window preferences
+ (BOOL)spellCheckByDefault;
+ (void)setSpellCheckByDefault: (BOOL)spellCheck;

+ (BOOL)shouldOpenDrawerInNewWindow;
+ (void)setShouldOpenDrawerInNewWindow:(BOOL)should;

+ (BOOL)autoDetectMusic;
+ (void)setAutoDetectMusic: (BOOL)spellCheck;

+ (BOOL)linkMusicToStore;
+ (void)setLinkMusicToStore: (BOOL)shouldLink;

+ (NSString *)iTMSLinkPrefix;
+ (void)setiTMSLinkPrefix: (NSString *)newPrefix;

+ (NSString *)iTMSLinkSuffix;
+ (void)setiTMSLinkSuffix: (NSString *)newSuffix;

+ (BOOL)playCheckFriendsSound;
+ (NSSound *)checkFriendsSound;

+ (void)setEntryWindowSize:(NSSize) newSize;
+ (NSSize)entryWindowSize;

+ (void)setPreferredWindowFont: (NSFont *)font;
+ (NSFont *)preferredWindowFont;

+ (void)setShouldShowPostConfirmationDialog: (BOOL)flag;
+ (BOOL)shouldShowPostConfirmationDialog;

+ (BOOL)shouldShareAccountOverRendezvous;

+ (BOOL)suppressLoginMessage;

// icons
+ (NSString *)communityIconURL;
+ (NSString *)userIconURL;

// HTML Preview Settings
+ (WebPreferences *)webPreferences;

// History Browser Preference
+ (void) setOpenHistoryLinksInXjournal: (BOOL)flag;
+ (BOOL) openHistoryLinksInXjournal;

+ (void)setLoadHistoryImages:(BOOL)flag;
+ (BOOL)loadHistoryImages;

// Donation Window
+ (BOOL)showDonationWindow;
+ (void)setShowDonationWindow: (BOOL)newState;
@end
