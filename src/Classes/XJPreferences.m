//
//  XJPreferences.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XJPreferences.h"
#import "XJCheckFriendsSessionManager.h"
#import "XJAccountManager.h"

#import "Xjournal-Swift.h"

#define ACCOUNT_PATH [XJGetGlobalAppSupportDir() stringByAppendingPathComponent: @"Account"]

NSString *XJGetGlobalAppSupportDir()
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *globalAppURL = [fm URLForDirectory: NSApplicationSupportDirectory inDomain: NSLocalDomainMask appropriateForURL: nil create: NO error: nil];
    NSString *globalAppPath = [globalAppURL path];
    
    return [globalAppPath stringByAppendingPathComponent: @"Xjournal"];
}

NSString *XJGetLocalAppSupportDir()
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *globalAppURL = [fm URLForDirectory: NSApplicationSupportDirectory inDomain: NSUserDomainMask appropriateForURL: nil create: YES error: nil];
    NSString *globalAppPath = [globalAppURL path];
    
    return [globalAppPath stringByAppendingPathComponent: @"Xjournal"];
}

#pragma mark -

NSString *XJGetGlobalGlossary()
{
    return [XJGetGlobalAppSupportDir() stringByAppendingPathComponent: @"Glossary"];
}

NSString *XJGetLocallGlossary()
{
    return [XJGetLocalAppSupportDir() stringByAppendingPathComponent: @"Glossary"];
}

static NSMutableDictionary *userPics;

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
            userPics = [[NSMutableDictionary alloc] initWithCapacity: 10];

        img = userPics[imageURL];
        if(img == nil) {
            img = [[NSImage alloc] initWithContentsOfURL: imageURL];
            if(img) {
                userPics[imageURL] = img;
            }
        }

        // Check if image is still nil - server may be broken
        if(img) {
        	// Check that the size is right
        	NSImageRep *rep = [img representations][0];
        	[img setSize:NSMakeSize([rep pixelsWide], [rep pixelsHigh])];
        	return img;
        }
        else
            return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarDeleteIcon)];
        
    } else {
        // This is what happens when we're somehow offline or there's no default pic
        return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarDeleteIcon)];
    }
}

+ (BOOL)shouldCheckForGroup: (LJGroup *)grp
{
    NSMutableDictionary *dict = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: PREFS_CHECKFRIENDS_GROUPS] mutableCopy];
    id val = dict[[grp name]];

    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: dict forKey: PREFS_CHECKFRIENDS_GROUPS];
    
    return ((val != nil) && [val boolValue]);
}

+ (void)setShouldCheck: (BOOL)chk forGroup: (LJGroup *)grp
{
    // this assumes you can't have 2 groups with the same name (valid?)
    NSMutableDictionary *dict = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: PREFS_CHECKFRIENDS_GROUPS] mutableCopy];
    // Prefs stores a dict of booleans keyed against group names, hence, if you have two groups with the same name
    // --> key clash
    
    dict[[grp name]] = @(chk);
    [[XJCheckFriendsSessionManager sharedManager] setChecking: chk forGroup: grp];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: dict forKey: PREFS_CHECKFRIENDS_GROUPS];
}

+ (NSFont *)preferredWindowFont
{
	id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *fontName = [values valueForKey: @"XJEntryWindowFontName"];
	CGFloat fontSize = [[values valueForKey: @"XJEntryWindowFontSize"] doubleValue];
	
    NSFont *font = [NSFont fontWithName: fontName size: fontSize];
	
    return font ?: [NSFont systemFontOfSize: fontSize];
}

// ----------------------------------------------------------------------------------------
// icons
// ----------------------------------------------------------------------------------------
+ (NSString *)userIconURL {
    return [[[NSBundle mainBundle] URLForImageResource:@"userinfo"] absoluteString];
}

+ (NSString *)communityIconURL {
    return [[[NSBundle mainBundle] URLForImageResource:@"communitysmall"] absoluteString];
}

@end
