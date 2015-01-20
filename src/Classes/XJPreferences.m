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

+ (BOOL)shouldCheckForGroup: (LJGroup *)grp
{
    NSMutableDictionary *dict = [self makeMutable: [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: PREFS_CHECKFRIENDS_GROUPS]];
    id val = [dict objectForKey: [grp name]];

    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: dict forKey: PREFS_CHECKFRIENDS_GROUPS];
    
    return ((val != nil) && [val boolValue]);
}

+ (void)setShouldCheck: (BOOL)chk forGroup: (LJGroup *)grp
{
    // this assumes you can't have 2 groups with the same name (valid?)
    NSMutableDictionary *dict = [self makeMutable: [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: PREFS_CHECKFRIENDS_GROUPS]];
    // Prefs stores a dict of booleans keyed against group names, hence, if you have two groups with the same name
    // --> key clash
    
    [dict setObject: [NSNumber numberWithBool: chk] forKey: [grp name]];
    [[XJCheckFriendsSessionManager sharedManager] setChecking: chk forGroup: grp];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: dict forKey: PREFS_CHECKFRIENDS_GROUPS];
}

+ (NSFont *)preferredWindowFont
{
	id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *fontName = [values valueForKey: @"XJEntryWindowFontName"];
	int fontSize = [[values valueForKey: @"XJEntryWindowFontSize"] intValue];
	
    NSFont *font = [NSFont fontWithName: fontName size: fontSize];
	if(font) return font;
	
	return [NSFont systemFontOfSize: fontSize];
}

// ----------------------------------------------------------------------------------------
// icons
// ----------------------------------------------------------------------------------------
+ (NSString *)userIconURL {
    return [[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"userinfo" ofType:@"gif"]] absoluteString];
}

+ (NSString *)communityIconURL {
    return [[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"communitysmall" ofType:@"gif"]] absoluteString];
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