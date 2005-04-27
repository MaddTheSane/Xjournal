//
//  XJPreferences.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LJKit/LJKit.h>
#import <WebKit/WebKit.h>

#define LJ_USERNAME @"livejournal.username"
#define PREFS [NSUserDefaults standardUserDefaults]

// ===============================
// Window Preferences
// ===============================
// BOOL :: Preference Key for defining the way entries are dated
// When NO, use posting time.  When YES use window creation (these match the NSMatrix tags)
FOUNDATION_EXPORT NSString * const XJEntryDateIsWindowCreationTimePreference;

// BOOL :: Preference for whether a new window should open the drawer
FOUNDATION_EXPORT NSString * const XJShouldOpenDrawerInNewWindowPreference;

// BOOL :: Should we turn on spell checking?
FOUNDATION_EXPORT NSString * const XJShouldSpellCheckInNewWindowPreference;

// NSString :: What's the user's preferred window size?
// The value of this preference should be translated back and forth with
// NSStringFromSize() and NSSizeFromString()
FOUNDATION_EXPORT NSString * const XJEntryWindowSizePreference;

// Preference key for the user's preferred composition font
// There's a convenience method in this class through which this
// preference should be set.
FOUNDATION_EXPORT NSString * const XJEntryWindowFontPreference;

// BOOL :: Should we confirm posting with a dialog?
FOUNDATION_EXPORT NSString * const XJShouldShowPostingConfirmationDialogPreference;

// BOOL :: Should we confirm posting with Growl?
FOUNDATION_EXPORT NSString * const XJShouldShowPostingConfirmationGrowlPreference;

// int :: What do we do when posting a saved entry with saved changes?
// Should be one of the values in the enumeration below
FOUNDATION_EXPORT NSString * const XJShouldAskForUnsavedEntriesPreference;
enum {
	kXJShouldAskForUnsavedEntries = 0,
	kKJShouldSaveUnsavedEntries,
	kXJShouldDiscardUnsavedEntries
};

// int :: Preference for default post format
FOUNDATION_EXPORT NSString * const XJEntryDefaultPostFormatPreference;
enum {
	kXJLiveJournalFormat = 0,
	kXJMarkdownFormat,
	kXJPreformattedFormat
};

// int :: Preference for default security level
FOUNDATION_EXPORT NSString * const XJEntryDefaultSecurityLevelPreference;
enum {
	kXJEntryPublicSecurity = 0,
	kXJEntryPrivateSecuirity,
	kXJEntryFriendsSecurity
};

// ===============================
// Check Friends
// ===============================
// BOOL :: Preference for whether checkfriends notifications should play a sound
FOUNDATION_EXPORT NSString * const XJCheckFriendsShouldPlaySoundPreference;

// NSString :: Preference for the sound checkfriends should play
FOUNDATION_EXPORT NSString * const XJCheckFriendsSelectedAlertSoundPreference;

// BOOL :: Should Checkfriends show the dock icon?
FOUNDATION_EXPORT NSString * const XJCheckFriendsShouldShowDockIconPreference;

// BOOL :: Should we show a checkfriends dialog
FOUNDATION_EXPORT NSString * const XJCheckFriendsShouldShowDialogPreference;

// BOOL :: Should we use Growl for the notification
FOUNDATION_EXPORT NSString * const XJCheckFriendsShouldUseGrowlPreference;

// ===============================
// Palettes
// ===============================
// All BOOL
FOUNDATION_EXPORT NSString * const XJBookmarkWindowIsOpenPreference;
FOUNDATION_EXPORT NSString * const XJGlossaryWindowIsOpenPreference;
FOUNDATION_EXPORT NSString * const XJShortcutWindowIsOpenPreference;

// ===============================
// RSS
// ===============================
// All NSString
FOUNDATION_EXPORT NSString * const XJRSSSubjectFormatStringPreference;
FOUNDATION_EXPORT NSString * const XJRSSFormatStringPreference;

// WebKit Prefs
#define XJ_HISTORY_PREF_IDENT @"XJHistory"

// App dirs
#define GLOBAL_APPSUPPORT @"/Library/Application Support/Xjournal"
#define LOCAL_APPSUPPORT [@"~/Library/Application Support/Xjournal" stringByExpandingTildeInPath]

// Glossary Dirs
#define GLOBAL_GLOSSARY @"/Library/Application Support/Xjournal/Glossary"
#define LOCAL_GLOSSARY [@"~/Library/Application Support/Xjournal/Glossary" stringByExpandingTildeInPath]

// Notifications
#define XJGlossaryInsertEvent @"XJGlossaryInsertEvent"
#define XJAccountRemovedNotification @"XJAccountRemovedNotification"
#define XJAddressCardDroppedNotification @"XJAddressCardDroppedNotification"

// Pref key for default entry security
#define XJ_DEFAULT_SECURITY @"XJDefaultSecurityLevel"

// Suppress login message
#define XJ_SUPPRESS_LOGIN_MSG @"XJSuppressLoginMessage"
#define SHOW_DONATION_WINDOW @"XJShowDonationWindow"

@interface XJPreferences : NSObject {
}

+(void)installPreferences;

+ (NSArray *)pictureKeywords;
+ (NSImage *)imageForURL: (NSURL *)imageURL; // May return nil if offline

// Default Security Setting
// These return LJPublicSecurityMode, LJPrivateSecurityMode or LJFriendSecurityMode
+ (int)defaultSecuritySetting;
+ (void)setDefaultSecuritySetting:(int)newSetting;

+ (void)setPreferredWindowFont: (NSFont *)font;
+ (NSFont *)preferredWindowFont;

+ (BOOL)suppressLoginMessage;

// icons
+ (NSString *)communityIconURL;
+ (NSString *)userIconURL;

// Donation Window
+ (BOOL)showDonationWindow;
+ (void)setShowDonationWindow: (BOOL)newState;
@end
