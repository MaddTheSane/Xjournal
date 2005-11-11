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
#import <OmniAppKit/OmniAppKit.h>

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
#define ITMS_LINK_PREFIX @"XJiTMSLinkPrefix"
#define ITMS_LINK_SUFFIX @"XJiTMSLinkSuffix"

// Prefs for checkfriends
#define CHECKFRIENDS_GROUP_TYPE @"XJCheckFriendsGroupType"
#define PREFS_CHECKFRIENDS_GROUPS @"checkfriends.groups"
#define CHECKFRIENDS_PLAY_SOUND @"XJCheckFriendsPlaySound"
#define CHECKFRIENDS_SELECTED_SOUND @"XJCheckFriendsAlertSound"

// Window Options
#define ENTRY_WINDOW_FONT @"XJEntryWindowFont"

// WebKit Prefs
#define XJ_HISTORY_PREF_IDENT @"XJHistory"

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

@interface XJPreferences : NSObject {}

+ (NSArray *)pictureKeywords;
+ (NSImage *)imageForURL: (NSURL *)imageURL; // May return nil if offline

// Checkfriends API
+ (BOOL)shouldCheckForGroup: (LJGroup *)grp;
+ (void)setShouldCheck: (BOOL)chk forGroup: (LJGroup *)grp;

+ (NSString *)iTMSLinkPrefix;
+ (void)setiTMSLinkPrefix: (NSString *)newPrefix;

+ (NSString *)iTMSLinkSuffix;
+ (void)setiTMSLinkSuffix: (NSString *)newSuffix;

+ (BOOL)playCheckFriendsSound;
+ (NSSound *)checkFriendsSound;

+ (NSFont *)preferredWindowFont;

// icons
+ (NSString *)communityIconURL;
+ (NSString *)userIconURL;
@end
