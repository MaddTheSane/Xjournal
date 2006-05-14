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

#define NOTE_LOGIN_START @"note.login.start"
#define NOTE_LOGIN_END @"note.login.end"

// Prefs for checkfriends
#define CHECKFRIENDS_GROUP_TYPE @"XJCheckFriendsGroupType"
#define PREFS_CHECKFRIENDS_GROUPS @"checkfriends.groups"
#define CHECKFRIENDS_PLAY_SOUND @"XJCheckFriendsPlaySound"
#define CHECKFRIENDS_SELECTED_SOUND @"XJCheckFriendsAlertSound"

// Window Options
#define ENTRY_WINDOW_FONT @"XJEntryWindowFontName"

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

+ (NSFont *)preferredWindowFont;

// icons
+ (NSString *)communityIconURL;
+ (NSString *)userIconURL;
@end
