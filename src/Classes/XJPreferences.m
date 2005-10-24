//
//  XJPreferences.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJPreferences.h"
#import "NetworkConfig.h"
#import "XJCheckFriendsSessionManager.h"
#import "XJAccountManager.h"

#define ACCOUNT_PATH [@"~/Library/Application Support/Xjournal/Account" stringByExpandingTildeInPath]

static NSMutableDictionary *userPics;
static BOOL usingCached;


@interface XJPreferences (Private)
+ (NSMutableDictionary *)makeMutable: (NSDictionary *)dict;
@end

@implementation XJPreferences
+ (NSArray *)pictureKeywords
{
    return [[[[XJAccountManager defaultManager] defaultAccount] userPicturesDictionary] allKeys];
}

+ (NSImage *)imageForURL: (NSURL *)imageURL
{
    if(imageURL != nil && [NetworkConfig destinationIsReachable: @"www.livejournal.com"]) {
        // If there's no default userpic we get a null image URL
        NSImage *img;
    
        if(!userPics)
            userPics = [[NSMutableDictionary dictionaryWithCapacity: 10] retain];

        img = [userPics objectForKey: imageURL];
        if(img == nil) {
            img = [[NSImage alloc] initWithContentsOfURL: imageURL];
            if(img) {
                [userPics setObject: img forKey: imageURL];
                [img release];
            }
        }

        // Check if image is still nil - server may be broken
        if(img) {
        	// Check that the size is right
        	NSImageRep *rep = [[img representations] objectAtIndex: 0];
        	[img setSize:NSMakeSize([rep pixelsWide], [rep pixelsHigh])];
        	return img;
        }
        else
            return [NSImage imageNamed: @"delete"];
        
    } else {
        // This is what happens when we're somehow offline or there's no default pic
        return [NSImage imageNamed: @"delete"];
    }
}

// Entry date setters
+ (int)entryDateDefault
{
    return [PREFS integerForKey: PREFS_DEFAULT_POST_DATE];
}

+ (void)setEntryDateDefault: (int)newPref
{
    [PREFS setInteger: newPref forKey: PREFS_DEFAULT_POST_DATE];
}

// Auto login
+ (BOOL)shouldAutoLogin
{
    return [[PREFS objectForKey: PREFS_AUTO_LOGIN] intValue];
}

+ (void)setShouldAutoLogin: (BOOL)should
{
    [PREFS setObject: (should ? @"1" : @"0") forKey: PREFS_AUTO_LOGIN];
}

// Default Security Setting
// These return LJPublicSecurityMode, LJPrivateSecurityMode or LJFriendSecurityMode
+ (int)defaultSecuritySetting
{
    return [PREFS integerForKey:XJ_DEFAULT_SECURITY];
}

+ (void)setDefaultSecuritySetting:(int)newSetting
{
    [PREFS setInteger: newSetting forKey: XJ_DEFAULT_SECURITY];
}

// What to do with unsaved files
// 0 == ask, 1 == save, 2 == don't save
+ (int)unsavedOption {
	return [PREFS integerForKey: XJ_UNSAVED_OPTION];
}

+ (void)setUnsavedOption: (int)newOption {
    [PREFS setInteger: newOption forKey: XJ_UNSAVED_OPTION];
}


// Checkfriends API
+ (BOOL)shouldCheckFriends { return [PREFS boolForKey: CHECKFRIENDS_DO_CHECK]; }
+ (void)setShouldCheckFriends: (BOOL)should {
    [PREFS setBool: should forKey: CHECKFRIENDS_DO_CHECK];
    if(should) {
        [[XJCheckFriendsSessionManager sharedManager] startCheckingFriends];
    }
    else {
        [[XJCheckFriendsSessionManager sharedManager] stopCheckingFriends];
    }
        
}

+ (BOOL)shouldCheckForGroup: (LJGroup *)grp
{
    NSMutableDictionary *dict = [self makeMutable: [PREFS objectForKey: PREFS_CHECKFRIENDS_GROUPS]];
    id val = [dict objectForKey: [grp name]];

    [PREFS setObject: dict forKey: PREFS_CHECKFRIENDS_GROUPS];
    
    return ((val != nil) && [val boolValue]);
}

+ (void)setShouldCheck: (BOOL)chk forGroup: (LJGroup *)grp
{
    // this assumes you can't have 2 groups with the same name (valid?)
    NSMutableDictionary *dict = [self makeMutable: [PREFS objectForKey: PREFS_CHECKFRIENDS_GROUPS]];
    // Prefs stores a dict of booleans keyed against group names, hence, if you have two groups with the same name
    // --> key clash
    
    [dict setObject: [NSNumber numberWithBool: chk] forKey: [grp name]];
    [[XJCheckFriendsSessionManager sharedManager] setChecking: chk forGroup: grp];
    [PREFS setObject: dict forKey: PREFS_CHECKFRIENDS_GROUPS];
}

+ (BOOL)showFriendsDialog { return [PREFS boolForKey: CHECKFRIENDS_SHOW_DIALOG]; }
+ (void)setShowFriendsDialog: (BOOL)show { [PREFS setBool: show forKey: CHECKFRIENDS_SHOW_DIALOG]; }

+ (BOOL)showDockIcon  { return [PREFS boolForKey: CHECKFRIENDS_DOCK_ICON]; }
+ (void)setShowDockIcon: (BOOL)show { [PREFS setBool: show forKey: CHECKFRIENDS_DOCK_ICON]; }

+ (BOOL)openFriendsPage { return [PREFS boolForKey: CHECKFRIENDS_OPEN_PAGE]; }
+ (void)setOpenFriendsPage: (BOOL)open { [PREFS setBool: open forKey: CHECKFRIENDS_OPEN_PAGE]; }

+ (BOOL)openInBackground { return [PREFS boolForKey: CHECKFRIENDS_OPEN_IN_BG]; }
+ (void)setOpenInBackground: (BOOL)openInBG { [PREFS setBool: openInBG forKey: CHECKFRIENDS_OPEN_IN_BG]; }

    // Window preferences
+ (BOOL)spellCheckByDefault { return [PREFS boolForKey: SPELLCHECK_BY_DEFAULT]; }
+ (void)setSpellCheckByDefault: (BOOL)spellCheck { [PREFS setBool: spellCheck forKey: SPELLCHECK_BY_DEFAULT]; }

+ (BOOL)shouldOpenDrawerInNewWindow { return [PREFS boolForKey: PREFS_OPEN_DRAWER]; }
+ (void)setShouldOpenDrawerInNewWindow:(BOOL)should { [PREFS setBool: should forKey: PREFS_OPEN_DRAWER]; }

+ (BOOL)autoDetectMusic { return [PREFS boolForKey: PREFS_MUSIC_AUTO_DETECT]; }
+ (void)setAutoDetectMusic: (BOOL)autoDetect { [PREFS setBool: autoDetect forKey: PREFS_MUSIC_AUTO_DETECT]; }

+ (BOOL)linkMusicToStore { return [PREFS boolForKey: LINK_MUSIC_TO_STORE]; }
+ (void)setLinkMusicToStore: (BOOL)shouldLink { [PREFS setBool: shouldLink forKey: LINK_MUSIC_TO_STORE]; }

+ (NSString *)iTMSLinkPrefix { return [PREFS stringForKey: ITMS_LINK_PREFIX]; }
+ (void)setiTMSLinkPrefix: (NSString *)newPrefix { [PREFS setObject: newPrefix forKey: ITMS_LINK_PREFIX]; }

+ (NSString *)iTMSLinkSuffix { return [PREFS stringForKey: ITMS_LINK_SUFFIX]; }
+ (void)setiTMSLinkSuffix: (NSString *)newSuffix { [PREFS setObject: newSuffix forKey: ITMS_LINK_SUFFIX]; }

+ (BOOL)playCheckFriendsSound { return [PREFS boolForKey: CHECKFRIENDS_PLAY_SOUND]; }
+ (NSSound *)checkFriendsSound
{
    NSString *path = [PREFS stringForKey: CHECKFRIENDS_SELECTED_SOUND];
    NSSound *sound = [[NSSound alloc] initWithContentsOfFile: path byReference: NO];
    return [sound autorelease];
}

+ (BOOL)usingCachedAccount { return usingCached; }

+ (void)setEntryWindowSize:(NSSize) newSize { [PREFS setObject: NSStringFromSize(newSize) forKey: ENTRY_WINDOW_SIZE]; }
+ (NSSize)entryWindowSize
{
    NSString *sizeString = [PREFS objectForKey: ENTRY_WINDOW_SIZE];
    if(sizeString == nil)
        return NSMakeSize(500, 510);
    else
        return NSSizeFromString(sizeString);
}

+ (void)setPreferredWindowFont: (NSFont *)font {
    NSMutableData *data;
    NSKeyedArchiver *archiver;

    data = [NSMutableData data];
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    // Customize archiver here
    [archiver encodeObject:font forKey:ENTRY_WINDOW_FONT];
    [archiver finishEncoding];
    [archiver release];

    [PREFS setObject: data forKey: ENTRY_WINDOW_FONT];

}
+ (NSFont *)preferredWindowFont
{
    NSData *data = [PREFS objectForKey: ENTRY_WINDOW_FONT];
    if(data != nil) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSFont *preferredFont = [[unarchiver decodeObjectForKey:ENTRY_WINDOW_FONT] retain];
        [unarchiver finishDecoding];
        [unarchiver release];

        return [preferredFont autorelease];
    }
    return nil;
}

+ (void)setShouldShowPostConfirmationDialog: (BOOL)flag
{
    [PREFS setBool: flag forKey: SHOW_POST_CONFIRM_DIALOG];
}

+ (BOOL)shouldShowPostConfirmationDialog { return [PREFS boolForKey: SHOW_POST_CONFIRM_DIALOG]; }

+ (BOOL)shouldShareAccountOverRendezvous { return [PREFS boolForKey: SHARE_RENDEZVOUS]; }

// ----------------------------------------------------------------------------------------
// icons
// ----------------------------------------------------------------------------------------
+ (NSString *)userIconURL
{
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"userinfo" ofType:@"gif"]];
    return [url absoluteString];
}

+ (NSString *)communityIconURL
{
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"communitysmall" ofType:@"gif"]];
    return [url absoluteString];
}

//
// HTML Font
//
// HTML Preview Settings
+ (WebPreferences *)webPreferences
{
    WebPreferences *prefs = [WebPreferences standardPreferences];
    [prefs setAutosaves: YES];
    return prefs;
}

// History Browser Preference
+ (void) setOpenHistoryLinksInXjournal: (BOOL)flag
{
    [PREFS setBool: flag forKey: XJ_OPEN_LINKS_IN_APP];
}

+ (BOOL) openHistoryLinksInXjournal { return [PREFS boolForKey: XJ_OPEN_LINKS_IN_APP]; }

+ (void)setLoadHistoryImages:(BOOL)flag
{
    [PREFS setBool: flag forKey: XJ_HISTORY_LOAD_IMAGES];
}
+ (BOOL)loadHistoryImages{ return [PREFS boolForKey: XJ_HISTORY_LOAD_IMAGES]; }

+ (BOOL)suppressLoginMessage {
	return [PREFS boolForKey: XJ_SUPPRESS_LOGIN_MSG];
}

// Donation Window
+ (BOOL)showDonationWindow {
	return [PREFS boolForKey: SHOW_DONATION_WINDOW];
}

+ (void)setShowDonationWindow: (BOOL)newState {
	[PREFS setBool: newState forKey: SHOW_DONATION_WINDOW];
}
@end

@implementation XJPreferences (Private)

+ (NSMutableDictionary *)makeMutable: (NSDictionary *)dict
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary addEntriesFromDictionary: dict];
    return dictionary;
}
@end