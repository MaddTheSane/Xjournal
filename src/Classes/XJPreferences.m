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

// ===============================
// Window Preferences
// ===============================
NSString * const XJEntryDateIsWindowCreationTimePreference = @"EntryDateIsWindowCreationTime";
NSString * const XJShouldOpenDrawerInNewWindowPreference = @"ShouldOpenDrawerInNewWindow";
NSString * const XJShouldSpellCheckInNewWindowPreference = @"ShouldSpellCheckInNewWindow";
NSString * const XJEntryWindowSizePreference = @"EntryWindowSize";
NSString * const XJEntryWindowFontPreference = @"EntryWindowFont";
NSString * const XJShouldShowPostingConfirmationDialogPreference = @"ShouldShowPostingConfirmationDialog";
NSString * const XJShouldShowPostingConfirmationGrowlPreference = @"ShouldShowPostingConfirmationGrowl";
NSString * const XJShouldAskForUnsavedEntriesPreference = @"ShouldAskForUnsavedEntries";
NSString * const XJEntryDefaultPostFormatPreference = @"EntryDefaultPostFormat";
NSString * const XJEntryDefaultSecurityLevelPreference = @"EntryDefaultSecurityLevel";

// ===============================
// Check Friends
// ===============================
NSString * const XJCheckFriendsShouldPlaySoundPreference = @"CheckFriendsShouldPlaySound";
NSString * const XJCheckFriendsSelectedAlertSoundPreference = @"CheckFriendsSelectedAlertSound";
NSString * const XJCheckFriendsShouldShowDockIconPreference = @"CheckFriendsShouldShowDockIcon";
NSString * const XJCheckFriendsShouldShowDialogPreference = @"CheckFriendsShouldShowDialog";
NSString * const XJCheckFriendsShouldUseGrowlPreference = @"CheckFriendsShouldUseGrowl";

// ===============================
// Palettes
// ===============================
NSString * const XJBookmarkWindowIsOpenPreference = @"BookmarkWindowIsOpen";
NSString * const XJGlossaryWindowIsOpenPreference = @"GlossaryWindowIsOpen";
NSString * const XJShortcutWindowIsOpenPreference = @"ShortcutWindowIsOpen";

// ===============================
// RSS
// ===============================
NSString * const XJRSSSubjectFormatStringPreference = @"RSSSubjectFormatString";
NSString * const XJRSSFormatStringPreference = @"RSSFormatString";

#define ACCOUNT_PATH [@"~/Library/Application Support/Xjournal/Account" stringByExpandingTildeInPath]

static NSMutableDictionary *userPics;

@interface XJPreferences (Private)
+ (NSMutableDictionary *)makeMutable: (NSDictionary *)dict;
@end

@implementation XJPreferences
+(void)installPreferences {
	NSLog(@"Initializing preferences");
	// Set up initial values
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
// --------------------------
// General Prefs
// --------------------------
// Spell Check?  YES
	[dictionary setObject: [NSNumber numberWithBool: YES] forKey: XJShouldSpellCheckInNewWindowPreference];
	
	// Detect Music? YES
	// This should merge into the music prefs
	[dictionary setObject: [NSNumber numberWithBool: YES] forKey: @"XJMusicShouldAutoDetect"];
	
// Open Drawer? YES
	[dictionary setObject: [NSNumber numberWithBool: YES] forKey: XJShouldOpenDrawerInNewWindowPreference];
	
	// Entry dating?  WHEN POSTED (0)
	[dictionary setObject: [NSNumber numberWithInt: 0] forKey: XJEntryDateIsWindowCreationTimePreference];
	
	// Default Security Level - PUBLIC (0)
	[dictionary setObject: [NSNumber numberWithInt: 0] forKey: @"XJDefaultSecurityLevel"];
	
	// Default Format - LJ (0)
	[dictionary setObject: [NSNumber numberWithInt: kXJLiveJournalFormat] forKey: XJEntryDefaultPostFormatPreference];
	
	// Posting an entry with unsaved changes - ASK (0)
	[dictionary setObject: [NSNumber numberWithInt: kXJShouldAskForUnsavedEntries] forKey: XJShouldAskForUnsavedEntriesPreference];	
	
	// A default size
	[dictionary setObject: NSStringFromSize(NSMakeSize(507,500)) forKey: XJEntryWindowSizePreference];
	
	// --------------------------
	// Notification
	// --------------------------
	// Should we show a dialog? YES
	[dictionary setObject: [NSNumber numberWithBool: YES] forKey: XJCheckFriendsShouldShowDialogPreference];
	// Should we use Growl? NO
	[dictionary setObject: [NSNumber numberWithBool: NO] forKey: XJCheckFriendsShouldUseGrowlPreference];
	// Show the dock icon?  YES
	[dictionary setObject: [NSNumber numberWithBool: YES] forKey: XJCheckFriendsShouldShowDockIconPreference];
	// Open the friends page when dock icon clicked?  NO
	[dictionary setObject: [NSNumber numberWithBool: NO] forKey: @"XJCheckFriendsShouldOpenFriendsPage"];
	// Play a sound? NO
	[dictionary setObject: [NSNumber numberWithBool: NO] forKey: XJCheckFriendsShouldPlaySoundPreference];
	// What's the default sound?
	// Leave nil?
	
	// Show dialog on posting?  YES
	[dictionary setObject: [NSNumber numberWithBool: YES] forKey: XJShouldShowPostingConfirmationDialogPreference];
	
	// Use Growl? NO
	[dictionary setObject: [NSNumber numberWithBool: NO] forKey: XJShouldShowPostingConfirmationGrowlPreference];
	
// --------------------------
// Music
// --------------------------
	[dictionary setObject: @"<$name/> - <$artist/> (from: <i><$album/></i>, rated <$rating/>)" forKey: @"MusicFormatString"];
	[dictionary setObject: @"No Music" forKey:@"NoMusicString"];
	[dictionary setObject: [NSNumber numberWithBool: YES] forKey: @"DetectiTunesChanges"];
	[dictionary setObject: [NSNumber numberWithBool: NO] forKey: @"LinkMusicToiTMS"];
	
	// --------------------------
	// RSS
	// --------------------------
	[dictionary setObject: @"<$title/>" forKey: XJRSSSubjectFormatStringPreference];
	[dictionary setObject: @"<strong><$title/>:</strong>\n<blockquote><$body/></blockquote>\n\n<a href=\"<$permalink/>\">Link</a>" forKey: XJRSSFormatStringPreference];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];	
}

+ (void)log {
	NSLog(@"XJPreferences");
}

+ (NSArray *)pictureKeywords
{
	[self log];
    return [[[[XJAccountManager defaultManager] defaultAccount] userPicturesDictionary] allKeys];
}

+ (NSImage *)imageForURL: (NSURL *)imageURL
{
	[self log];
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


// Default Security Setting
// These return LJPublicSecurityMode, LJPrivateSecurityMode or LJFriendSecurityMode
+ (int)defaultSecuritySetting
{
	[self log];
    return [PREFS integerForKey:XJ_DEFAULT_SECURITY];
}

+ (void)setDefaultSecuritySetting:(int)newSetting
{
	[self log];
    [PREFS setInteger: newSetting forKey: XJ_DEFAULT_SECURITY];
}

+ (void)setPreferredWindowFont: (NSFont *)font {
    NSMutableData *data;
    NSKeyedArchiver *archiver;

    data = [NSMutableData data];
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    // Customize archiver here
    [archiver encodeObject:font forKey: XJEntryWindowFontPreference];
    [archiver finishEncoding];
    [archiver release];

    [PREFS setObject: data forKey: XJEntryWindowFontPreference];

}
+ (NSFont *)preferredWindowFont
{
    NSData *data = [PREFS objectForKey: XJEntryWindowFontPreference];
    if(data != nil) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSFont *preferredFont = [[unarchiver decodeObjectForKey: XJEntryWindowFontPreference] retain];
        [unarchiver finishDecoding];
        [unarchiver release];

        return [preferredFont autorelease];
    }
    return nil;
}

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